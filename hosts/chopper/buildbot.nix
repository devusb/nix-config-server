{
  config,
  pkgs,
  lib,
  caddyHelpers,
  ...
}:
{
  sops.secrets.buildbot_github_app_secret_key.owner = "buildbot";
  sops.secrets.buildbot_github_oauth_secret.owner = "buildbot";
  sops.secrets.buildbot_github_webhook_secret.owner = "buildbot";
  sops.secrets.buildbot_nix_worker_password.owner = "buildbot";
  sops.secrets.buildbot_nix_workers.owner = "buildbot";

  services.buildbot-nix.master = {
    enable = true;
    domain = "buildbot.devusb.us";
    useHTTPS = true;

    workersFile = config.sops.secrets.buildbot_nix_workers.path;

    buildSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    admins = [
      "devusb"
    ];

    github = {
      authType.app = {
        id = 1016931;
        secretKeyFile = config.sops.secrets.buildbot_github_app_secret_key.path;
      };
      oauthId = "Iv23liDS2QmUZzhs73tk";
      oauthSecretFile = config.sops.secrets.buildbot_github_oauth_secret.path;
      webhookSecretFile = config.sops.secrets.buildbot_github_webhook_secret.path;
    };
  };

  services.nginx.enable = lib.mkForce false;

  services.buildbot-nix.worker = {
    enable = true;
    workerPasswordFile = config.sops.secrets.buildbot_nix_worker_password.path;
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "buildbot.${domain}" = helpers.mkVirtualHost config.services.buildbot-master.port;
  };

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "the-doctor";
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
