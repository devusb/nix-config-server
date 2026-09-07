{
  config,
  pkgs,
  caddyHelpers,
  ...
}:
let
  atticPush = pkgs.writeShellScript "nixbot-attic-push" ''
    set -eu -o pipefail
    attic login r2d2 https://attic.springhare-egret.ts.net "$(< "$CREDENTIALS_DIRECTORY/attic-token")"
    exec attic push --stdin r2d2
  '';
in
{
  sops.secrets.buildbot_github_app_secret_key.owner = "nixbot";
  sops.secrets.buildbot_github_oauth_secret.owner = "nixbot";
  sops.secrets.buildbot_github_webhook_secret.owner = "nixbot";

  services.nixbot = {
    enable = true;
    domain = "buildbot.devusb.us";
    useHTTPS = true;

    buildSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    admins = [
      "github:devusb"
    ];

    github = {
      enable = true;
      appId = 1016931;
      appSecretKeyFile = config.sops.secrets.buildbot_github_app_secret_key.path;
      oauthId = "Iv23liDS2QmUZzhs73tk";
      oauthSecretFile = config.sops.secrets.buildbot_github_oauth_secret.path;
      webhookSecretFile = config.sops.secrets.buildbot_github_webhook_secret.path;
    };

    uploaders = [
      {
        name = "attic";
        command = [ "${atticPush}" ];
        pathsVia = "stdin";
      }
    ];

    nginx.enable = false;
  };

  systemd.services.nixbot = {
    path = [ pkgs.attic-client ];
    serviceConfig.LoadCredential = [ "attic-token:${config.sops.secrets.attic_token.path}" ];
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "buildbot.${domain}" = helpers.mkVirtualHost config.services.nixbot.port;
  };

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "superintendent";
      protocol = "ssh-ng";
      sshUser = "nix";
      systems = [
        "aarch64-linux"
      ];
      maxJobs = 4;
      supportedFeatures = [
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
    }
    {
      hostName = "cortana";
      protocol = "ssh-ng";
      sshUser = "nix";
      systems = [
        "aarch64-darwin"
      ];
      maxJobs = 4;
      supportedFeatures = [
        "big-parallel"
        "kvm"
      ];
    }
  ];
}
