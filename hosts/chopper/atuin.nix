{ pkgs, config, ...}: {
  imports = [
    ../../modules/tailscale-serve.nix
  ];
  networking.hostName = "atuin";

  services.tailscale-serve = {
    enable = true;
    port = 8888;
    funnel = true;
    authKeyFile = "/run/secrets/ts_key";
  };

  services.atuin = {
    enable = true;
    host = "0.0.0.0";
    openRegistration = false;
  };

  system.stateVersion = "24.05";

}
