{ pkgs, ... }: {
  services.wyoming = {
    piper.servers.local = {
      enable = true;
      uri = "tcp://127.0.0.1:10200";
      voice = "en-us-ryan-medium";
    };
    faster-whisper.package = pkgs.wyoming-faster-whisper.overrideAttrs (old: {
      postPatch = ''
        substituteInPlace setup.py --replace 'whipser' 'whisper'
      '';
    });
    faster-whisper.servers.local = {
      enable = true;
      uri = "tcp://127.0.0.1:10300";
      model = "base";
      language = "en";
      beamSize = 2;
    };
    openwakeword = {
      enable = true;
      uri = "tcp://127.0.0.1:10400";
      preloadModels = [
        "ok_nabu"
        "alexa"
      ];
    };
  };

  networking.firewall.enable = false; # disable firewall for ESP voice

}
