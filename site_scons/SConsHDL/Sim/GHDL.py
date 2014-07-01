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
    workdir = os.path.join(toplibdir, 'work')
    libraries = projenv.libraries
    ghdl_a_sh = projenv.sim_tooldir.File('ghdl-a.sh').abspath
    ghdl_e_sh = projenv.sim_tooldir.File('ghdl-e.sh').abspath

    def GHDLInit(target, source, env):

        print toplibdir
        print workdir
        print libraries

        if not os.path.isdir(toplibdir):
            os.mkdir(toplibdir)
        if not os.path.isdir(workdir):
            os.mkdir(workdir)
        for lib in libraries:
            libdir = os.path.join(toplibdir, lib)
            if not os.path.isdir(libdir):
                os.mkdir(libdir)

        ghdl_a_sh_source = list()
        ghdl_a_sh_source.append('#!/bin/sh')
        ghdl_a_command = projenv.kconfig.get('hdl.sim.ghdl.ghdl', 'ghdl')
        ghdl_a_command += ' -a'
        ghdl_a_opts = projenv.kconfig.get('hdl.sim.ghdl.analyze_opts', '')
        if ghdl_a_opts:
            ghdl_a_command += ' ' + ghdl_a_opts
        ghdl_a_command += ''.join(' -P' + projenv.sim_tooldir.Dir('lib').Dir(l).abspath for l in projenv.libraries)
        ghdl_a_command += ' ${1+"$@"}'
        ghdl_a_sh_source.append(ghdl_a_command)
        ghdl_a_sh_source.append('')

        ghdl_a_sh_file = file(ghdl_a_sh, 'w')
        ghdl_a_sh_file.writelines('\n'.join(ghdl_a_sh_source))
        ghdl_a_sh_file.close()
        os.chmod(ghdl_a_sh, 0o755)

        ghdl_e_sh_source = list()
        ghdl_e_sh_source.append('#!/bin/sh')
        ghdl_e_command = projenv.kconfig.get('hdl.sim.ghdl.ghdl', 'ghdl')
        ghdl_e_command += ' -e'
        ghdl_e_opts = projenv.kconfig.get('hdl.sim.ghdl.elaborate_opts', '')
        if ghdl_e_opts:
            ghdl_e_command += ' ' + ghdl_e_opts
        ghdl_e_command += ''.join(' -P' + projenv.sim_tooldir.Dir('lib').Dir(l).abspath for l in projenv.libraries)
        ghdl_e_command += ' ${1+"$@"}'
        ghdl_e_sh_source.append(ghdl_e_command)
        ghdl_e_sh_source.append('')

        ghdl_e_sh_file = file(ghdl_e_sh, 'w')
        ghdl_e_sh_file.writelines('\n'.join(ghdl_e_sh_source))
        ghdl_e_sh_file.close()
        os.chmod(ghdl_e_sh, 0o755)

    return [SCons.Script.Action(GHDLInit, 'GHDLInit()')]

def AnalyzeActions(projenv, source, language, standard, library):

    if language != 'vhdl':
        raise SCons.Errors.UserError('unsupported language: %s' % language)

    ret = list()

    env = SCons.Script.Environment(tools = [])
    env['GHDLA']   = projenv.sim_tooldir.File('ghdl-a.sh')
    env['GHDLDIR'] = projenv.sim_tooldir
    env['WORK']    = library
    env['WORKDIR'] = projenv.sim_tooldir.Dir('lib').Dir(library)

    env['HDLSOURCE'] = source
    env['relpath'] = os.path.relpath

    ret.append(env.Action('$GHDLA.abspath --work=$WORK --workdir=$WORKDIR.abspath ${[s.path for s in HDLSOURCE]}'))
    
    return ret

def ElaborateActions(projenv, hdlunit):

    ret = list()

    bindir = projenv.sim_tooldir.Dir('bin')

    env = SCons.Script.Environment(tools = [])
    env['GHDLE']        = projenv.sim_tooldir.File('ghdl-e.sh')
    env['WORK']         = hdlunit.library
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
    ret.append(SCons.Script.Mkdir(bindir))
    ret.append(env.Action('$GHDLE.abspath --work=$WORK --workdir=$WORKDIR.abspath -o "$SIM.path" $TOP'))
    
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
