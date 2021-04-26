terraform {
  backend "local" {
    path = "./data/tfstate/terraform.tfstate"
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  nixos_machines = {
    test1 = { mem_mb = 512, disk_gb = 10 },
    test2 = { mem_mb = 512, disk_gb = 10 },
  }
  ubuntu_machines = {
    test3 = { mem_mb = 3096, disk_gb = 10 },
  }
}

resource "libvirt_cloudinit_disk" "cloud_init_ubuntu" {
  name      = "cloud-init-ubuntu.iso"
  pool      = "default"
  user_data = file("${path.module}/data/cloud-init-ubuntu.cfg")
}

resource "libvirt_volume" "nixos_disk" {
  for_each         = local.nixos_machines
  name             = each.key
  base_volume_pool = "default"
  base_volume_name = "base-nixos"
  size             = each.value.disk_gb == null ? null : each.value.disk_gb * pow(1024, 3)
}

resource "libvirt_volume" "ubuntu_disk" {
  for_each         = local.ubuntu_machines
  name             = each.key
  base_volume_pool = "default"
  base_volume_name = "base-ubuntu"
  size             = each.value.disk_gb == null ? null : each.value.disk_gb * pow(1024, 3)
}

resource "libvirt_domain" "nixos_vm" {
  for_each = local.nixos_machines
  name     = each.key
  vcpu     = 2
  memory   = each.value.mem_mb
  disk {
    volume_id = libvirt_volume.nixos_disk[each.key].id
  }
  network_interface {
    network_name = "default"
  }
}

resource "libvirt_domain" "ubuntu_vm" {
  for_each = local.ubuntu_machines
  name     = each.key
  vcpu     = 2
  memory   = each.value.mem_mb
  disk {
    volume_id = libvirt_volume.ubuntu_disk[each.key].id
  }
  network_interface {
    network_name = "default"
  }
  cloudinit = libvirt_cloudinit_disk.cloud_init_ubuntu.id
}

# does not work on first deployment because dhcp is not started yet
#output "ipv4" {
#  value = values(libvirt_domain.nixos_vm)[*].network_interface.0.addresses
#}
