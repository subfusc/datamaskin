(import [sleekxmpp [ClientXMPP JID]])
(import [sleekxmpp.exceptions [IqError IqTimeout]])
(import [.protocols [ProtocolGlue]])

(defclass ProtocolBot [ProtocolGlue]
  (defn --init-- [self config]
    (.--init-- (super) config))

  (defn cmd [self cmd args &kwargs kwargs]
    (if (get kwargs "admin")
        (cond [(and (= "join" cmd) (> (len args) 0) (= (.count cmd " ") 0))
               (self.protocol.join-room args)]
              [(and (= "part" cmd) (> (len args) 0) (= (.count cmd " ") 0))
               (self.protocol.leave-room args)]))))
