{ ... }:
{
  services.calibre-web = {
    enable = true;
    listen.ip = "127.0.0.1";
    options = {
      enableBookUploading = true;
      enableBookConversion = true;
      reverseProxyAuth = {
        enable = true;
        header = "X-Pomerium-Claim-Email";
      };
    };
  };
}
