;; -*- coding: utf-8 -*-
(import [slixmpp [ClientXMPP]])
(import [.Context [Context]])
(import sys)

(defclass XMPPContext [Context]
  (defn --init-- [self message stream from-nick jid bot-name stream-type]
    (.--init-- (super) message stream from-nick bot-name)
    (setv self.type stream-type self.jid jid))

  (defn --repr-- [self]
    (+ f"XMPPContext [message: {self.message}, stream: {self.stream}, "
       f"from-nick: {self.from-nick}, name: {self.name}, self-nick: {self.self-nick}"
       f", type: {self.type}, jid: {self.jid}]")))

(defclass XMPP [ClientXMPP]
  (defn --init-- [self cmd listen config]
    (setv
      self.cmd cmd
      self.listen listen
      self.xmpp-conf (get config "XMPP")
      self.nick (get config "nick")
      self.rooms (get config "rooms")
      self.admins (get config "XMPP" "admins")
      self.cmdp (get config "command_prefix"))
    (ClientXMPP.--init-- self (get self.xmpp-conf "jid") (get self.xmpp-conf "password"))
    (.register_plugin self "xep_0030")
    (.register_plugin self "xep_0045")
    (.register_plugin self "xep_0199"))

  (defn join-room [self room]
    (.join-muc (get self.plugin "xep_0045") room self.nick :wait True))

  (defn leave-room [self room]
    (.leave-muc (get self.plugin "xep_0045") room self.nick :msg "I don't wanna be here!"))

  (defn session-start [self event]
    (.send_presence self)
    (.get_roster self)
    (for [room self.rooms]
      (self.join-room room)))

  (defn group-message [self msg]
    (setv context (XMPPContext (.strip (. msg ["body"]))
                               (.join "" (. msg ["from"] bare))
                               (. msg ["mucnick"])
                               (. msg ["from"] bare)
                               self.nick
                               (. msg ["type"])))
    (and (!= context.from-nick self.nick)
         (if (= (get context.message 0) self.cmdp)
             (do
               (setv split-cmd (.split context.message " "))
               (self.cmd
                 (cut (get split-cmd 0) 1)
                 (.join " " (cut split-cmd 1))
                 :admin (in context.from-nick self.admins)
                 :context context))
             (self.listen context.message :context context))))

  (defn message [self msg]
    (if (in (get msg "type") ["chat" "normal"])
        (do (setv context (XMPPContext (.strip (. msg ["body"]))
                               (.join "" (. msg ["from"] bare))
                               (. msg ["from"] user)
                               (. msg ["from"] bare)
                               self.nick
                               (. msg ["type"])))
            (if (and (!= context.from-nick self.nick) (= (get context.message 0) self.cmdp))
                (do
                  (setv split-cmd (.split context.message " "))
                  (self.cmd
                    (cut (get split-cmd 0) 1)
                    (.join " " (cut split-cmd 1))
                    :admin (in context.jid (get self.xmpp-conf "admins"))
                    :context context))))))

  (defn outbound-message [self message context &kwargs kw]
    (.send-message self :mto context.stream :mbody message :mtype context.type))

  (defn start [self]
    (self.add_event_handler "session_start" self.session-start)
    (self.add_event_handler "groupchat_message" self.group-message)
    (self.add_event_handler "message" self.message)
    (.connect self)
    (.process self :forever True))

  (defn protocol-stop [self]))
