{ ... }:
{
  microvm.vms.echoip = {
    extraModules = [ ./common.nix ];
    config = {
      microvm = {
        vcpu = 1;
        mem = 512;
        vsock.cid = 3;
        interfaces = [
          {
            type = "tap";
            id = "vm-echoip";
            mac = "02:00:00:00:20:01";
          }
        ];
      };

      systemd.network.networks."20-lan".address = [ "192.168.20.50/23" ];

      services.echoip.enable = true;
      networking.firewall.allowedTCPPorts = [ 8080 ];
    };
  };
}
