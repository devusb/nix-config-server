{ ... }: final: prev: rec {
  deployBackup = { backup_name, backup_files_list, backup_url ? http://192.168.20.133:25478/upload?token=59af2e561fc9f80a9bb9 }:
    prev.writeShellScriptBin "deployBackup" ''
      tar cvzf /tmp/${backup_name}.tar.gz ${prev.lib.strings.concatMapStrings (x: " " + x) backup_files_list}
      curl -Ffile=@/tmp/${backup_name}.tar.gz '${backup_url}'
      rm /tmp/${backup_name}.tar.gz
      logger "${backup_name} backup completed $(date)"
    '';

  pomerium-bin = prev.callPackage ./pomerium-bin.nix { };

  pomerium = prev.pomerium.overrideAttrs (old: rec {
    version = "0.17-git";
    src = prev.fetchFromGitHub {
      owner = "pomerium";
      repo = "pomerium";
      rev = "0-17-0";
      sha256 = "sha256-fDg+O1qPhLGBKARb1Fm/DfAUxkfe1Hq0cfklv4ax8WA=";
    };
    ldflags =
      let
        # Set a variety of useful meta variables for stamping the build with.
        setVars = {
          "github.com/pomerium/pomerium/internal/version" = {
            Version = "v0.17-git";
            BuildMeta = "nixpkgs";
            ProjectName = "pomerium";
            ProjectURL = "github.com/pomerium/pomerium";
          };
          "github.com/pomerium/pomerium/internal/envoy" = {
            OverrideEnvoyPath = "${prev.envoy}/bin/envoy";
          };
        };
        concatStringsSpace = list: prev.lib.concatStringsSep " " list;
        mapAttrsToFlatList = fn: list: prev.lib.concatMap prev.lib.id (prev.lib.mapAttrsToList fn list);
        varFlags = concatStringsSpace (
          mapAttrsToFlatList
            (package: packageVars:
              prev.lib.mapAttrsToList
                (variable: value:
                  "-X ${package}.${variable}=${value}"
                )
                packageVars
            )
            setVars);
      in
      [
        "${varFlags}"
      ];
  });
}
