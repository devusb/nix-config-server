{ ... }:
{
  services.target.enable = true;
  environment.etc."target/saveconfig.json".enable = false;
  users.users.csi = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIF0qmRb3RibvaLyXJToFP4jZY+69Q3ChyFEBak2DMpm csi@kube"
    ];
    extraGroups = [
      "wheel"
    ];
  };

}
