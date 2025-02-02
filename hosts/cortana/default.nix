{ pkgs, lib, ... }:
{
  imports = [
    ../common/builder.nix
  ];

  system.stateVersion = 5;

  environment.systemPackages = with pkgs; [
    tart
  ];

  networking.hostName = "cortana";

  launchd.user.agents.vm-kube1 = {
    command = "${lib.getExe pkgs.tart} run talos --net-bridged=en0 --no-graphics";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Background";
    };
  };

}
