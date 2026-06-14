{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];
  networking.hostName = "hermes";
  networking.useHostResolvConf = false;
  networking.nameservers = [
    "9.9.9.9"
    "149.112.112.112"
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libxkbcommon
    mesa
    nspr
    nss
    pango
    udev
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libXScrnSaver
  ];

  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/ts_key";
    extraUpFlags = [
      "--ssh"
      "--advertise-tags=tag:server"
    ];
    authKeyParameters.ephemeral = false;
  };

  systemd.services.tailscaled-autoconnect = {
    startLimitIntervalSec = 300;
    startLimitBurst = 10;
    serviceConfig = {
      Type = lib.mkForce "exec";
      Restart = "on-failure";
      RestartSec = "10";
    };
  };

  services.hermes-agent = {
    enable = true;
    settings = {
      model = {
        provider = "openai-codex";
        base_url = "https://chatgpt.com/backend-api/codex";
        model = "gpt-5.4-mini";
      };
      memory.provider = "holographic";
    };
    extraDependencyGroups = [ "messaging" ];
    extraPythonPackages = [ pkgs.python312Packages.numpy ];
    extraPackages = with pkgs; [
      himalaya
      uv
    ];
    environment = {
      NIX_LD = "/run/current-system/sw/share/nix-ld/lib/ld.so";
      NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
    };
    addToSystemPackages = true;
  };

  system.stateVersion = "26.05";

}
