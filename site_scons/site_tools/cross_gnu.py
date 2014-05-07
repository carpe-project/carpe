# -*- python -*-

import SCons.Action
import SCons.Scanner
import SCons.Util
import SCons.Script

CrossCFileSuffix = '.c'
CrossCSuffixes = ['.c', '.h', '.S']
CrossASSuffixes = ['.s']
CrossObjSuffix = '.${CROSS_TARGET}.o'
CrossProgSuffix = '.$CROSS_TARGET'
CrossSRECSuffix = '.${CROSS_TARGET}.srec'
CrossCAction = SCons.Action.Action('$CROSSCCCOM', '$CROSSCCCOMSTR')
CrossASAction = SCons.Action.Action('$CROSSASCOM', '$CROSSASCOMSTR')
CrossARActions = [SCons.Action.Action('$CROSSARCOM', '$CROSSARCOMSTR'),
                   SCons.Action.Action('$CROSSRANLIBCOM', '$CROSSRANLIBCOMSTR')]
CrossLinkAction = SCons.Action.Action('$CROSSLINKCOM', '$CROSSLINKCOMSTR')
CrossSRECAction = SCons.Action.Action('$CROSSSRECCOM', '$CROSSSRECCOMSTR')

def CrossStaticObjectEmitter(target, source, env):
    return (target, source)

CrossCScanner = \
    SCons.Scanner.ClassicCPP('CrossCScanner',
                             '$CROSSCPPSUFFIXES',
                             'CROSSCPPPATH',
                             '^[ \t]*#[ \t]*(?:include|import)[ \t]*(<|")([^>"]+)(>|")')

def CrossProgramScan(node, env, libpath = ()):
    """
    This scanner scans program files for static-library
    dependencies.  It will search the CROSSLIBPATH environment variable
    for libraries specified in the CROSSLIBS variable, returning any
    files it finds as dependencies.
    """
    try:
        libs = env['CROSSLIBS']
    except KeyError:
        libs = []
    
    if SCons.Util.is_String(libs):
        libs = libs.split()
    else:
        libs = SCons.Util.flatten(libs)
    
    try:
        prefix = env['CROSSLIBPREFIXES']
        if not SCons.Util.is_List(prefix):
            prefix = [ prefix ]
    except KeyError:
        prefix = [ '' ]

    try:
        suffix = env['CROSSLIBSUFFIXES']
        if not SCons.Util.is_List(suffix):
            suffix = [ suffix ]
    except KeyError:
        suffix = [ '' ]

    pairs = []
    for suf in map(env.subst, suffix):
        for pref in map(env.subst, prefix):
            pairs.append((pref, suf))

    result = []

    if callable(libpath):
        libpath = libpath()

    find_file = SCons.Node.FS.find_file
    adjustixes = SCons.Util.adjustixes
    for lib in libs:
        if SCons.Util.is_String(lib):
            lib = env.subst(lib)
            for pref, suf in pairs:
                l = adjustixes(lib, pref, suf)
                l = find_file(l, libpath, verbose=SCons.Scanner.Prog.print_find_libs)
                if l:
                    result.append(l)
        else:
            result.append(lib)
    
    try:
        linkscript = env['CROSSLINKSCRIPT']
    except KeyError:
        pass
    else:
        if not SCons.Util.is_List(linkscript):
            linkscript = [ linkscript ]
        result.extend(linkscript)
    
    return result

CrossProgramScanner = \
    SCons.Scanner.Base(CrossProgramScan, "CrossProgramScanner",
                       path_function = SCons.Scanner.FindPathDirs('CROSSLIBPATH'))

CrossSourceFileScanner = \
    SCons.Scanner.Base({}, name='CrossSourceFileScanner')

for suffix in CrossCSuffixes:
    CrossSourceFileScanner.add_scanner(suffix, CrossCScanner)

CrossStaticLibraryBuilder = \
    SCons.Builder.Builder(name = 'CrossStaticLibraryBuilder',
                          action = CrossARActions,
                          emitter = '$CROSSLIBEMITTER',
                          prefix = '$CROSSLIBPREFIX',
                          suffix = '$CROSSLIBSUFFIX',
                          src_suffix = '$CROSSOBJSUFFIX',
                          src_builder = 'CrossObject',
                          )

CrossProgramBuilder = \
    SCons.Builder.Builder(name = 'CrossProgramBuilder',
                          action = CrossLinkAction,
                          emitter = '$CROSSPROGEMITTER',
                          prefix = '$CROSSPROGPREFIX',
                          suffix = '$CROSSPROGSUFFIX',
                          src_suffix = '$CROSSOBJSUFFIX',
                          src_builder = 'CrossObject',
                          target_scanner = CrossProgramScanner,
                          )

CrossStaticObjectBuilder = \
    SCons.Builder.Builder(name = 'CrossStaticObjectBuilder',
                          action = {},
                          emitter = {},
                          prefix = '$CROSSOBJPREFIX',
                          suffix = '$CROSSOBJSUFFIX',
                          src_builder = ['CFile'],
                          source_scanner = CrossSourceFileScanner,
                          single_source = True,
                          )
for suffix in CrossCSuffixes:
    CrossStaticObjectBuilder.add_action(suffix, CrossCAction)
    CrossStaticObjectBuilder.add_emitter(suffix, CrossStaticObjectEmitter)

for suffix in CrossASSuffixes:
    CrossStaticObjectBuilder.add_action(suffix, CrossASAction)
    CrossStaticObjectBuilder.add_emitter(suffix, CrossStaticObjectEmitter)

CrossSRECBuilder = \
    SCons.Builder.Builder(name = 'CrossSRECBuilder',
                          action = CrossSRECAction,
                          emitter = '$CROSSSRECEMITTER',
                          prefix = '$CROSSSRECPREFIX',
                          suffix = '$CROSSSRECSUFFIX',
                          src_builder = 'CrossProgram',
                          )

def exists(env, **kw):
    if not env.get('CROSS_TARGET', None):
        return False
    return (env.Detect(['${CROSS_TARGET}-gcc']) and
            env.Detect(['${CROSS_TARGET}-as']) and
            env.Detect(['${CROSS_TARGET}-ar']) and
            env.Detect(['${CROSS_TARGET}-objcopy']))

def generate(env, **kw):
    
    env['CROSSCC'] = env.Detect(['${CROSS_TARGET}-gcc']) or '${CROSS_TARGET}-gcc'
    env['CROSSCFLAGS'] = []
    env['CROSSCCCOM'] = '$CROSSCC -o $TARGET -c $CROSSCFLAGS $CROSSCCCOMCOM $SOURCES'
    env['CROSSCCCOMCOM'] = '$CROSSCPPFLAGS $CROSSCPPDEFFLAGS $CROSSCPPINCFLAGS'
    env['CROSSCPPDEFPREFIX'] = '-D'
    env['CROSSCPPDEFSUFFIX'] = ''
    env['CROSSCPPDEFFLAGS'] = '${_defines(CROSSCPPDEFPREFIX, CROSSCPPDEFINES, CROSSCPPDEFSUFFIX, __env__)}'
    env['CROSSINCPREFIX'] = '-I'
    env['CROSSINCSUFFIX'] = ''
    env['CROSSCPPINCFLAGS'] = '${_concat(CROSSINCPREFIX, CROSSCPPPATH, CROSSINCSUFFIX, __env__, RDirs, TARGET, SOURCE)}'

    env['CROSSAS'] = env.Detect(['${CROSS_TARGET}-as']) or '${CROSS_TARGET}-as'
    env['CROSSASFLAGS'] = []
    env['CROSSASCOM'] = '$CROSSAS -o $TARGET -c $CROSSASFLAGS $CROSSASCOMCOM $SOURCES'
    env['CROSSASCOMCOM'] = '$CROSSASINCFLAGS'
    env['CROSSASINCPREFIX'] = '-I'
    env['CROSSASINCSUFFIC'] = ''
    env['CROSSASINCFLAGS'] = '${_concat(CROSSASINCPREFIX, CROSSASINCPATH, CROSSASINCSUFFIX, __env__, RDirs, TARGET, SOURCE)}'
    
    env['CROSSAR'] = env.Detect(['${CROSS_TARGET}-ar']) or '${CROSS_TARGET}-ar'
    env['CROSSARFLAGS'] = 'rc'
    env['CROSSARCOM'] = '$CROSSAR $CROSSARFLAGS $TARGET $SOURCES'
    env['CROSSRANLIB'] = env.Detect(['${CROSS_TARGET}-ranlib']) or '${CROSS_TRAGET}-ranlib'
    env['CROSSRANLIBFLAGS'] = ''
    env['CROSSRANLIBCOM'] = '$CROSSRANLIB $CROSSRANLIBFLAGS $TARGET'
    
    env['CROSSLINK'] = '$CROSSCC'
    env['CROSSLINKFLAGS'] = []
    env['CROSSLINKCOM'] = '$CROSSLINK -o $TARGET $CROSSLINKFLAGS $CROSSLINKSCRIPTFLAGS $SOURCES $CROSSLIBDIRFLAGS $CROSSLIBFLAGS'
    env['CROSSLINKSCRIPTPREFIX'] = '-Wl,-T,'
    env['CROSSLINKSCRIPTSUFFIX'] = ''
    
    env['CROSSLINKSCRIPTFLAGS'] = '${map(lambda x: CROSSLINKSCRIPTPREFIX + str(x) + CROSSLINKSCRIPTSUFFIX, __env__.Flatten(CROSSLINKSCRIPT))}'
    env['CROSSLIBDIRFLAGS'] = '$( ${_concat(CROSSLIBDIRPREFIX, CROSSLIBPATH, CROSSLIBDIRSUFFIX, __env__, RDirs, TARGET, SOURCE)} $)'
    env['CROSSLIBDIRPREFIX'] = '-L'
    env['CROSSLIBDIRSUFFIX'] = ''
    env['CROSSLIBS'] = []
    env['CROSSLIBFLAGS'] = '${_stripixes(CROSSLIBLINKPREFIX, CROSSLIBS, CROSSLIBLINKSUFFIX, CROSSLIBPREFIXES, CROSSLIBSUFFIXES, __env__)}'
    env['CROSSLIBLINKPREFIX'] = '-l'
    env['CROSSLIBLINKSUFFIX'] = '.${CROSS_TARGET}'
    env['CROSSLIBPREFIXES'] = ['$CROSSLIBPREFIX']
    env['CROSSLIBPREFIX'] = 'lib'
    env['CROSSLIBSUFFIXES'] = ['$CROSSLIBSUFFIX']
    env['CROSSLIBSUFFIX'] = '.${CROSS_TARGET}.a'
    
    env['CROSSOBJCOPY'] = env.Detect(['${CROSS_TARGET}-objcopy']) or '${CROSS_TARGET}-objcopy'
    env['CROSSSRECCOM'] = '$CROSSOBJCOPY -O srec $SOURCE $TARGET'
    
    env['CROSSCPPSUFFIXES'] = CrossCFileSuffix
    env['CROSSCFILESUFFIX'] = CrossCFileSuffix
    env['CROSSOBJSUFFIX'] = CrossObjSuffix
    env['CROSSSRECSUFFIX'] = CrossSRECSuffix
    
    env.SetDefault(CROSSCPPFLAGS = [],
                   CROSSCPPDEFINES = [],
                   CROSSCPPPATH = [],
                   CROSSASINCPATH = [],
                   CROSSPROGSUFFIX = CrossProgSuffix,
                   CROSSLINKSCRIPT = [],
                   )

    env.SetDefault(CROSSCCCOMSTR = '$CROSSCCCOM',
                   CROSSASCOMSTR = '$CROSSASCOM',
                   CROSSARCOMSTR = '$CROSSARCOM',
                   CROSSRANLIBCOMSTR = '$CROSSRANLIBCOM',
                   CROSSLINKCOMSTR = '$CROSSLINKCOM',
                   CROSSSRECCOMSTR = '$CROSSSRECCOM',
                   )
    
    env['BUILDERS']['CrossStaticObject'] = CrossStaticObjectBuilder
    env['BUILDERS']['CrossObject'] = CrossStaticObjectBuilder
    env['BUILDERS']['CrossStaticLibrary'] = CrossStaticLibraryBuilder
    env['BUILDERS']['CrossLibrary'] = CrossStaticLibraryBuilder
    env['BUILDERS']['CrossProgram'] = CrossProgramBuilder
    env['BUILDERS']['CrossSREC'] = CrossSRECBuilder
