# -*- coding: utf-8 -*-
import re
from random import randint, choice

SHADAP_RE = r'[^s]*sh[ua][td][^ua]*[ua]p'
DICE_CMD_RE = r'^(?P<number>[0-5]?\d?)[dD](?P<size>[1-9]|\d{2,3})$'
UNIVERSE_RE = r'^.*natur.*univers'

class Plugin(object):

    def __init__(self, **kwargs):
        self.shadap = re.compile(SHADAP_RE, re.I)
        self.dicere = re.compile(DICE_CMD_RE, re.U)
        self.universe = re.compile(UNIVERSE_RE, re.I)
        self.x = kwargs['config'].get('test','x')
        self.jobs_exist = 'new_job' in kwargs and 'del_job' in kwargs
        self.ball_response = ['It is certain',
                              'It is decidedly so',
                              'Without a doubt',
                              'Yes, definitely',
                              'You may rely on it',
                              'As I see it, yes',
                              'Most likely',
                              'Outlook good',
                              'Yes',
                              'Signs point to yes',
                              'Reply hazy try again',
                              'Ask again later',
                              'Better not tell you now',
                              'Cannot predict now',
                              'Concentrate and ask again',
                              'Don\'t count on it',
                              'My reply is no',
                              'My sources say no',
                              'Outlook not so good',
                              'Very doubtful']

    def listen(self, msg, channel, **kwargs):
        if msg.find(kwargs['context'].self_nick) != -1 and self.shadap.search(msg):
            return [(0, channel, kwargs['from_nick'], 'Fuck you! I\'m only doing what I\'m being told to do.')]

        if msg.find(kwargs['context'].self_nick) != -1 and self.universe.search(msg):
            return [(0, channel, kwargs['from_nick'], 'The universe is a spheroid region, 705 meters in diameter.')]
        
        if len(msg) == 9 and msg.strip().lower() == "python 2?":
            return [(0, channel, kwargs['from_nick'], "It's dead, jim!")]
        
    def cmd(self, command, args, channel, **kwargs):
        match = self.dicere.match(command)
        if command == 'coin' or command == 'toss' or command == 'cointoss':
            if randint(1, 2) == 1:
                return [(0, channel, kwargs['from_nick'], "Head")]
            else:
                return [(0, channel, kwargs['from_nick'], "Tail")]
        if command == 'readmyconfig?':
            return [(0, channel, kwargs['from_nick'], self.x)]
        if command == 'cronjobs?':
            return [(0, channel, kwargs['from_nick'], 'yes' if self.jobs_exist else 'no')]
        if command == '8ball' or command == '8' or command == 'ball':
            return [(0, channel, kwargs['from_nick'], choice(self.ball_response))]
        if match:
            if match.group('number') != '':
                answ = [randint(1, int(match.group('size'))) for x in range(0, int(match.group('number')))]
                answ = "Sum: {s}, {l}".format(s = sum(answ), l = answ)
            else:
                answ = randint(1, int(match.group('size')))
                if match.group('size') == '20' and answ == 20:
                    answ = 'CRITICAL HIT!'
            return [(0, channel, kwargs['from_nick'], str(answ))]
