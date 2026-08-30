{ ... }:
{
  microvm = {
    registerWithMachined = true;
    vsock.ssh.enable = true;
    credentialFiles.TS_AUTHKEY = "/run/secrets/ts_key";
    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
        posixAcl = false;
      }
    ];
    volumes = [
      {
        image = "state.img";
        mountPoint = "/var/lib";
        size = 1024;
      }
    ];
  };

  services.openssh.hostKeys = [
    {
      path = "/var/lib/sshd/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  services.tailscale = {
    enable = true;
    authKeyFile = "/run/credentials/@system/TS_AUTHKEY";
    authKeyParameters = {
      ephemeral = false;
      preauthorized = true;
    };
    extraUpFlags = [
      "--advertise-tags=tag:server"
      "--ssh"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHD+tZ4hf4MhEW+akoZbXPN3Zi4cijSkQlX6bZlnV+Aq mhelton@gmail.com"
  ];

  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.networks."20-lan" = {
    matchConfig.Type = "ether";
    gateway = [ "192.168.20.1" ];
    dns = [ "192.168.20.1" ];
  };

  system.stateVersion = "26.05";
}
