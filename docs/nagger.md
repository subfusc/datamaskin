# Nagger plugin

[Back](/datamaskin/)

Nag people into answering!

- `nag <interval> <name> <message>` Nag someone using a message every
  interval.
- `stop-nag <name>` Stop the nagging of a given name (in case someone
  else feels its getting out of hand.
- `reset-nag` Reset all the nags (only callable by an admin).

The `interval` object is written as any variant of `1hour 2 minutes and 3s`, `1 dag 3 timer og 2 sekunder`, `3h` or similar.
