{ ... }:
{
  virtualisation.incus.enable = true;
  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = [ "incusbr0" ];
  virtualisation.incus.ui.enable = true;
}
