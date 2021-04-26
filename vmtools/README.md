
Running NixOS and Ubuntu VMs using libvirt provider for terraform
### Initial setup

```sh
# 1. Run nix-shell which has terraform and python with needed dependencies
$ nix-shell

# 2. Initialize terraform
$ terraform init

# 3. Put path to your public ssh key at the top of `default.nix` (you can
# generate a new one with `make ssh-key`)

# 4. Replace BASE_POOL_NAME in Makefile with your libvirt pool name (if it's not "default")

# 5. Fetch ubuntu install image
$ make fetch-ubuntu-focal

# 6. Generate base images for NixOS and Ubuntu
$ make base-nixos base-ubuntu cloud-init-ubuntu

# 7. List VMs you want to run in the `locals` section of `main.tf`

# 8. Launch all Ubuntu and NixOS VMs
$ make apply

# Your Ubuntu and NixOS instances are now available via ssh.
# To get IP addresses you can use `virsh domifaddr <machine-name>`
# or `virsh net-dhcp-leases <network-name>`
# For NixOS the username is "root", for Ubuntu the username is "ubuntu" and the password is "1".
# You can also access tty for the VMs via virt-manager.
```

### Deploying NixOS systems

```sh
# 1. Add configs you want to use to `configs` attribute in `default.nix`

# 2. Put IP addresses and configs for the NixOS machines into `deployment` at the bottom of `default.nix`

# 3. Set `IdentityFile` in the `sshconfig` file to the path to your private ssh key

# 4. Deploy all systems using ssh config from the `sshconfig` file
$ SSHOPTS="-F ./sshconfig" make deploy
```

### Cleaning up

```sh
# Destroy all Ubuntu and NixOS VMs
$ make destroy

# Recreate all Ubuntu and NixOS VMs from scratch (destroy then launch again)
$ make re
```

### Example of using `nix repl` for exploring NixOS system configs
```sh
$ nix repl ./default.nix

# just a useful alias
nix-repl> ls = f: if builtins.isAttrs f then builtins.attrNames f else f

nix-repl> ls vm.vault.config
[ "appstream" "assertions" "boot" "console" "containers" "docker-containers" "documentation" "dysnomia" "ec2" "environment" "fileSystems" "fonts" "gnu" "gtk" "hardware" "i18n" "ids" "jobs" "krb5" "lib" "location" "meta" "nesting" "networking" "nix" "nixops" "nixpkgs" "passthru" "power" "powerManagement" "programs" "qt5" "security" "services" "sound" "specialisation" "swapDevices" "system" "systemd" "time" "users" "virtualisation" "warnings" "xdg" "zramSwap" ]

nix-repl> ls vm.vault.config.systemd.services
[ "audit" "console-getty" "container-getty@" "container@" "dbus" "dhcpcd" "getty@" "network-local-commands" "network-setup" "nix-daemon" "nix-gc" "nix-optimise" "nscd" "polkit" "post-resume" "pre-sleep" "prepare-kexec" "reload-systemd-vconsole-setup" "resolvconf" "save-hwclock" "serial-getty@" "sshd" "systemd-backlight@" "systemd-fsck@" "systemd-importd" "systemd-journal-flush" "systemd-journald" "systemd-logind" "systemd-modules-load" "systemd-nspawn@" "systemd-random-seed" "systemd-remount-fs" "systemd-sysctl" "systemd-timedated" "systemd-timesyncd" "systemd-udev-settle" "systemd-udevd" "systemd-update-utmp" "systemd-user-sessions" "user-runtime-dir@" "user@" "vault" ]

nix-repl> ls vm.vault.config.systemd.services.vault.serviceConfig.ExecStart
"/nix/store/clymspy6384j2havb0axki41imazrrcl-vault-bin-1.7.0/bin/vault server '-config' '/nix/store/3l9zkmpma5klqv5hpzw0a2sljgwcchvm-vault.hcl'"
```
