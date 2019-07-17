# Do you need a Beefy Builder (tm) in your life?

Spin up a temporary beefy build server in a few minutes using Terraform.

## Necessary set-up

The `shell.nix` file contains all necessary dependencies.

1. Make sure you have your Packet API token handy. You can get it in your user
   profile on Packet.
2. Make sure your AWS credentials are set up in `~/.aws/credentials`. You will
   need an API Key that can write to our production account, in order to set up
   the DNS pointing at the server on `serokell.org`.

Copy `.envrc.example` to `.envrc`, fill out the placeholders, and run `direnv
allow`.

## Structure

The infrastructure definition is in `builder.tf`, and defines a single
`c2.medium.x86` machine on Packet, and two DNS records in Route53 to point at it.

See commends in the file for how to obtain certain values, should you need to
change them.

The nix expression in `configuration.nix` configures this system to accept a set
of SSH keys on the `root` user. Add yours to the set before deploying.

## Usage

tl;dr: spin up the server with Terraform, and then push the config using
`nixos-rebuild`.
