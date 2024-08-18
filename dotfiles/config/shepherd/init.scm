(define kmonad
  (service
    '(kmonad-daemon)
    #:start (make-forkexec-constructor
      '("$HOME_ENVIRONMENT/profile/bin/kmonad" "$XDG_CONFIG_HOME/kmonad/config.kbd"))
    #:stop (make-kill-destructor)
    #:respawn? #t))

(register-services (list kmonad))
;;(start-in-the-background '(kmonad))
