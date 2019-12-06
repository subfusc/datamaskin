# Admin Commands

[Back](/datamaskin/)

These are the commands available to admins of the bot ordered by
functionality type.

Who the admins are is determined by the protocol that is run. The criteria
for the current protocols are:

- `terminal` Always admin
- `xmpp` Needs to be able to message the bot directly and be in the
  XMPP > admins list in the config.

## Cron

- `cron-del <uuid>` Delete a job from the queue.
- `cron-job <id>` Show details about a job (inkl. `uuid`)
- `cron-list` List all jobs by id and name/(time to run)
- `cron-new` Forcefully make a new cron by starting a new process
- `cron-reset` Delete all jobs in the queue

## Plugins

- `force-unload <plugin>` Unload a plugin from the system without attempting to run (stop)
- `load [plugin]` Load a plugin. If no arg is given, it shows unloaded plugins available.
- `reload <plugin>` Reload a plugin including refreshing the code
- `unload [plugin]` Unload a plugin including removing the code from the system. If
  no plugin is given, list loaded plugins.

## Protocol

- `join <room>` Attempt to join a room if the protcol implementation supports it
- `part <room>` Leave a room
