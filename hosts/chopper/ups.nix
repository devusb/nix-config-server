{ ... }:
{
  services.apcupsd = {
    enable = true;
  };
  services.prometheus.exporters.apcupsd = {
    enable = true;
  };
}
