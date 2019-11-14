# -*- coding: utf-8 -*-
import json
from urllib.request import urlopen
from urllib.parse import urlencode

class Plugin(object):

    def __init__(self, **kwargs): pass

    def cmd(self, command, args, channel, **kwargs):
        if command == 'define' and args:
            word =  self.search_urbandictionary(args)
            if word and 'definition' in word and 'word' in word:
                message = "{w}: {d}".format(w = word['word'],
                                            d = word['definition'].replace("\n", "").replace("\r", ""))
                r = []
                r.append((0, channel, message))

                if 'example' in word:
                    example = "Example: {e}".format(e = word['example'].replace("\n","").replace("\r",""))

                    r.append((0, channel, example))

                return r
            else:
                return [(0, channel,
                         "Sorry, I couldn't find \"{w}\"".format(w = args))]

    def search_urbandictionary(self, query):
        result = urlopen("http://api.urbandictionary.com/v0/define?" + urlencode({'term': query})).read()
        answer = json.loads(result)
        word = answer['list'][0]
        if word['word'] == query:
            return word
        else:
            return False


if __name__ == '__main__':
    p = Plugin()
    print(p.cmd('define', 'GUI', 'test'))
    print(p.cmd('define', "Åhus", 'test'))
