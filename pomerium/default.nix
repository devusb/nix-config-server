{ pkgs, ... }:
let
  pomeriumConfig = pkgs.writeText "config.yaml" (builtins.readFile ../aws-proxy/pomerium/config.yaml);
  redisConfig = pkgs.writeText "redis.conf" ''
    dir /data
  '';
  entrypoint = pkgs.writeShellScriptBin "entrypoint.sh" ''
    # Create the tun device path if required
    if [ ! -d /dev/net ]; then mkdir /dev/net; fi
    if [ ! -e /dev/net/tun ]; then  mknod /dev/net/tun c 10 200; fi

    # Wait 5s for the daemon to start and then run tailscale up to configure
    /bin/sh -c "${pkgs.coreutils}/bin/sleep 5; ${pkgs.tailscale}/bin/tailscale up --accept-routes --accept-dns --authkey=$TAILSCALE_AUTHKEY" &
    exec ${pkgs.tailscale}/bin/tailscaled --state=/data/tailscaled.state &
    ${pkgs.redis}/bin/redis-server ${redisConfig} &
    ${pkgs.pomerium}/bin/pomerium -config "${pomeriumConfig}"

  '';
in
{
  name = "pomerium-proxy";
  contents = with pkgs; [
    coreutils
    dockerTools.caCertificates
    dockerTools.fakeNss
    dockerTools.binSh
    tailscale
    pomerium
    redis
  ];
  config.Cmd = [ "${entrypoint}/bin/entrypoint.sh" ];
}
