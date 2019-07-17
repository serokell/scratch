# Configure the Packet Provider.
# Set your API Token in .envrc
provider "packet" {
  version = "~> 2.2"
}

# Configure the AWS Provider.
# Make sure your aws credentials are set up in ~/.aws/credentials
# Then set the profile name in .envrc
provider "aws" {
  version = "~> 2.2"
  region = "eu-west-2"
}

locals {
  # Project ID: Serokell Infrastructure.
  # Note: Get UUID from CP URI.
  project_id = "e3490904-7e06-442e-a84d-b74ca05f52d5"

  # Route53 Hosted Zone ID
  # Note: `aws route53 list-hosted-zones-by-name --dns-name serokell.org --max-items 1 | jq '.HostedZones[0].Id'`.
  hosted_zone_id = "/hostedzone/ZJMSUAHZF633J"
}

data "packet_operating_system" "nixos" {
  name             = "nixos"
  distro           = "NixOS"
  version          = "19.03"
  provisionable_on = "c2.medium.x86"
}

# Default root SSH keys are configured at the project-level on the Packet control panel
resource "packet_device" "builder1" {
  hostname         = "builder.serokell.org"
  plan             = "c2.medium.x86"
  facilities       = ["ams1"]
  billing_cycle    = "hourly"
  operating_system = "${data.packet_operating_system.nixos.id}"
  project_id       = "${local.project_id}"
}

# Update `builder1.serokell.org` to point to our new server
# Note: TTL is intentionally low for convenience.
resource "aws_route53_record" "builder1-ipv4" {
  zone_id = "${local.hosted_zone_id}"
  name    = "builder1"
  type    = "A"
  ttl     = "5"
  records        = ["${packet_device.builder1.access_public_ipv4}"]
}

resource "aws_route53_record" "builder1-ipv6" {
  zone_id = "${local.hosted_zone_id}"
  name    = "builder1"
  type    = "AAAA"
  ttl     = "5"
  records        = ["${packet_device.builder1.access_public_ipv6}"]
}

## Outputs used to generate networking.nix
# Note: Networks 1 and 2 will shift up if Elastic addresses are added to the intance
#   https://www.terraform.io/docs/providers/packet/r/device.html#network
output "hostname"     {value = packet_device.builder1.hostname}
output "plan"         {value = packet_device.builder1.plan}
output "ipv4_gateway" {value = packet_device.builder1.network.0.gateway}
output "ipv4_address" {value = packet_device.builder1.network.0.address}
output "ipv4_cidr"    {value = packet_device.builder1.network.0.cidr}
output "ipv6_gateway" {value = packet_device.builder1.network.1.gateway}
output "ipv6_address" {value = packet_device.builder1.network.1.address}
output "ipv6_cidr"    {value = packet_device.builder1.network.1.cidr}
output "private_gateway" {value = packet_device.builder1.network.2.gateway}
output "private_address" {value = packet_device.builder1.network.2.address}
output "private_cidr"    {value = packet_device.builder1.network.2.cidr}
