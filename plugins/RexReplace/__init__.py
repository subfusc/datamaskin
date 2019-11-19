import re

class Plugin(object):

    def __init__(self, **kwargs):
        self.last_messages = {}
        self.matcher = re.compile(r'^s/(?P<from>.+?)(?<!\\)/(?P<to>.*)$')

    def _get_channel(self, channel):
        if not channel in self.last_messages:
            self.last_messages[channel] = {}
        return self.last_messages[channel]

    def _get_user_in_channel(self, user, channel):
        channel = self._get_channel(channel)
        if not user in channel:
            channel[user] = []
        return channel[user]

    def _add_last_for(self, user, channel, message):
        last_for_user = self._get_user_in_channel(user, channel)
        self.last_messages[channel][user] = [message] + last_for_user[:2]

    def listen(self, msg, channel, **kwargs):
        m = self.matcher.match(msg)
        if m:
            try:
                from_re = re.compile(m.group('from'))
                to = m.group('to').strip('/')
                for message in self._get_user_in_channel(kwargs['from_nick'],channel):
                    if from_re.search(message):
                        print(message)
                        return [(0, channel, '{} mente "{}"'.format(kwargs['from_nick'],
                                                                    from_re.sub(to, message)))]
                for user, messages in self._get_channel(channel).iteritems():
                    for message in messages:
                        if from_re.search(message):
                            return [(0, channel,
                                     '{} er pedantisk og vil rette til "{}"'.format(kwargs['from_nick'],
                                                                                    from_re.sub(to,message)))]
            except re.error:
                return [(0, channel, kwargs['from_nick'], 'Jeg vil ikke ha de gale Regex-ene dine!')]
        else:
            self._add_last_for(kwargs['from_nick'], channel, msg)

if __name__ == '__main__':
    p = Plugin()
    #p.last_messages = {'dasbot@conference.chat.secret.no': {'foo': ['haha', u'den var daarlig, hoho!']}}
    p.listen('den var daarlig, hoho!', 'dasbot@conference.chat.secret.no', from_nick='foo')
    p.listen('bakslask / er ikke bra', 'dasbot@conference.chat.secret.no', from_nick='foo')
    print(p.listen('s/hoho/hihi/', 'dasbot@conference.chat.secret.no', from_nick='foo'))
    print(p.listen('s/hoho//', 'dasbot@conference.chat.secret.no', from_nick='foo'))
    print(p.listen('s/\//foo/', 'dasbot@conference.chat.secret.no', from_nick='foo'))
    print(p.listen('s/\//foo/', 'dasbot@conference.chat.secret.no', from_nick='bar'))
