# -*- coding: utf-8 -*-
# Basic interface class for communicating with an IRC server.
# Copyright (C) 2012  Sindre Wetjen

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
import time
import re

class Plugin(object):

    def __init__(self):
        self.time_descriptor_to_seconds = {'d': 86400, 'h': 3600, 't': 3600, 'm': 60, 's': 1}
        time_descriptors = r'(d(ag(er)?|ays?)?|t(imer?)?|h(ours?)?|m(inut(es?|t(er)?))?|s(econds?|ekund(er)?)?)'
        self.initial_phrase = re.compile(r'^\s*((remind me in)|(minn meg på om))\s+(?P<reminder_obj>.+)$')
        self.time_phrase = re.compile(r'^(?P<time>(\s*\d+\s?' +
                                      time_descriptors +
                                      r')+(\s*(and|og)\s+\d+\s?' +
                                      time_descriptors +
                                      r')?)(?P<message>.+?)$')
        self.time_split = re.compile(r'(\d+)\s?' + time_descriptors)

    def _print_reminder(self, channel, user, msg):
        return [(0, channel, user, "Jeg skulle minne deg på {}".format(msg))]

    def _print_reminder_debug(self, channel, user, ti, msg):
        return [(0, channel, user, msg),
                (0, channel, user, "Real time used: {t}".format(t = (time.time() - ti)))]

    def _time_obj_parse(self, time_obj):
        time_message = self.time_phrase.match(time_obj)
        if time_message:
            times = self.time_split.findall(time_message.group('time'))
            s = 0
            for time_obj in times:
                s += int(time_obj[0]) * self.time_descriptor_to_seconds[time_obj[1][0]]
            return (s, time_message.group('time').strip(), time_message.group('message'))
        return (None, None, None)

    def cmd(self, command, args, channel, **kwargs):
        print(repr(kwargs))
        if command == "reminder":
            seconds, time_desc, message = self._time_obj_parse(args)
            if seconds:
                kwargs['new_job'](time.time() + seconds,
                                   self._print_reminder,
                                   [channel,
                                    kwargs['from_nick'],
                                    message.strip()])
                return [(0, channel,
                         kwargs['from_nick'],
                         "Okay, I will remind you of that in {}.".format(time_desc))]

    def listen(self, msg, channel, **kwargs):
        initial = self.initial_phrase.match(msg)
        if initial:
            seconds, time_desc, message = self._time_obj_parse(initial.group('reminder_obj'))
            if seconds:
                kwargs['new_job'](time.time() + seconds,
                                   self._print_reminder,
                                   [channel,
                                    kwargs['from_nick'],
                                    message.strip()])
                return [(0, channel,
                         kwargs['from_nick'],
                         "Skal minne deg på det om {}.".format(time_desc))]

if __name__ == '__main__':
    p = Plugin()
    print(p.listen('minn meg på om 2d 4t 3m og 50s at jeg må fikse dette', '#foobar', from_nick="foo", new_job=(lambda *a: None)))
    print(p.listen('remind me in 20d 24h 43m and 100s to fix this', '#foobar', from_nick="foo", new_job=(lambda *a: None)))
    print(p.listen('minn meg på om 2 dager 4 timer og 1 sekund at jeg må fikse dette', '#foobar', from_nick="foo", new_job=(lambda *a: None)))
    print(p.listen('remind me in 4 hours 1 minute and 30 seconds to fix this', '#foobar', from_nick="foo", new_job=(lambda *a: None)))
    print(p.cmd('reminder', '2h 3m and 4s foo bar', '#foobar', from_nick="foo", new_job=(lambda *a: None)))
