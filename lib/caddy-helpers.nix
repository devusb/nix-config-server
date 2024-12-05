{ wildcardDomain, ... }:
{
  mkVirtualHost = port: {
    useACMEHost = wildcardDomain;
    extraConfig = ''
      reverse_proxy :${toString port}
    '';
  };
  mkHttpsVirtualHost = port: {
    useACMEHost = wildcardDomain;
    extraConfig = ''
      reverse_proxy localhost:${toString port} {
          transport http {
                  tls
                  tls_insecure_skip_verify
          }
      }
    '';
  };
  mkSocketVirtualHost = path: {
    useACMEHost = wildcardDomain;
    extraConfig = ''
      reverse_proxy unix/${path}
    '';
  };

}
