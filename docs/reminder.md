# Reminder

[Back](/datamaskin/)

Add a reminder for your self or someone else in the bot so that it
will remind you of that after some time.

## Command
- `reminder [time] [message]` Set a reminder for your self that will
  be sendt after `time`

## Listen
`remind me in [time] [message]` and `minn meg på om [time] [message]`
will both add a reminder for you. The bot will confirm that it has set
a reminder for you.

## Time
the `time` object is the amount of time you want it to wait before
reminding you about your message. It is written using a sequence of
`{number} {what}`. e.g. `2 hours`, `2h`, `2 dager og 5 timer` and `2
days 6 hours and 45 minutes` are all valid. It will accept english
and norwegian sequences.

### List of accepted words
- d, day, days, dag, dager
- t, time, timer
- h, hour, hours
- m, minutt, minutter, minute, mintues
- s, second, seconds, sekund, sekunder
