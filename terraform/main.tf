terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.10"
    }
  }
  cloud {
    organization = "devusb"
    workspaces {
      name = "r2d2"
    }
  }
}

data "vault_generic_secret" "proxmox" {
  path = "secret/proxmox"
}

provider "proxmox" {
    pm_api_url = "https://192.168.99.101:8006/api2/json"
    pm_user = data.vault_generic_secret.proxmox.data.username
    pm_password = data.vault_generic_secret.proxmox.data.password
}

locals {
  ssh_key = <<-EOT
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5rmy7r//z1fARqDe6sIu5D4Nt5uD3rRvwtADDgb+sS6slv6I51Gm2rKcxDIHgYBSyhTDIuhNHlnn+cyJK4ZPxyZFxF0Vy0fZIFG3Y7AqkyQ0oXEDGYyqfL8U0mi0uGKmVW02T45w16REJG3x77uncw8VVxdEpKuYw+wk7uRlQpP/UiFYWsX4NS9rUS/aZrYZ2ys1/dCPqvz4KPXk7SZrqyqkiumIr8O0wluYI5FwhMtd3xpD9AQVI3V0zjYZPwesL+BkW4CAAm5dSnsns3haAuWHti/QLSR+90k15KhflXlq6JDzE4jrMbd1DYZqoVuTgoZxDB3HDJwEwpbYCWKLFaGR6ZDhE3NeFikNkdDRrlIcrK1wJCEO2QuDZ43IE/bDhLhOmqfliL6kRr+2G1AvY4Hr0jnJHbbHqN9mES5+VJZuhH2ii+QHS70VZN0NNQv7f0QJqiTVcUVuPXksBp6oojbkXK79CWd1X0u3shd6XinZ5N3KAD4PT8zlTCmglXNYamc1JpRqKzgFwgFcljXpHwtfuezpNVmzo1Vqi6Ib9S8qJi9rahhsafYP3Y+8EV3Ii3oXmGQBSwumAHCQIkiQ/Sc+FRS02GRgWuYOaQfvW99kLXbX+0eCMSdCJSLC+H1cO2b451qpDGGDnH9w+EvS04oyv4yufpwFlhys7qfU6HQ== mhelton@gmail.com
  EOT
}

resource "proxmox_lxc" "blocky" {
  target_node  = "r2d2"
  hostname     = "blocky"
  ostemplate   = "local:vztmpl/nixos-system-x86_64-linux.tar.xz"
  password     = "nixos"
  unprivileged = true
  ostype       = "nixos"
  cmode        = "console"
  onboot       = true

  rootfs {
    storage = "local-zfs"
    size    = "5G"
  }
  memory = 512
  swap   = 512
  cores = 1

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    tag    = 20
    ip6    = "dhcp"
    firewall = false
    hwaddr = "9A:A4:BB:CF:29:D5"
  }

  nameserver = "1.1.1.1"

  features {
    nesting     = true
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "plex" {
  target_node  = "r2d2"
  hostname     = "plex"
  ostemplate   = "local:vztmpl/nixos-22_05-070322.tar.xz"
  unprivileged = true
  ostype       = "nixos"
  cmode        = "console"
  onboot       = "true"

  memory = 8192
  swap   = 4096
  cores = 4

  rootfs {
    storage = "local-zfs"
    size    = "10G"
  }

  mountpoint {
    key     = "0"
    slot    = 0
    # uncomment below to init new instance
    #storage = "/r2d2_0/media"
    storage = ""
    volume  = "/r2d2_0/media"
    mp      = "/media"
    size    = "256G"
  }

  mountpoint {
    key     = "1"
    slot    = 1
    storage = "media"
    mp      = "/mnt/plex_data"
    size    = "30G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    tag    = 20
    ip6    = "dhcp"
    firewall = false
    hwaddr = "F6:C3:6B:61:F7:FB"
  }

  features {
    nesting     = true
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "unifi" {
  target_node  = "r2d2"
  hostname     = "unifi"
  ostemplate   = "local:vztmpl/nixos-22_05-070322.tar.xz"
  password     = "nixos"
  unprivileged = true
  ostype       = "nixos"
  cmode        = "console"
  onboot       = true

  rootfs {
    storage = "local-zfs"
    size    = "8G"
  }
  memory = 2048
  swap   = 1024
  cores = 1

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    tag    = 20
    ip6    = "dhcp"
    firewall = false
    hwaddr = "36:0C:72:1C:83:84"
  }

  features {
    nesting     = true
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "arr" {
  target_node  = "r2d2"
  hostname     = "arr"
  ostemplate   = "local:vztmpl/nixos-system-unstable-082722.tar.xz"
  unprivileged = true
  ostype       = "nixos"
  cmode        = "console"
  onboot       = "true"

  memory = 2048
  swap   = 1024
  cores = 4

  rootfs {
    storage = "local-zfs"
    size    = "10G"
  }

  mountpoint {
    key     = "0"
    slot    = 0
    # uncomment below to init new instance
    #storage = "/r2d2_0/media"
    storage = ""
    volume  = "/r2d2_0/media"
    mp      = "/media"
    size    = "256G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    tag    = 20
    ip6    = "dhcp"
    firewall = false
    hwaddr = "22:71:BA:E3:0B:6C"
  }

  features {
    nesting     = true
  }

  ssh_public_keys = local.ssh_key
}
