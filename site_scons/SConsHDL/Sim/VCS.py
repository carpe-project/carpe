# -*- python -*-

import SConsHDL

import SCons.Errors
import SCons.Script

import os
import pipes
import shlex

name = 'vcs'
Name = 'Synopsys VCS'

def Kconfig(kconfig, env):

    kconfig.Config('hdl.sim.vcs.VCS_HOME',
                   prompt = '"VCS_HOME environment variable setting"',
                   type = 'string',
                   default = '"%s"' % env['ENV']['VCS_HOME'] if env['ENV'].has_key('VCS_HOME') else None,
                   )

    kconfig.Config('hdl.sim.vcs.SNPSLMD_LICENSE_FILE',
                   prompt = '"SNPSLMD_LICENSE_FILE environment variable setting"',
                   type = 'string',
                   default = '"%s"' % env['ENV']['SNPSLMD_LICENSE_FILE'] if env['ENV'].has_key('SNPSLMD_LICENSE_FILE') else None,
                   )

    kconfig.Config('hdl.sim.vcs.timebase',
                   prompt = '"Time base (NS, PS, etc.)"',
                   type = 'string',
                   default = '"PS"',
                   )

    kconfig.Config('hdl.sim.vcs.time_resolution',
                   prompt = '"Time resolution (NS, PS, etc.)"',
                   type = 'string',
                   default = '"PS"',
                   )

    kconfig.Config('hdl.sim.vcs.vhdlan',
                   prompt = '"vhdlan command"',
                   type = 'string',
                   default = '"%s"' % 'vhdlan',
                   )

    kconfig.Config('hdl.sim.vcs.vhdlan_opts',
                   prompt = '"vhdlan command options"',
                   type = 'string',
                   default = '"-q -nc -full64 -vhdl08"',
                   )


    kconfig.Config('hdl.sim.vcs.vlogan',
                   prompt = '"vlogan command"',
                   type = 'string',
                   default = '"%s"' % 'vlogan',
                   )

    kconfig.Config('hdl.sim.vcs.vlogan_opts',
                   prompt = '"vlogan command options"',
                   type = 'string',
                   default = '"-q -nc -full64 -v2k"',
                   )


    kconfig.Config('hdl.sim.vcs.vcs',
                   prompt = '"vcs command"',
                   type = 'string',
                   default = '"%s"' % 'vcs',
                   )

    kconfig.Config('hdl.sim.vcs.vcs_opts',
                   prompt = '"vcs command options"',
                   type = 'string',
                   default = '"-q -nc -full64"',
                   )

    kconfig.Config('hdl.sim.vcs.simv_opts',
                   prompt = '"simulator run command options"',
                   type = 'string',
                   default = '"-q -nc"',
                   )

def InitActions(projenv):

    toplibdir = projenv.sim_tooldir.Dir('lib').abspath
    workdir = os.path.join(toplibdir, 'work')
    libraries = projenv.libraries
    timebase = projenv.kconfig.get('hdl.sim.vcs.timebase', None)
    time_resolution = projenv.kconfig.get('hdl.sim.vcs.time_resolution', None)
    synopsys_sim_setup = projenv.sim_tooldir.File('synopsys_sim.setup').abspath

    def VCSInit(target, source, env):

        if not os.path.isdir(toplibdir):
            os.mkdir(toplibdir)
        if not os.path.isdir(workdir):
            os.mkdir(workdir)
        for lib in libraries:
            libdir = os.path.join(toplibdir, lib)
            if not os.path.isdir(libdir):
                os.mkdir(libdir)
        
        synopsys_sim_setup_source = list()
        if timebase is not None:
            synopsys_sim_setup_source.append('TIMEBASE: %s' % timebase)
        if time_resolution is not None:
            synopsys_sim_setup_source.append('TIME_RESOLUTION = %s' % time_resolution)
        synopsys_sim_setup_source.append('WORK > DEFAULT')
        synopsys_sim_setup_source.append('DEFAULT : ./lib/work')
        synopsys_sim_setup_source.extend(['%s: ./lib/%s' % (l, l) for l in libraries])
        synopsys_sim_setup_source.append('')

        synopsys_sim_setup_file = file(synopsys_sim_setup, 'w')
        synopsys_sim_setup_file.writelines('\n'.join(synopsys_sim_setup_source))
        synopsys_sim_setup_file.close()

    return [SCons.Script.Action(VCSInit, 'VCSInit()')]

def AnalyzeActions(projenv, source, language, standard, library):

    ret = list()

    if language == 'vhdl':
        env = SCons.Script.Environment(tools = [])
        env['VHDLAN'] = projenv.kconfig.get('hdl.sim.vcs.vhdlan', 'vhdlan')

        env['VHDLAN_OPTS'] = list()
        if projenv.kconfig.get('hdl.sim.vcs.full64', False):
            env['VHDLAN_OPTS'].append('-full64')
        env['VHDLAN_OPTS'].extend(['-work', library])
        env['VHDLAN_OPTS'].extend(shlex.split(projenv.kconfig.get('hdl.sim.vcs.vhdlan_opts', '')))
        env['VHDLANSOURCE'] = source
        
        env['VCS_HOME'] = projenv.kconfig['hdl.sim.vcs.VCS_HOME']
        env['SNPSLMD_LICENSE_FILE'] = projenv.kconfig['hdl.sim.vcs.SNPSLMD_LICENSE_FILE']
        env['SYNOPSYS_SIM_SETUP'] = projenv.sim_tooldir.File('synopsys_sim.setup')
        env['HDLSOURCE'] = source
        env['VCSDIR'] = projenv.sim_tooldir
        env['relpath'] = os.path.relpath

        ret.append(env.Action('cd $VCSDIR.abspath && SNPSLMD_LICENSE_FILE=$SNPSLMD_LICENSE_FILE VCS_HOME=$VCS_HOME SYNOPSYS_SIM_SETUP=${relpath(SYNOPSYS_SIM_SETUP.path, VCSDIR.path)} $VHDLAN $VHDLAN_OPTS ${[relpath(s.path, VCSDIR.path) for s in HDLSOURCE]}'))

    elif language == 'verilog':
        env = SCons.Script.Environment(tools = [])
        env['VLOGAN'] = projenv.kconfig.get('hdl.sim.vcs.vlogan', 'vlogan')

        env['VLOGAN_OPTS'] = list()
        if projenv.kconfig.get('hdl.sim.vcs.full64', False):
            env['VLOGAN_OPTS'].append('-full64')
        hw['VLOGAN_OPTS'].extend(['-work', library])
        env['VLOGAN_OPTS'].extend(shlex.split(projenv.kconfig.get('hdl.sim.vcs.vlogan_opts', '')))
        env['HDLSOURCE'] = source
        env['VCSDIR'] = projenv.sim_tooldir

        env['VCS_HOME'] = projenv.kconfig['hdl.sim.vcs.VCS_HOME']
        env['SNPSLMD_LICENSE_FILE'] = projenv.kconfig['hdl.sim.vcs.SNPSLMD_LICENSE_FILE']
        env['SYNOPSYS_SIM_SETUP'] = projenv.sim_tooldir.File('synopsys_sim.setup')
        env['relpath'] = os.path.relpath

        ret.append(env.Action('cd $VCSDIR.abspath && SNPSLMD_LICENSE_FILE=$SNPSLMD_LICENSE_FILE VCS_HOME=$VCS_HOME SYNOPSYS_SIM_SETUP=${relpath(SYNOPSYS_SIM_SETUP.path, VCSDIR.path)} $VLOGAN $VLOGAN_OPTS ${[relpath(s.path, VCSDIR.path) for s in HDLSOURCE]}'))

    else:
        
        raise SCons.Errors.UserError('unsupported language: %s' % language)

    return ret

def ElaborateActions(projenv, hdlunit):

    ret = list()

    bindir = projenv.sim_tooldir.Dir('bin')

    env = SCons.Script.Environment(tools = [])
    env['VCS']          = projenv.kconfig.get('hdl.sim.vcs.vcs', 'VCS')
    env['LIBRARY']      = hdlunit.library
    env['VCS_HOME']     = projenv.kconfig['hdl.sim.vcs.VCS_HOME']

    import SConsHDL
    if isinstance(hdlunit, SConsHDL.VHDLEntity):
        top = '%s.%s' % (hdlunit.library, hdlunit.entity)
    elif isinstance(hdlunit, SConsHDL.VHDLArchitecture):
        top = '%s.%s__%s' % (hdlunit.library, hdlunit.entity, hdlunit.architecture)
    elif isinstance(hdlunit, SConsHDL.VerilogModule):
        top = '%s.%s' % (hdlunit.library, hdlunit.module)
    else:
        raise SCons.Errors.UserError('invalid HDL unit: ' % str(hdlunit))
        
    env['TOP']      = top
    env['SIM']      = bindir.File('%s-%s' % (hdlunit.library, hdlunit.filename()))

    env['VCS_OPTS'] = list()
    env['VCS_OPTS'].extend(shlex.split(projenv.kconfig.get('hdl.sim.vcs.vcs_opts', '')))

    env['VCS_HOME'] = projenv.kconfig['hdl.sim.vcs.VCS_HOME']
    env['SNPSLMD_LICENSE_FILE'] = projenv.kconfig['hdl.sim.vcs.SNPSLMD_LICENSE_FILE']
    env['VCSDIR'] = projenv.sim_tooldir
    env['SYNOPSYS_SIM_SETUP'] = projenv.sim_tooldir.File('synopsys_sim.setup')
    env['relpath'] = os.path.relpath

    ret.append(SCons.Script.Mkdir(bindir))
    ret.append(env.Action('cd $VCSDIR.abspath && SNPSLMD_LICENSE_FILE=$SNPSLMD_LICENSE_FILE VCS_HOME=$VCS_HOME SYNOPSYS_SIM_SETUP=${relpath(SYNOPSYS_SIM_SETUP.path, VCSDIR.path)} $VCS $VCS_OPTS -o ${relpath(SIM.path, VCSDIR.path)} $TOP'))

    return ret


class SimCommand:
    def __init__(self, sim):
        self.sim = sim

    def __call__(self, target, source, env):
        for t in target:
            contents = list()
            contents.append('#!/bin/sh')
            contents.append('export SNPSLMD_LICENSE_FILE=%s' % pipes.quote(env.kconfig['hdl.sim.vcs.SNPSLMD_LICENSE_FILE']))
            contents.append('export VCS_HOME=%s' % pipes.quote(env.kconfig['hdl.sim.vcs.VCS_HOME']))
            contents.append('export SYNOPSYS_SIM_SETUP=%s' % pipes.quote(env.sim_tooldir.File('synopsys_sim.setup').abspath))
            contents.append('exec %s %s "${1+$@}"' % (pipes.quote(self.sim.abspath), env.kconfig.get('hdl.sim.vcs.simv_opts')))
            contents.append('')
            f = file(t.path, 'w')
            f.writelines('\n'.join(contents))
            f.close()

def CommandActions(projenv, hdlunit):

    bindir = projenv.sim_tooldir.Dir('bin')
    sim = bindir.File('%s-%s' % (hdlunit.library, hdlunit.filename()))

    ret = list()

    ret.append(SCons.Script.Action(SimCommand(sim)))
    ret.append(SCons.Script.Chmod('$TARGET', 0o755))
    
    return ret
