(import [sleekxmpp [ClientXMPP JID]])
(import [sleekxmpp.exceptions [IqError IqTimeout]])
(import [Message [Message]])

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
        (do (setv context (Message (.join "" (. msg ["from"] bare))
                                   (. msg ["type"])
                                   (. msg ["body"])
                                   (. msg ["from"] resource)))
            (if (and (!= context.from-nick self.nick) (= (get context.message 0) self.cmdp))
                (do
                  (setv split-cmd (.split context.message " "))
                  (.cmd self
                        (cut (get split-cmd 0) 1)
                        (.join " " (cut split-cmd 1))
                        :admin True
                        :context context))))))

  (defn group-message [self msg]
    (setv context (Message (.join "" (. msg ["from"] bare))
                           (. msg ["type"])
                           (. msg ["body"])
                           (. msg ["from"] resource)))
    (and (!= context.from-nick self.nick)
         (if (= (get context.message 0) self.cmdp)
             (do
               (setv split-cmd (.split context.message " "))
               (.cmd self
                     (cut (get split-cmd 0) 1)
                     (.join " " (cut split-cmd 1))
                     :admin '()
                     :context context))
             (.listen self context.message :context context))))

  (defn cmd [self command args &kwargs kwargs]
    (if (and (in "admin" kwargs) (get kwargs "admin") args (not (in " " args)) (in "@" args))
        (cond [(= command "join") (.join-room self args)]
              [(= command "leave") (.leaveMUC
                                     (get self.plugin "xep_0045")
                                     args
                                     self.nick
                                     :msg "I don't wanna be here!")])))

  (defn listen [self message &kwargs kwargs])

  (defn outbound-message [self message context &kwargs kwargs]
    (setv parsed-message (if (in "to" kwargs) f"{(get kwargs \"to\")}: {message}" message))
    (.send-message self :mto context.stream :mbody parsed-message :mtype context.type))

  (defn --init-- [self config]
    (setv self.nick (get config "nick"))
    (setv self.rooms (get config "rooms"))
    (setv self.cmdp (get config "command_prefix"))
    (ClientXMPP.--init--
      self
      (get config "username")
      (get config "password"))

    (self.add_event_handler "session_start" self.session-start)
    (self.add_event_handler "groupchat_message" self.group-message)
    (self.add_event_handler "message" self.message)))
