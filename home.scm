;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu home services dotfiles)
             (gnu home services fontutils)
             (gnu home services guix)
             (gnu home services shells)
             (gnu home services shepherd)
             (gnu home services ssh)
             (gnu packages)
             (gnu packages haskell-apps)
             (gnu services)
             (guix channels)
             (guix gexp))

(define kmonad-shepherd-service (lambda (_) (list
  (shepherd-service
    (provision '(kmonad-daemon))
    (documentation "Run the KMonad daemon (kmonad-daemon).")
    (start #~(make-forkexec-constructor
      ;; Consider using local-file to host the config in the Guix store.
      (list
        #$(file-append kmonad "/bin/kmonad")
        #$(local-file "config/kmonad/config.kbd" "kmonad-config.kbd"))))
    (stop #~(make-kill-destructor))
    (auto-start? #f)))))

(define kmonad-service-type (service-type
  (name 'kmonad)
  (description "Register a home Shepherd service to run a KMonad daemon.")
  (extensions (list 
    (service-extension home-shepherd-service-type kmonad-shepherd-service)))
  (default-value #f)))

(home-environment
  ;; Below is the list of packages that will show up in your
  ;; Home profile, under ~/.guix-home/profile.
  (packages (specifications->packages (list
    ;; Shells
    "fish"

    ;; Text editors
    "neovim"
    
    ;; Source control
    "git"

    ;; GUI applications 
    "foot"
    "icecat"
    "rofi"
    "sway"
    "swaylock"

    ;; Shell tools
    "curl"
    "jq"
    "tree"
    "unzip"

    ;; Utilities
    "stow"
    "kmonad"
    )))

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services (list
    ;; Configure fish to use Guix
    (simple-service 'my-fish-service home-fish-service-type (home-fish-extension
      (aliases
        '(("g" . "git")))))

    ;; Configure fontconfig
    (simple-service 'my-fontconfig-service home-fontconfig-service-type
      (list '(alias
              (family "monospace")
              (prefer (family "FiraCode Nerd Font")))))

    ;; Add Guix channels
    (simple-service 'my-channels-service home-channels-service-type
      (list (channel
		          (name 'nonguix)
		          (url "https://gitlab.com/nonguix/nonguix")
		          (introduction
			          (make-channel-introduction
				          "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
				          (openpgp-fingerprint
					          "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))))

    (service home-openssh-service-type (home-openssh-configuration
      (hosts (list
        (openssh-host
          (name "*")
          (identity-file "~/.ssh/id_ed25519"))))
      (add-keys-to-agent "yes"))) ;; This setting is not working as I expected.

    (service home-ssh-agent-service-type (home-ssh-agent-configuration
      (extra-options '("-t" "15m"))))

    ;; Register (not auto-start) a service to run a KMonad daemon.
    (service kmonad-service-type))))

