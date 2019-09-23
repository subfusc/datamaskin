(import [sleekxmpp [ClientXMPP JID]])
(import [sleekxmpp.exceptions [IqError IqTimeout]])

(defclass XMPPBot [ClientXMPP]
  (defn session-start [self event]
    (.send_presence self)
    (.get_roster self)
    (for [room self.rooms]
      (self.join-room room)))

  (defn join-room [self room]
    (.joinMUC (get self.plugin "xep_0045") room self.nick :wait True))

  (defn message [self msg]
    (if (in (get msg "type") ["chat" "normal"])
        (.send (.reply msg "A message from Hy!"))))

  (defn group-message [self msg]
    (and
      (in (get msg "type") ["groupchat" "normal"])
      (!= (. msg ["from"] resource) self.nick)
      (.send (.reply msg "A message from Hy!"))))

  (defn --init-- [self jid pass nick rooms]
    (setv self.nick nick)
    (setv self.rooms rooms)
    (ClientXMPP.--init-- self jid pass)
    (self.add_event_handler "session_start" self.session-start)
    (self.add_event_handler "groupchat_message" self.group-message)
    (self.add_event_handler "message" self.message)))
