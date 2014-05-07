# -*- python -*-

import os

Default(None)

#Alias('help', []
#      '@echo TODO: print help text')

def ConvertRelpath(value, env):
    if not os.path.isabs(value):
        return os.path.join(GetLaunchDir(), value)
    else:
        return value

vars = Variables(None, ARGUMENTS)
vars.Add('BUILDDIR', 'Build directory',                           'build',   None, ConvertRelpath)
vars.Add('CONFIG', 'Kconfig file to use (default = .config)',     '.config', None, ConvertRelpath)
vars.Add('KCONFIG_CPPFLAGS', 'CPPFLAGS used to compile Kconfig')
vars.Add('KCONFIG_CURSES_LOC', 'curses.h C include argument',     '<ncurses.h>')
vars.Add('KCONFIG_MCONF_LIBS', 'libraries used to compile mconf', ['ncurses'])
vars.Add('KCONFIG_NCONF_LIBS', 'libraries used to compile mconf', ['ncurses', 'panel', 'menu'])

vars.Add('KCONFIG_FRONTEND', 'Kconfig frontend to use',           'nconf')

env = Environment(
    variables = vars,
    tools = [],
    )
env['ENV'].update(os.environ)

SConsignFile(env.subst('$BUILDDIR/.sconsign'))

kconfig = SConscript('Kconfig.scons',
                     variant_dir = env['BUILDDIR'],
                     duplicate = 0,
                     exports = {'env': env},
                     )

SConscript('CARPE.scons',
           variant_dir = env['BUILDDIR'],
           duplicate = 0,
           exports = {'env': env,
                      'kconfig': kconfig,
                      },
           )
