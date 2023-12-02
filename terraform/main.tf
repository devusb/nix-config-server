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
  pm_api_url  = "https://192.168.99.101:8006/api2/json"
  pm_user     = data.vault_generic_secret.proxmox.data.username
  pm_password = data.vault_generic_secret.proxmox.data.password
}

locals {
  ssh_key = <<-EOT
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5rmy7r//z1fARqDe6sIu5D4Nt5uD3rRvwtADDgb+sS6slv6I51Gm2rKcxDIHgYBSyhTDIuhNHlnn+cyJK4ZPxyZFxF0Vy0fZIFG3Y7AqkyQ0oXEDGYyqfL8U0mi0uGKmVW02T45w16REJG3x77uncw8VVxdEpKuYw+wk7uRlQpP/UiFYWsX4NS9rUS/aZrYZ2ys1/dCPqvz4KPXk7SZrqyqkiumIr8O0wluYI5FwhMtd3xpD9AQVI3V0zjYZPwesL+BkW4CAAm5dSnsns3haAuWHti/QLSR+90k15KhflXlq6JDzE4jrMbd1DYZqoVuTgoZxDB3HDJwEwpbYCWKLFaGR6ZDhE3NeFikNkdDRrlIcrK1wJCEO2QuDZ43IE/bDhLhOmqfliL6kRr+2G1AvY4Hr0jnJHbbHqN9mES5+VJZuhH2ii+QHS70VZN0NNQv7f0QJqiTVcUVuPXksBp6oojbkXK79CWd1X0u3shd6XinZ5N3KAD4PT8zlTCmglXNYamc1JpRqKzgFwgFcljXpHwtfuezpNVmzo1Vqi6Ib9S8qJi9rahhsafYP3Y+8EV3Ii3oXmGQBSwumAHCQIkiQ/Sc+FRS02GRgWuYOaQfvW99kLXbX+0eCMSdCJSLC+H1cO2b451qpDGGDnH9w+EvS04oyv4yufpwFlhys7qfU6HQ== mhelton@gmail.com
  EOT
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
  cores  = 4

  rootfs {
    storage = "local-zfs"
    size    = "10G"
  }

  mountpoint {
    key  = "0"
    slot = 0
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
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    hwaddr   = "F6:C3:6B:61:F7:FB"
  }

  features {
    nesting = true
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
    size    = "16G"
  }
  memory = 2048
  swap   = 1024
  cores  = 2

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    hwaddr   = "36:0C:72:1C:83:84"
  }

  features {
    nesting = true
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

  memory = 4096
  swap   = 2048
  cores  = 4

  rootfs {
    storage = "local-zfs"
    size    = "10G"
  }

  mountpoint {
    key  = "0"
    slot = 0
    # uncomment below to init new instance
    #storage = "/r2d2_0/media"
    storage = ""
    volume  = "/r2d2_0/media"
    mp      = "/media"
    size    = "256G"
  }

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    hwaddr   = "22:71:BA:E3:0B:6C"
  }

  features {
    nesting = true
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "atuin" {
  target_node  = "r2d2"
  hostname     = "atuin"
  ostemplate   = "local:vztmpl/nixos-system-unstable-112222.tar.xz"
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
  cores  = 4

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    hwaddr   = "36:77:FD:22:7E:9C"
  }

  features {
    nesting = true
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "fileshare" {
  target_node  = "r2d2"
  hostname     = "fileshare"
  ostemplate   = "local:vztmpl/nixos-system-unstable-112222.tar.xz"
  unprivileged = false
  ostype       = "nixos"
  cmode        = "console"
  onboot       = "true"
  startup      = "order=1,up=30"

  memory = 2048
  swap   = 1024
  cores  = 4

  rootfs {
    storage = "local-zfs"
    size    = "8G"
  }

  mountpoint {
    key  = "0"
    slot = 0
    # uncomment below to init new instance
    #storage = "/r2d2_0/media"
    storage = ""
    volume  = "/r2d2_0/media"
    mp      = "/mnt/media"
    size    = "256G"
  }
  mountpoint {
    key  = "1"
    slot = 1
    # uncomment below to init new instance
    #storage = "/r2d2_0/homes"
    storage = ""
    volume  = "/r2d2_0/homes"
    mp      = "/mnt/homes"
    size    = "256G"
  }
  mountpoint {
    key  = "2"
    slot = 2
    # uncomment below to init new instance
    #storage = "/r2d2_0/homes/mhelton"
    storage = ""
    volume  = "/r2d2_0/homes/mhelton"
    mp      = "/mnt/homes/mhelton"
    size    = "256G"
  }
  mountpoint {
    key  = "3"
    slot = 3
    # uncomment below to init new instance
    #storage = "/r2d2_0/homes/ilona"
    storage = ""
    volume  = "/r2d2_0/homes/ilona"
    mp      = "/mnt/homes/ilona"
    size    = "256G"
  }
  mountpoint {
    key  = "4"
    slot = 4
    # uncomment below to init new instance
    #storage = "/r2d2_0/backup"
    storage = ""
    volume  = "/r2d2_0/backup"
    mp      = "/mnt/backup"
    size    = "256G"
  }

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    hwaddr   = "3A:C9:F7:CB:0A:B3"
  }

  features {
    nesting = true
    mount   = "nfs"
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "vault" {
  target_node  = "r2d2"
  hostname     = "vault"
  ostemplate   = "local:vztmpl/nixos-system-unstable-112222.tar.xz"
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
  cores  = 4

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    hwaddr   = "42:B5:CC:D5:0F:37"
  }

  features {
    nesting = true
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "attic" {
  target_node  = "r2d2"
  hostname     = "attic"
  ostemplate   = "local:vztmpl/nixos-system-unstable-112222.tar.xz"
  unprivileged = true
  ostype       = "nixos"
  cmode        = "console"
  onboot       = "true"

  memory = 2048
  swap   = 4096
  cores  = 4

  rootfs {
    storage = "local-zfs"
    size    = "10G"
  }

  mountpoint {
    key  = "0"
    slot = 0
    # uncomment below to init new instance
    #storage = "/r2d2_0/nix-cache"
    storage = ""
    volume  = "/r2d2_0/nix-cache"
    mp      = "/nix-cache"
    size    = "256G"
  }

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    hwaddr   = "B6:E3:2E:6C:E0:76"
  }

  features {
    nesting = true
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "miniflux" {
  target_node  = "r2d2"
  hostname     = "miniflux"
  ostemplate   = "local:vztmpl/nixos-system-x86_64-linux-091723.tar.xz"
  password     = "nixos"
  unprivileged = true
  ostype       = "nixos"
  cmode        = "console"
  onboot       = true

  rootfs {
    storage = "local-zfs"
    size    = "8G"
  }
  memory = 1024
  swap   = 512
  cores  = 1

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    hwaddr   = "06:EF:31:76:DA:8B"
  }

  features {
    nesting = true
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "obsidian" {
  target_node  = "r2d2"
  hostname     = "obsidian"
  ostemplate   = "local:vztmpl/nixos-system-x86_64-linux-091723.tar.xz"
  password     = "nixos"
  unprivileged = true
  ostype       = "nixos"
  cmode        = "console"
  onboot       = true

  rootfs {
    storage = "local-zfs"
    size    = "8G"
  }
  memory = 1024
  swap   = 512
  cores  = 1

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    hwaddr   = "AE:74:B1:DB:DA:52"
  }

  features {
    nesting = true
  }

  ssh_public_keys = local.ssh_key
}

resource "proxmox_lxc" "jellyfin" {
  target_node  = "r2d2"
  hostname     = "jellyfin"
  ostemplate   = "local:vztmpl/nixos-22_05-070322.tar.xz"
  unprivileged = true
  ostype       = "nixos"
  cmode        = "console"
  onboot       = "true"

  memory = 8192
  swap   = 4096
  cores  = 4

  rootfs {
    storage = "local-zfs"
    size    = "20G"
  }

  mountpoint {
    key  = "0"
    slot = 0
    # uncomment below to init new instance
    storage = "/r2d2_0/media"
    #storage = ""
    volume  = "/r2d2_0/media"
    mp      = "/media"
    size    = "256G"
  }

  network {
    name     = "eth0"
    bridge   = "vmbr0"
    ip       = "dhcp"
    tag      = 20
    ip6      = "dhcp"
    firewall = false
    # hwaddr   = "F6:C3:6B:61:F7:FB"
  }

  features {
    nesting = true
  }

  ssh_public_keys = local.ssh_key
}
