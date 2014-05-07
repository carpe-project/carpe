# -*- python -*-

import pkgutil
import sys

tools = {m.name: m for m in [__import__('%s.%s' % (__name__, t[1]), {}, {}, ['*']) for t in pkgutil.iter_modules(sys.modules[__name__].__path__)]}

def Kconfig(kconfig, env):
    tool_valuelist = kconfig.ValueList('hdl.syn.tool',
                                       prompt = '"Synthesis Toolchain Selection"',
                                       optional = True,
                                       )
    for tool in tools.keys():
        tool_valuelist.Value('hdl.syn.tool.%s' % tools[tool].name,
                             prompt = '"%s"' % tools[tool].Name,
                             value = tool,
                             )
    for tool in tools.keys():
        tool_menu = kconfig.Menu('%s Options' % tools[tool].Name,
                                 depends_on = 'hdl.syn.tool.%s' % tools[tool].name,
                                 )
        tools[tool].Kconfig(tool_menu, env)

def Tool(kconfig):
    try:
        return tools[kconfig['hdl.syn.tool']]
    except KeyError:
        return None
