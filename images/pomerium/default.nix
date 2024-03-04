{ pkgs, ... }:
let
  pomeriumConfig = pkgs.writeText "config.yaml" (builtins.readFile ./config.yaml);
  entrypoint = pkgs.writeShellScriptBin "entrypoint.sh" ''
    # Create the tun device path if required
    if [ ! -d /dev/net ]; then mkdir /dev/net; fi
    if [ ! -e /dev/net/tun ]; then  mknod /dev/net/tun c 10 200; fi

    # Wait 5s for the daemon to start and then run tailscale up to configure
    /bin/sh -c "${pkgs.coreutils}/bin/sleep 5; ${pkgs.tailscale}/bin/tailscale up --accept-routes --accept-dns=false --authkey=$TAILSCALE_AUTHKEY" &
    exec ${pkgs.tailscale}/bin/tailscaled --state=/data/tailscaled.state &
    ${pkgs.pomerium}/bin/pomerium -config "${pomeriumConfig}"

  '';
in
{
  name = "pomerium-proxy";
  tag = "latest";
  contents = with pkgs; [
    coreutils
    dockerTools.caCertificates
    dockerTools.fakeNss
    dockerTools.binSh
    tailscale
    pomerium
  ];
  config.Cmd = [ "${entrypoint}/bin/entrypoint.sh" ];
}
