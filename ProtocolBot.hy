(import [sleekxmpp [ClientXMPP JID]])
(import [sleekxmpp.exceptions [IqError IqTimeout]])
(import protocols)

(defclass ProtocolBot [protocols.ProtocolGlue]
  (defn --init-- [self config]
    (.--init-- (super) config)))

(defmain [&rest _]
  (.start (ProtocolBot {"nick" "Test" "command_prefix" "!"})))
