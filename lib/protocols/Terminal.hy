;; -*- coding: utf-8 -*-
(import os)
(import sys)
(import [.Context [Context]])

(defclass TerminalContext [Context]
  (defn --init--[self message bot-name]
    (.--init-- (super) message "terminal" (get os.environ "USER") bot-name)
    (setv self.admin True)))

(defclass Terminal []

  (defn --init-- [self cmd listen config]
    (setv
      self.config config
      self.cmdc (get config "command_prefix")
      self.-input sys.stdin
      self.-output sys.stdout
      self.-cmd cmd
      self.-listen listen))

  (defn args-to-cmd [self line]
    (setv split-cmd (.split (cut line 1) " "))
    {"command" (get split-cmd 0)
     "args" (.join " " (cut split-cmd 1))
     "context" (TerminalContext line (get self.config "nick"))})

  (defn args-to-listen [self line]
    {"message" line
     "context" (TerminalContext line (get self.config "nick"))})

  (defn cmd [self &kwargs kwargs]
    (setv
      command (get kwargs "command")
      args (get kwargs "args")
      (get kwargs "admin") True)
    (del (get kwargs "command"))
    (del (get kwargs "args"))
    (self.-cmd command args #** kwargs))

  (defn listen [self &kwargs kwargs]
    (setv msg (get kwargs "message"))
    (del (get kwargs "message"))
    (self.-listen msg #** kwargs))

  (defn outbound-message [self message context &kwargs kwargs]
    (print (if (in :to kwargs)
               (.format "{}: {}" kwargs[:to] message)
               message)))

  (defn wait-for-event [self]
    (setv line (input "datamaskin>> "))
    (if (= (get line 0) self.cmdc)
        (self.args-to-cmd line)
        (self.args-to-listen line)))

  (defn start [self]
    (setv exit False)
    (while (not exit)
      (setv event (self.wait-for-event))
      (cond [(and (in "command" event) (= "exit" (get event "command"))) (setv exit True)]
            [(in "command" event) (self.cmd #** event)]
            [(in "message" event) (self.listen #** event)]))))
