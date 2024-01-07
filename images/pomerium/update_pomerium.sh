nix build .#images.pomerium
podman load < result
podman push localhost/pomerium-proxy:latest docker://registry.fly.io/pomerium-proxy:latest
flyctl deploy -i registry.fly.io/pomerium-proxy:latest
