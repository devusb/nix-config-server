{ pkgs, ... }: {
  virtualisation.libvirtd = {
    enable = true;
  };

  users.users.mhelton.extraGroups = [ "libvirtd" ];

}
