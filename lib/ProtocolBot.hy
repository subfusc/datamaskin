(import [sleekxmpp [ClientXMPP JID]])
(import [sleekxmpp.exceptions [IqError IqTimeout]])
(import [.protocols [ProtocolGlue]])

(defclass ProtocolBot [ProtocolGlue]
  (defn --init-- [self config]
    (.--init-- (super) config)))

(defmain [&rest _]
  (.start (ProtocolBot {"nick" "Test" "command_prefix" "!"})))
