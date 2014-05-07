# -*- python -*-

import re
import os
import cPickle

import SCons.Taskmaster
import SCons.Job
import SCons.Script.Main
import SCons.Node
import SCons.Node.FS
import SCons.SConsign

class Config:
    
    def __init__(self,
                 symbol,
                 prompt     = None,
                 type       = 'bool',
                 default    = None,
                 depends_on = None,
                 select     = None,
                 range      = None,
                 help       = None,
                 option     = None,
                 ):
        self.symbol     = symbol
        self.prompt     = prompt
        self.type       = type
        self.default    = default
        self.depends_on = depends_on
        self.select     = select
        self.range      = range
        self.option     = option
        self.help       = help

    def make_template_contents(self, template_contents):

        template_contents.append('config %s' % self.symbol)
        
        if self.prompt is not None:
            template_contents.append('prompt %s' % self.prompt)

        template_contents.append(self.type)
            
        if self.default is not None:
            if isinstance(self.default, list):
                template_contents.extend(['default %s' % d for d in self.default])
            else:
                template_contents.append('default %s' % self.default)
            
        if self.depends_on is not None:
            if isinstance(self.default, list):
                template_contents.extend(['depends on %s' % d for d in self.depends_on])
            else:
                template_contents.append('depends on %s' % self.depends_on)

        if self.select is not None:
            if isinstance(self.select, list):
                template_contents.extend(['select %s' % s for s in self.select])
            else:
                template_contents.append('select %s' % self.select)

        if self.range is not None:
            template_contents.append('range %s' % self.range)

        if self.option is not None:
            if isinstance(self.option, list):
                template_contents.extend(['option %s' % o for o in self.option])
            else:
                template_contents.append('option %s' % self.option)

        if self.help is not None:
            template_contents.append('help')
            template_contents.extend(['\t' + line for line in self.help])

        template_contents.append('')

class Choice:

    def __init__(self,
                 configdict,
                 prompt     = None,
                 type       = 'bool',
                 optional   = False,
                 default    = None,
                 depends_on = None,
                 help       = None,
                 ):
        self.configdict = configdict
        self.prompt     = prompt
        self.type       = type
        self.optional   = optional
        self.default    = default
        self.depends_on = depends_on
        self.help       = help

        self.entries = list()

    def Config(self, symbol, **kwargs):
        if self.configdict.has_key(symbol):
            raise ValueError('duplicate symbol %s' % symbol)
        global Config
        ret = Config(symbol, **kwargs)
        self.entries.append(ret)
        self.configdict[symbol] = ret
        return ret

    def make_template_contents(self, template_contents):

        template_contents.append('choice')
        
        if self.prompt is not None:
            template_contents.append('prompt %s' % self.prompt)

        template_contents.append(self.type)

        if self.optional:
            template_contents.append('optional')
        
        if self.default is not None:
            if isinstance(self.default, list):
                template_contents.extend(['default %s' % d for d in self.default])
            else:
                template_contents.append('default %s' % self.default)
            
        if self.depends_on is not None:
            if isinstance(self.depends_on, list):
                template_contents.extend(['depends on %s' % d for d in self.depends_on])
            else:
                template_contents.append('depends on %s' % self.depends_on)

        if self.help is not None:
            template_contents.append('help')
            template_contents.extend(['\t' + line for line in self.help])

        template_contents.append('')

        for e in self.entries:
            e.make_template_contents(template_contents)

        template_contents.extend([
                'endchoice',
                '',
                ])

class Value:

    def __init__(self,
                 symbol,
                 prompt,
                 value,
                 depends_on = None,
                 help = None,
                 ):
        self.symbol = symbol
        self.prompt = prompt
        self.value = value
        self.depends_on = depends_on,
        self.help = help
        self.type = 'bool'

class ValueList:

    def __init__(self,
                 configdict,
                 symbol,
                 prompt = None,
                 type = 'string',
                 optional = False,
                 default = None,
                 depends_on = None,
                 help = None,
                 ):
        self.configdict = configdict
        self.symbol = symbol
        self.prompt = prompt
        self.type = type
        self.optional = optional
        self.default = default
        self.depends_on = depends_on
        self.help = help

        self.entries = list()
        self.values = list()
        self.allowed_values = list()

    def Value(self,
              symbol,
              prompt,
              value = None,
              **kw):
        if self.configdict.has_key(symbol):
            raise ValueError('duplicate symbol %s' % symbol)
        if value is None:
            value = symbol
        if value in self.values:
            raise ValueError('duplicate value %s for list %s' % (value, self.symbol))
        global Value
        ret = Value(symbol, prompt, value, **kw)
        self.entries.append(ret)
        self.values.append(value)
        self.allowed_values.append(value)
        self.configdict[symbol] = ret
        return ret

    def make_template_contents(self, template_contents):

        template_contents.append('choice')
        
        if self.prompt is not None:
            template_contents.append('prompt %s' % self.prompt)

        if self.optional:
            template_contents.append('optional')
        
        if self.default is not None:
            if isinstance(self.default, list):
                template_contents.extend(['default %s' % d for d in self.default])
            else:
                template_contents.append('default %s' % self.default)

        if self.depends_on is not None:
            if isinstance(self.depends_on, list):
                template_contents.extend(['depends on %s' % d for d in self.depends_on])
            else:
                template_contents.append('depends on %s' % self.depends_on)

        if self.help is not None:
            template_contents.append('help')
            template_contents.extend(['\t' + line for line in self.help])

        template_contents.append('')

        for config in self.entries:
            template_contents.append('config %s' % config.symbol)
        
            template_contents.append('prompt %s if %s' % (config.prompt, 'y' if config.value in self.allowed_values else 'n'))

            template_contents.append('bool')
                
            if self.depends_on is not None:
                if isinstance(self.default, list):
                    template_contents.extend(['depends on %s' % d for d in self.depends_on])
                else:
                    template_contents.append('depends on %s' % self.depends_on)

            if self.help is not None:
                template_contents.append('help')
                template_contents.extend(['\t' + line for line in self.help])

            template_contents.append('')

        template_contents.extend([
                'endchoice',
                '',
                ])

        template_contents.append('config %s' % self.symbol)
        template_contents.append(self.type)
        for config in self.entries:
            template_contents.append('default %s if %s' % (config.value, config.symbol))
            
        template_contents.append('')

class Menu:
    
    def __init__(self,
                 configdict,
                 title,
                 depends_on = None,
                 visible_if = None
                 ):
        self.configdict = configdict
        self.title = title
        self.depends_on = depends_on
        self.visible_if = visible_if

        self.entries = list()

    def make_template_contents(self, template_contents):

        template_contents.append('menu "%s"' % self.title.encode('string-escape'))

        if self.depends_on is not None:
            if isinstance(self.depends_on, list):
                template_contents.extend(['depends on %s' % d for d in self.depends_on])
            else:
                template_contents.append('depends on %s' % self.depends_on)

        if self.visible_if is not None:
            if isinstance(self.visible_if, list):
                template_contents.extend(['visible if %s' % d for d in self.visible_if])
            else:
                template_contents.append('visible if %s' % self.visible_if)

        template_contents.append('')

        for e in self.entries:
            e.make_template_contents(template_contents)

        template_contents.extend([
                'endmenu',
                '',
                ])

    def Menu(self, title, **kw):
        global Menu
        ret = Menu(self.configdict, title, **kw)
        self.entries.append(ret)
        return ret

    def Config(self, symbol, **kwargs):
        if self.configdict.has_key(symbol):
            raise ValueError('duplicate symbol %s' % symbol)
        global Config
        ret = Config(symbol, **kwargs)
        self.entries.append(ret)
        self.configdict[symbol] = ret
        return ret

    def Choice(self, **kwargs):
        global Choice
        ret = Choice(self.configdict, **kwargs)
        self.entries.append(ret)
        return ret

    def ValueList(self, symbol, **kw):
        global ValueList
        ret = ValueList(self.configdict, symbol, **kw)
        self.entries.append(ret)
        self.configdict[symbol] = ret
        return ret

class Kconfig(Menu):

    def __init__(self, template, dotconfig, title):
        Menu.__init__(self, dict(), title)

        self.template  = template
        self.dotconfig = dotconfig

    def make_template_contents(self, template_contents):
        template_contents.extend([
                'mainmenu "%s"' % self.title.encode('string-escape'),
                ''
                ])
        for e in self.entries:
            e.make_template_contents(template_contents)

    def parse_value(self, symbol, config, value):
        invalid = False
        if config.type == 'bool':
            if value == 'y':
                value = True
            elif value == 'n':
                value = False
            else:
                invalid = True
        elif config.type == 'int':
            value = int(value)
        elif config.type == 'hex':
            value = int(value)
        elif config.type == 'string':
            if value[0] == '"' and value[-1] == '"':
                value = value[1:-1].decode('string-escape')
            else:
                invalid = True
        if invalid:
            raise ValueError('unrecognized value "%s" for config variable "%s"' % (value.encode('string-escape'), symbol))
        return value

    def Parse(self):
        ret = dict()
        for symbol, config in self.configdict.items():
            if config.type == 'bool':
                ret[symbol] = False
            else:
                ret[symbol] = None

        f = file(self.dotconfig.abspath, 'r')
        for l in f:
            l = l.strip()
            if len(l) == 0:
                continue
            if l[0] == '#':
                continue
            symbol, value = l.split('=', 1)
            symbol = symbol.strip()
            value = value.strip()
            if not self.configdict.has_key(symbol):
                raise ValueError('unrecognized key in %s: %s' % (self.dotconfig.path, symbol))
            ret[symbol] = self.parse_value(symbol, self.configdict[symbol], value)
        return ret

    def Template(self):
        ret = list()
        self.make_template_contents(ret)
        return ret
