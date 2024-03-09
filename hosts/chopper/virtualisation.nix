{ ... }: {
  virtualisation.libvirtd = {
    enable = true;
    allowedBridges = [
      "virbr0"
    ];
  };

  users.users.mhelton.extraGroups = [ "libvirtd" ];

  networking = {
    interfaces.enp5s0.useDHCP = false;
    bridges = {
      virbr0 = {
        interfaces = [
          "enp5s0"
        ];
      };
    };
  };

}
