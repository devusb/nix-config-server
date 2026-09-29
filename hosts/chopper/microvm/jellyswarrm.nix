{ inputs, ... }:
{
  microvm.vms.vm-jellyswarrm = {
    extraModules = [
      ./common.nix
      inputs.jellyswarrm.nixosModules.default
    ];
    config = {
      microvm = {
        vcpu = 2;
        mem = 3072;
        vsock.cid = 5;
        interfaces = [
          {
            type = "tap";
            id = "vm-jellyswarrm";
            mac = "02:00:00:00:20:03";
          }
        ];
        credentialFiles.JELLYSWARRM_PASSWORD = "/run/secrets/jellyswarrm";
      };

      systemd.network.networks."20-lan".address = [ "192.168.20.52/23" ];

      services.jellyswarrm = {
        enable = true;
        host = "127.0.0.1";
        passwordFile = "/run/credentials/@system/JELLYSWARRM_PASSWORD";
        package = inputs.jellyswarrm.packages.x86_64-linux.jellyswarrm.overrideAttrs (old: {
          preBuild = old.preBuild + ''
            sed -i 's/^UI_VERSION=.*/UI_VERSION=12.0.0/' crates/jellyswarrm-proxy/static/ui-version.env
          '';
        });
      };
    };
  };
}
