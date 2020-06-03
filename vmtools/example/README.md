## How to use

Bootstrap a vm:
```sh
# Generate an ssh key
$ make ssh-key

# Create bootstrap disk image. It takes about a minute, but you only
# have to do it once
$ make image

# Run a libvirt vm from the disk image. You might need to adjust some
# parameters at the top of `Makefile`
$ make vm-create

# Monitor dhcp leases to see an ip address for the vm. You can
# also set up a local dns server for automatically resolving vm
# ip addresses, but how to do that depends on your system
$ make ip
^C
```

Then put the ip address for the vm into `sshconfig` file.

Now you have a nixos vm with ssh access which you can deploy system configurations to over ssh, just change system config used in `default.nix`

Commands you can use for managing the vm:
```sh
$ ssh -F ./sshconfig test.vm  # ssh into the vm
$ make deploy-switch          # deploy configuration.nix without rebooting
$ make deploy-reboot          # deploy configuration.nix with rebooting
$ make vm-delete              # destroy the vm
```

You can also use `nix repl` for exploring your system config:
```sh
$ nix repl ./default.nix

# just a useful alias
nix-repl> ls = f: if builtins.isAttrs f then builtins.attrNames f else f

nix-repl> ls machine.config
[ "appstream" "assertions" "boot" "console" "containers" "docker-containers" "documentation" "dysnomia" "ec2" "environment" "fileSystems" "fonts" "gnu" "gtk" "hardware" "i18n" "ids" "jobs" "krb5" "lib" "location" "meta" "nesting" "networking" "nix" "nixops" "nixpkgs" "passthru" "power" "powerManagement" "programs" "qt5" "security" "services" "sound" "specialisation" "swapDevices" "system" "systemd" "time" "users" "virtualisation" "warnings" "xdg" "zramSwap" ]

nix-repl> ls machine.config.systemd.services
[ "audit" "console-getty" "container-getty@" "container@" "dbus" "dhcpcd" "getty@" "network-local-commands" "network-setup" "nix-daemon" "nix-gc" "nix-optimise" "nscd" "polkit" "post-resume" "pre-sleep" "prepare-kexec" "resolvconf" "rngd" "save-hwclock" "serial-getty@" "sshd" "systemd-backlight@" "systemd-fsck@" "systemd-importd" "systemd-journal-flush" "systemd-journald" "systemd-logind" "systemd-modules-load" "systemd-nspawn@" "systemd-random-seed" "systemd-remount-fs" "systemd-sysctl" "systemd-timedated" "systemd-timesyncd" "systemd-udev-settle" "systemd-udevd" "systemd-update-utmp" "systemd-user-sessions" "systemd-vconsole-setup" "user-runtime-dir@" "user@" "vault" ]

nix-repl> ls machine.config.systemd.services.vault.serviceConfig.ExecStart
"/nix/store/bcrw7y84s9cdz7db4smwzz5va96z5c7r-vault-bin-1.3.0/bin/vault server -config /nix/store/arkxcfd3sx296z978wrs9gbm4pj1z38s-vault.hcl"
```