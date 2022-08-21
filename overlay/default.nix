{ nixpkgs-stable, ... }: final: prev: rec {
  stable = import nixpkgs-stable { system = prev.system; };

  deployBackup = { backup_name, backup_files_list, backup_url ? http://192.168.20.133:25478/upload?token=59af2e561fc9f80a9bb9 }:
    prev.writeShellScriptBin "deployBackup" ''
      tar cvzf /tmp/${backup_name}.tar.gz ${prev.lib.strings.concatMapStrings (x: " " + x) backup_files_list}
      curl -Ffile=@/tmp/${backup_name}.tar.gz '${backup_url}'
      rm /tmp/${backup_name}.tar.gz
      logger "${backup_name} backup completed $(date)"
    '';
  blockyConfig = import ./blocky-config.nix;

  pomerium = prev.callPackage ./pomerium { envoy = stable.envoy; };
}
