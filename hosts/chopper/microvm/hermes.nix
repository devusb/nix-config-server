{ ... }:
{
  microvm.vms.vm-hermes = {
    extraModules = [ ./common.nix ];
    config =
      { pkgs, ... }:
      {
        microvm = {
          vcpu = 4;
          mem = 8192;
          vsock.cid = 4;
          interfaces = [
            {
              type = "tap";
              id = "vm-hermes";
              mac = "02:00:00:00:20:02";
            }
          ];
          volumes = [
            {
              image = "containers.img";
              mountPoint = "/var/lib/containers";
              size = 32768;
            }
            {
              image = "hermes.img";
              mountPoint = "/var/lib/hermes";
              size = 32768;
            }
          ];
        };

        systemd.network.networks."20-lan".address = [ "192.168.20.51/23" ];

        virtualisation.oci-containers = {
          backend = "podman";
          containers.hermes = {
            image = "docker.io/nousresearch/hermes-agent:v2026.8.31";
            environment = {
              HERMES_DASHBOARD = "1";
              HERMES_DASHBOARD_HOST = "127.0.0.1";
              HERMES_DASHBOARD_PORT = "9119";
            };
            volumes = [ "/var/lib/hermes:/opt/data" ];
            extraOptions = [ "--network=host" ];
            cmd = [
              "gateway"
              "run"
            ];
          };
        };

        users.users.mhelton.extraGroups = [ "podman" ];

        environment.systemPackages = with pkgs; [
          (writeShellScriptBin "hermes" ''
            export CONTAINER_HOST=unix:///run/podman/podman.sock
            exec ${pkgs.podman}/bin/podman exec -it hermes hermes "$@"
          '')
          neovim
          bottom
        ];
      };
  };
}
