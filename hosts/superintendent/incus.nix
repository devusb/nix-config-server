{ ... }:
{
  virtualisation.incus.enable = true;
  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = [
    "incusbr0"
    "tailscale0"
  ];
  virtualisation.incus.ui.enable = true;
  systemd.services.tailscaled.environment = {
    TS_DEBUG_FIREWALL_MODE = "nftables";
  };
}
