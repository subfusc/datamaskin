;; -*- coding: utf-8 -*-
(import [.XMPP [XMPP]])
(import [.Terminal [Terminal]])

(defclass ProtocolGlue []
  ;; Protocol functions necessary to make for each protocol
  ;; * --init-- [self command-function listen-function config]
  ;; ** Initialize the protocol with the bind-back functions
  ;;    to the cmd and listen functions of the bot so that it
  ;;    can be called in the proper place in the protocol
  ;;    override.
  ;;
  ;;    Include the config, should probably be structured as
  ;;    a sub-namespace of the main config (e.g. Terminal:)
  ;;
  ;; * outbound-message [self message context &kwargs kw]
  ;; ** Should send a message on the protocol to the correct
  ;;    place based. message is the string to be sendt. Context
  ;;    is an object containing the information necessary
  ;;    to send the message to the correct place. kwargs is optional.
  ;;
  ;;    Context should be defined by the protocol respectively.
  ;; * start [self]
  ;; ** This is to start the main loop of the protocol, and should
  ;;    block the thread running it.
  ;; * protocol-stop [self]
  ;; ** TODO
  ;; Optional functions
  ;; * join-room [self room]
  ;; ** If the protocol has a room concept, this function will be
  ;;    called to join a room based on a string identifier
  ;; * leave-room [self room]
  ;; ** If join-room is defined, so should leave room

  (defn --init-- [self config]
    (setv
      self.config config
      self.protocol ((cond [(= "xmpp" (get config "protocol")) XMPP]
                           [(= "terminal" (get config "protocol")) Terminal]
                           [else (raise "Unsupported protocol, please provide one")])
                      self.cmd self.listen config)))

  ;; Placeholder functions to be overriden by the parent classes
  (defn cmd [self cmd args &kwargs kwargs])
  (defn listen [self message &kwargs kwargs])
  (defn stop [self] (.protocol-stop self.protocol))

  (defn outbound-message [self &optional [message None] [context None] &kwargs kwargs]
    (if (or (= None message) (= None context)) (raise (Exception "missing arguments")))
    (setv parsed-message (if (in "to" kwargs) f"{(get kwargs \"to\")}: {message}" message))
    (self.protocol.outbound-message parsed-message context :kwargs kwargs))

  (defn start [self] (self.protocol.start)))
