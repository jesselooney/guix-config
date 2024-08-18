(use-modules
	(gnu)
	(nongnu packages linux)
	(nongnu system linux-initrd))
(use-service-modules desktop networking ssh xorg)
(use-package-modules haskell-apps shells)

;; Most of this is from a minimalist example in "Using the Configuration System" in the GNU Guix manual.

;; From https://lists.gnu.org/archive/html/help-guix/2023-12/msg00130.html
(define swaylock-pam-service-type
(service-type 
	(name 'swaylock-pam)
	(description "swaylock needs /etc/pam.d/swaylock configuration.")
	(extensions (list
		(service-extension pam-root-service-type
			(lambda (_) (list
				(pam-service
					(name "swaylock")
					(auth (list 
						(pam-entry
							(control "include")
							(module "login"))))))))))
	(default-value #f)))



(operating-system
	;; Icky nonfree firmware stuff
	(kernel linux)
	(initrd microcode-initrd)
	(firmware (list linux-firmware))

	(host-name "mercurius")
	(timezone "America/New_York")
	(locale "en_US.utf8")

	(keyboard-layout (keyboard-layout "us" "colemak_dh" #:options '("caps:swapescape")))

	(bootloader (bootloader-configuration
		(bootloader grub-efi-bootloader)
		(targets '("/boot"))
		(keyboard-layout keyboard-layout)))

	(mapped-devices
		(list (mapped-device
			(source (uuid "c2ac528f-6641-4e5d-b37e-941135007bad"))
			(target "root")
			(type luks-device-mapping))))

	(file-systems (append
		(list
			(file-system
				(device (file-system-label "root"))
				(mount-point "/")
				(type "ext4")
				(dependencies mapped-devices))
			(file-system
				(device (uuid "9224-002C" 'fat))
				(mount-point "/boot")
				(type "vfat")))
		%base-file-systems))

	(users (cons
		(user-account
			(name "jl")
			(comment "Jesse")
			(shell (file-append fish "/bin/fish"))
			(group "users")
			(home-directory "/home/jl")
			(supplementary-groups '("wheel" "input" "lp")))
		%base-user-accounts))

	(packages (append
		(specifications->packages (list
			"bluez"
			"fish"
			"kmonad"))
		%base-packages))

		(services (modify-services
		(cons*
			(service bluetooth-service-type)
			(service nftables-service-type)
			(service openssh-service-type (openssh-configuration
				(permit-root-login #f)
				(password-authentication? #f)))
			(service swaylock-pam-service-type)
			%desktop-services)

		(guix-service-type config => (guix-configuration
			(inherit config)
			(substitute-urls (cons
				"https://substitutes.nonguix.org"
				%default-substitute-urls))
			(authorized-keys (cons
				(local-file "./nonguix-signing-key.pub")
				%default-authorized-guix-keys))))

		(delete gdm-service-type)

		(udev-service-type config => (udev-configuration
			(inherit config)
			(rules (cons
				kmonad
				(udev-configuration-rules config)))))))

	(name-service-switch %mdns-host-lookup-nss))
