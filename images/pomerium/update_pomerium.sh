nix build .#images.pomerium
docker load < result
rm result
docker tag pomerium-proxy:latest registry.fly.io/pomerium-proxy:latest
docker push registry.fly.io/pomerium-proxy:latest
flyctl deploy -i registry.fly.io/pomerium-proxy:latest
