{ ... }: final: prev: rec {
    deployBackup = { backup_name, backup_files_list, backup_url }: prev.writeShellScriptBin "deployBackup" ''
        tar cvzf /tmp/${backup_name}.tar.gz ${prev.lib.strings.concatMapStrings (x: " " + x) backup_files_list}
        curl -Ffile=@/tmp/${backup_name}.tar.gz '${backup_url}'
        rm /tmp/${backup_name}.tar.gz
        logger "${backup_name} backup completed $(date)"
    '';
}