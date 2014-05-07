# -*- python -*-

import os

import SCons.Errors
import SCons.Script

name = 'ghdl'
Name = 'GHDL'

def Kconfig(kconfig, env):
    kconfig.Config('hdl.sim.ghdl.ghdl',
                   prompt = '"ghdl command"',
                   type = 'string',
                   default = '"%s"' % 'ghdl',
                   )
    kconfig.Config('hdl.sim.ghdl.analyze_opts',
                   prompt = '"ghdl analyze options"',
                   type = 'string',
                   default = '"--std=00"',
                   )
    kconfig.Config('hdl.sim.ghdl.elaborate_opts',
                   prompt = '"ghdl elaborate options"',
                   type = 'string',
                   default = '"--std=00"',
                   )

def InitActions(projenv):

    toplibdir = projenv.sim_tooldir.Dir('lib').abspath
    libraries = projenv.libraries

    def GHDLInit(target, source, env):

        if not os.path.isdir(toplibdir):
            os.mkdir(toplibdir)
        if not os.path.isdir(workdir):
            os.mkdir(workdir)
        for lib in libraries:
            libdir = os.path.join(toplibdir, lib)
            if not os.path.isdir(libdir):
                os.mkdir(libdir)

    return [SCons.Script.Action(GHDLInit, 'GHDLInit()')]

def AnalyzeActions(projenv, source, language, standard, library):

    if language != 'vhdl':
        raise SCons.Errors.UserError('unsupported language: %s' % language)

    ret = list()

    env = SCons.Script.Environment(tools = [])
    env['GHDL']    = projenv.kconfig.get('hdl.sim.ghdl.ghdl', 'ghdl')
    env['LIBS']    = projenv.libraries
    env['WORK']    = library
    env['LIBDIR']  = projenv.sim_tooldir.Dir('lib')
    env['WORKDIR'] = projenv.sim_tooldir.Dir('lib').Dir(library)

    env['OPTS'] = list()
    if projenv.kconfig.has_key('hdl.sim.ghdl.analyze_opts'):
        env['OPTS'].append(projenv.kconfig.get('hdl.sim.ghdl.analyze_opts'))
    env['OPTS'].append('${_concat(\'-P\', LIBS, \'\', __env__, lambda libs: [LIBDIR.Dir(l) for l in libs])}')
    env['HDLSOURCE'] = source

    ret.append(env.Action('$GHDL -a $OPTS --work=$WORK --workdir=$WORKDIR ${[s.path for s in HDLSOURCE]}'))
    
    return ret

def ElaborateActions(projenv, hdlunit):

    ret = list()

    bindir = projenv.sim_tooldir.Dir('bin')

    env = SCons.Script.Environment(tools = [])
    env['GHDL']         = projenv.kconfig.get('hdl.sim.ghdl.ghdl', 'ghdl')
    env['LIBS']         = projenv.libraries
    env['WORK']         = hdlunit.library
    env['LIBDIR']       = projenv.sim_tooldir.Dir('lib')
    env['WORKDIR']      = projenv.sim_tooldir.Dir('lib').Dir(hdlunit.library)
    env['SIM']      = bindir.File('%s-%s' % (hdlunit.library, hdlunit.filename()))

    import SConsHDL
    if isinstance(hdlunit, SConsHDL.VHDLEntity):
        top = [hdlunit.entity]
    elif isinstance(hdlunit, SConsHDL.VHDLArchitecture):
        top = [hdlunit.entity, hdlunit.architecture]
    else:
        raise SCons.Errors.UserError('invalid HDL unit: ' % str(hdlunit))

    env['TOP']          = top

    env['OPTS'] = list()
    if projenv.kconfig.has_key('hdl.sim.ghdl.elaborate_opts'):
        env['OPTS'].append(projenv.kconfig.get('hdl.sim.ghdl.elaborate_opts'))
    env['OPTS'].append('${_concat(\'-P\', LIBS, \'\', __env__, lambda libs: [LIBDIR.Dir(l) for l in libs])}')

    ret.append(SCons.Script.Mkdir(bindir))
    ret.append(env.Action('$GHDL -e $OPTS --work=$WORK --workdir=$WORKDIR -o "$SIM.path" $TOP'))
    
    return ret


class SimCommand:
    def __init__(self, sim):
        self.sim = sim

    def __call__(self, target, source, env):
        for t in target:
            if os.path.lexists(t.path):
                os.remove(t.path)
            os.symlink(os.path.relpath(self.sim.abspath, os.path.dirname(t.abspath)), t.path)

def CommandActions(projenv, hdlunit):

    bindir = projenv.sim_tooldir.Dir('bin')
    sim = bindir.File('%s-%s' % (hdlunit.library, hdlunit.filename()))

    ret = list()

    ret.append(SCons.Script.Action(SimCommand(sim)))

    return ret
