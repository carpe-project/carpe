# -*- python -*-

import sys
import collections
import re
import copy
import time

import SCons.Node
import SCons.Node.Alias
import SCons.Node.FS
import SCons.Node.Python
import SCons.Environment
import SCons.Script
import SCons.Util
import SCons.Errors
import SCons.Subst

import Sim
import Syn

standards = {
    'verilog': [
        'verilog95',
        ],
    'vhdl': [
        'vhdl87',
        'vhdl93',
        ],
    }

def Kconfig(kconfig, env):
    sim_menu = kconfig.Menu('Simulation Options')
    Sim.Kconfig(sim_menu, env)
    syn_menu = kconfig.Menu('Synthesis Options')
    Syn.Kconfig(syn_menu, env)

class HDLUnit:

    def __init__(self, language, library, unittype, unitid):
        self.language = language
        self.unittype = unittype
        self.unitid = unitid
        self.library = library

    def __eq__(self, other):
        return self.language == other.language and \
               self.unittype == other.unittype and \
               self.library == other.library and \
               self.unitid == other.unitid

    def shortname(self):
        return self._name_format % self.unitid

    def filename(self):
        return self._filename_format % self.unitid

    def alias(self, *command):
        d = {'command': ':'.join(command),
             'library': self.library,
             'language': self.language,
             'unittype': self.unittype,
             'name' : self.shortname()
             }
        return 'hdl:%(command)s:%(library)s:%(language)s:%(unittype)s:%(name)s' % d

class VHDLUnit(HDLUnit):

    def __init__(self, library, unittype, unitid):
        HDLUnit.__init__(self, 'vhdl', library, unittype, unitid)


class VHDLPackage(VHDLUnit):

    _name_re = re.compile('^(?:(?P<library>\\w+)\\.)??(?P<package>\\w+)$')
    _name_format = '%(package)s'
    _filename_format = '%(package)s'
    
    def __init__(self, name):
        m = self._name_re.match(name)
        if m is None:
            raise SCons.Errors.UserError('invalid VHDL package name `%s\', should be `[library.]package\'' % name)
        library = m.group('library')
        package = m.group('package')
        unitid = {
            'package': package,
            }
        VHDLUnit.__init__(self, library, 'package', unitid)
        self.package = package

    def implicitDepends(self):
        return []


class VHDLEntity(VHDLUnit):

    _name_re = re.compile('^(?:(?P<library>\\w+)\\.)??(?P<entity>\\w+)$')
    _name_format = '%(entity)s'
    _filename_format = '%(entity)s'
    
    def __init__(self, name):
        m = self._name_re.match(name)
        if m is None:
            raise SCons.Errors.UserError('invalid VHDL entity name `%s\', should be `[library.]entity\'' % name)
        library = m.group('library')
        entity = m.group('entity')
        unitid = {
            'entity': entity,
            }
        VHDLUnit.__init__(self, library, 'entity', unitid)
        self.entity = entity

    def implicitDepends(self):
        return []

class VHDLArchitecture(VHDLUnit):

    _name_re = re.compile('^(?:(?P<library>\\w+)\\.)??(?P<entity>\\w+)\\((?P<architecture>\\w+)\\)$')
    _name_format = '%(entity)s(%(architecture)s)'
    _filename_format = '%(entity)s__%(architecture)s'
    
    def __init__(self, name):
        m = self._name_re.match(name)
        if m is None:
            raise SCons.Errors.UserError('invalid VHDL architecture name `%s\', should be `[library.]entity(architecture)\'' % name)
        library = m.group('library')
        entity = m.group('entity')
        architecture = m.group('architecture')
        unitid = {
            'entity': entity,
            'architecture': architecture,
            }
        VHDLUnit.__init__(self, library, 'architecture', unitid)
        self.entity = entity
        self.architecture = architecture

    def implicitDepends(self):
        # an architecture requires its entity is analyzed into the same
        # library
        if self.library:
            return [VHDLEntity('%s.%s' % (self.library, self.entity))]
        else:
            return [VHDLEntity(self.entity)]

class VerilogUnit(HDLUnit):

    def __init__(self, library, unittype, unitid):
        HDLUnit.__init__(self, library, 'verilog', unittype, unitid)


class VerilogModule(VerilogUnit):

    _name_re = re.compile('^(?:(?P<library>\\w+)\\.)??(?P<module>\\w+)$')
    _name_format = '%(module)s'
    _filename_format = _name_format
    
    def __init__(self, name):
        m = self._name_re.match(name)
        if m is None:
            raise SCons.Errors.UserError('invalid Verilog module name `%s\', should be `[library.]module\'' % name)
        library = m.group('library')
        module = m.group('module')
        unitid = {
            'module': module,
            }
        VerilogUnit.__init__(self, library, 'module', unitid)
        self.module = module

    def implicitDepends(self):
        return []

def HDLStampFile(target, source, env):
    f = file(target[0].get_path(), 'w')
    f.write('%f\n' % time.time())
    f.close()

class HDLProjectEnvironment(SCons.Environment.Environment):

    def ParseFlags(self, *flags):
        return {}

    def __init__(self, project, builddir, kconfig, env = SCons.Environment.Environment(), **kw):
        SCons.Environment.Environment.__init__(self, **kw)
        self._dict.update(env._dict)
        self.project = project
        self.builddir = env.Dir(builddir)
        self.kconfig = kconfig

        self.projectalias = 'hdl:%s' % self.project
        self.libraries = []

        self.stampdir = self.builddir.Dir('stamp')
        self.lockdir = self.builddir.Dir('lock')

        self.sim_tool = Sim.Tool(self.kconfig)

        if self.sim_tool is not None:

            self.sim_stampdir = self.stampdir.Dir('sim').Dir(self.sim_tool.name)
            self.sim_tooldir = self.builddir.Dir('sim').Dir(self.sim_tool.name)
            
            sim_init_actions = list()
            sim_init_actions.append(SCons.Script.Mkdir(self.sim_tooldir))
            sim_init_actions.extend(self.sim_tool.InitActions(self))
            sim_init_actions.append(SCons.Script.Action(HDLStampFile, None))

            self.sim_init_stamp_node = \
                self.Command(target = [self.sim_stampdir.File('init')],
                             source = [],
                             action = sim_init_actions,
                             )

        self.syn_tool = Syn.Tool(self.kconfig)

        if self.syn_tool is not None:

            self.syn_stampdir = self.stampdir.Dir('syn').Dir(self.syn_tool.name)
            self.syn_tooldir = self.builddir.Dir('syn').Dir(self.syn_tool.name)
            
            syn_init_actions = list()
            syn_init_actions.append(SCons.Script.Mkdir(self.syn_tooldir))
            syn_init_actions.extend(self.syn_tool.InitActions(self))
            syn_init_actions.append(SCons.Script.Action(HDLStampFile, None))

            self.syn_init_stamp_node = \
                self.Command(target = [self.syn_stampdir.File('init')],
                             source = [],
                             action = syn_init_actions,
                             )
    
    def HDLLibraryEnvironment(self, library, **kw):
        if library not in self.libraries:
            self.libraries.append(library)
            self.libraries.sort()
        global HDLLibraryEnvironment
        return HDLLibraryEnvironment(self, library, **kw)

    def HDLSimElaborate(self,
                        hdlunit):

        if not isinstance(hdlunit, HDLUnit):
            raise SCons.Errors.UserError('hdlunit %s is not valid' % repr(hdlunit))

        if self.sim_tool is not None:

            sim_elaborate_actions = list()
            sim_elaborate_actions.extend(self.sim_tool.ElaborateActions(self, hdlunit))
            sim_elaborate_actions.append(SCons.Script.Action(HDLStampFile, None))
            
            stampfiles = \
                self.Command(target = [self.sim_stampdir.File(hdlunit.alias('sim', 'elaborate'))],
                             source = [],
                             action = sim_elaborate_actions,
                             )

            # elaboration requires the project is initialized
            self.Depends(stampfiles, self.sim_init_stamp_node)
            # add dependencies on required units
            self.Depends(stampfiles, [self.sim_stampdir.File(hdlunit.alias('sim', 'analyze'))])
            # side effect to prevent parallel runs of the build tool
            self.SideEffect(self.lockdir.Dir('sim').File(self.sim_tool.name), stampfiles)

            # create an alias for this target
            alias = hdlunit.alias('sim', 'elaborate')
            self.Alias([alias],
                       stampfiles,
                       )
            self.Alias([self.projectalias],
                       alias,
                       )
            return alias

    def HDLSimCommand(self,
                      target,
                      hdlunit,
                      ):

        if not isinstance(hdlunit, HDLUnit):
            raise SCons.Errors.UserError('hdlunit %s is not valid' % repr(hdlunit))

        if self.sim_tool is not None:

            sim_command_actions = list()
            sim_command_actions.extend(self.sim_tool.CommandActions(self, hdlunit))
            
            target = \
                self.Command(target = target,
                             source = [],
                             action = sim_command_actions,
                             )

            # add dependencies on required units
            self.Depends(target, [self.sim_stampdir.File(hdlunit.alias('sim', 'elaborate'))])
            
            return target

    def HDLSynElaborate(self,
                        hdlunit):

        if not isinstance(hdlunit, HDLUnit):
            raise SCons.Errors.UserError('hdlunit %s is not valid' % repr(hdlunit))

        if self.syn_tool is not None:

            syn_elaborate_actions = list()
            syn_elaborate_actions.extend(self.syn_tool.ElaborateActions(self, hdlunit))
            syn_elaborate_actions.append(SCons.Script.Action(HDLStampFile, None))
            
            stampfiles = \
                self.Command(target = [self.syn_stampdir.File(hdlunit.alias('syn', 'elaborate'))],
                             source = [],
                             action = syn_elaborate_actions,
                             )

            # elaboration requires the project is initialized
            self.Depends(stampfiles, self.syn_init_stamp_node)
            # add dependencies on required units
            self.Depends(stampfiles, [self.syn_stampdir.File(hdlunit.alias('syn', 'analyze'))])
            # side effect to prevent parallel runs of the build tool
            self.SideEffect(self.lockdir.Dir('syn').File(self.syn_tool.name), stampfiles)

            # create an alias for this target
            alias = hdlunit.alias('syn', 'elaborate')
            self.Alias([alias],
                       stampfiles,
                       )
            self.Alias([self.projectalias],
                       alias,
                       )
            return alias


class HDLLibraryEnvironment(SCons.Environment.Base):
    
    def __init__(self, projenv, library, **kw):
        SCons.Environment.Base.__init__(self, **kw)
        self._dict.update(projenv._dict)
        self.projenv = projenv
        self.library = library

    def HDLAnalyze(self,
                   source,
                   standard,
                   provides,
                   requires = [],
                   sim = True,
                   sim_requires = [],
                   sim_tool_opts = dict(),
                   syn = True,
                   syn_requires = [],
                   syn_tool_opts = dict(),
                   ):
        if not SCons.Util.is_List(source):
            source = [source]
        
        source = [(SCons.Script.File(SCons.Script.File(s).srcnode().abspath) if isinstance(s, str) else s) for s in source]

        if not SCons.Util.is_List(provides):
            provides = [provides]
        
        if len(provides) == 0:
            raise SCons.Errors.UserError('source file(s) %s provide(s) no units' % ', '.join(sources))
        
        for p in provides:
            if not isinstance(p, HDLUnit):
                raise SCons.Errors.UserError('provides entry %s is not valid' % repr(p))
            if p.library is not None:
                raise SCons.Errors.UserError('provides entries cannot specify libraries')

        for r in requires + sim_requires + syn_requires:
            if not isinstance(r, HDLUnit):
                raise SCons.Errors.UserError('requires entry %s is not valid' % repr(p))

        # make sure all units provided are the same language
        language = provides[0].language
        for p in provides[1:]:
            if language != p.language:
                raise SCons.Errors.UserError('provides entries must all be the same language')

        if standard is None:
            standard = standards[language][0]
        
        # fix up list of provided units
        provides = copy.deepcopy(provides)
        # set the library for each provide to the current
        # environment's library
        for p in provides:
            p.library = self.library
        
        # fix up list of required units
        requires = copy.deepcopy(requires)

        # units that don't specify a library use the current
        # environment's library
        for r in requires:
            if r.library is None:
                r.library = self.library

        # add implicit dependencies.
        # make sure not to add a dependency on units that are also
        # provided by this source
        for p in provides:
            ideps = p.implicitDepends()
            for i in ideps:
                if i not in provides:
                    requires.append(i)
        
        # create the nodes
        if sim and self.projenv.sim_tool is not None:

            sim_requires = copy.deepcopy(sim_requires)
            for r in sim_requires:
                if r.library is None:
                    r.library = self.library

            sim_requires.extend(copy.deepcopy(r) for r in requires)
            
            sim_provides_aliases = [p.alias('sim', 'analyze') for p in provides]

            sim_analyze_actions = list()
            sim_analyze_actions.extend(self.projenv.sim_tool.AnalyzeActions(self.projenv,
                                                                               source,
                                                                               language,
                                                                               standard,
                                                                               self.library),
                                       )
            sim_analyze_actions.append(SCons.Script.Action(HDLStampFile, None))
            
            # the command to run hdltool and then create the stamp files
            sim_stampfiles = \
                self.Command(target = [self.projenv.sim_stampdir.File(p.alias('sim', 'analyze')) for p in provides],
                             source = source,
                             action = sim_analyze_actions,
                             )

            # building this source requires the project is initialized
            self.Depends(sim_stampfiles, self.projenv.sim_init_stamp_node)
            # add dependencies on required units
            self.Depends(sim_stampfiles, [self.projenv.sim_stampdir.File(r.alias('sim', 'analyze')) for r in sim_requires])
            # side effect to prevent parallel runs of the build tool
            self.SideEffect(self.projenv.lockdir.Dir('sim').File(self.projenv.sim_tool.name), sim_stampfiles)

            # create an alias for this target
            self.Alias(sim_provides_aliases,
                       sim_stampfiles,
                       )
            # add this target to the whole project alias
            self.Alias([self.projenv.projectalias],
                       sim_provides_aliases,
                       )
        
        # create the nodes
        if syn and self.projenv.syn_tool is not None:

            syn_requires = copy.deepcopy(syn_requires)
            for r in syn_requires:
                if r.library is None:
                    r.library = self.library

            syn_requires.extend(copy.deepcopy(r) for r in requires)
            
            syn_provides_aliases = [p.alias('syn', 'analyze') for p in provides]

            syn_analyze_actions = list()
            syn_analyze_actions.extend(self.Action(self.projenv.syn_tool.AnalyzeActions(self.projenv,
                                                                                        source,
                                                                                        language,
                                                                                        standard,
                                                                                        self.library),
                                                   None))
            syn_analyze_actions.append(SCons.Script.Action(HDLStampFile, None))
            
            # the command to run hdltool and then create the stamp files
            syn_stampfiles = \
                self.Command(target = [self.projenv.syn_stampdir.File(p.alias('syn', 'analyze')) for p in provides],
                             source = source,
                             action = syn_analyze_actions,
                             )

            # building this source requires the project is initialized
            self.Depends(syn_stampfiles, self.projenv.syn_init_stamp_node)
            # add dependencies on required units
            self.Depends(syn_stampfiles, [self.projenv.syn_stampdir.File(r.alias('syn', 'analyze')) for r in syn_requires])
            # side effect to prevent parallel runs of the build tool
            self.SideEffect(self.projenv.lockdir.Dir('syn').File(self.projenv.syn_tool.name), syn_stampfiles)

            # create an alias for this target
            self.Alias(syn_provides_aliases,
                       syn_stampfiles,
                       )
            # add this target to the whole project alias
            self.Alias([self.projenv.projectalias],
                       syn_provides_aliases,
                       )

__all__ = [
    'VHDLPackage',
    'VHDLEntity',
    'VHDLArchitecture',
    'VerilogModule',
    'HDLProjectEnvironment',
    ]
