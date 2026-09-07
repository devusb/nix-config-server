{
  config,
  pkgs,
  caddyHelpers,
  ...
}:
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

    nginx.enable = false;
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

  systemd.services.attic-watch-store = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "tailscaled.service"
      config.systemd.services."container@attic".name
    ];
    requires = [
      "network-online.target"
    ];
    environment.HOME = "/var/lib/attic-watch-store";
    serviceConfig = {
      DynamicUser = true;
      MemoryHigh = "5%";
      MemoryMax = "10%";
      LoadCredential = "prod-auth-token:${config.sops.secrets.attic_token.path}";
      StateDirectory = "attic-watch-store";
      Restart = "on-failure";
      RestartSec = "60";
    };
    path = [ pkgs.attic-client ];
    script = ''
      set -eux -o pipefail
      ATTIC_TOKEN=$(< $CREDENTIALS_DIRECTORY/prod-auth-token)
      attic login r2d2 https://attic.springhare-egret.ts.net $ATTIC_TOKEN
      attic use r2d2
      exec attic watch-store r2d2
    '';
  };
}
