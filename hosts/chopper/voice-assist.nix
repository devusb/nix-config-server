{ ... }: {
  systemd.tmpfiles.settings."whisper"."/var/lib/voice-assist/whisper".d = {
    mode = "0666";
  };
  systemd.tmpfiles.settings."piper"."/var/lib/voice-assist/piper".d = {
    mode = "0666";
  };
  systemd.tmpfiles.settings."openwakeword"."/var/lib/voice-assist/openwakeword".d = {
    mode = "0666";
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      whisper = {
        volumes = [ "/var/lib/voice-assist/whisper:/data" ];
        image = "rhasspy/wyoming-whisper";
        cmd = [
          "--model"
          "base"
          "--language"
          "en"
        ];
        extraOptions = [
          "--network=host"
        ];
      };
      piper = {
        volumes = [ "/var/lib/voice-assist/piper:/data" ];
        image = "rhasspy/wyoming-piper";
        cmd = [
          "--voice"
          "en_US-lessac-medium"
        ];
        extraOptions = [
          "--network=host"
        ];
      };
      openwakeword = {
        volumes = [ "/var/lib/voice-assist/openwakeword:/custom" ];
        image = "rhasspy/wyoming-openwakeword";
        cmd = [
          "--preload-model"
          "ok_nabu"
          "--custom-model-dir"
          "/custom"
        ];
        extraOptions = [
          "--network=host"
        ];
      };
    };
  };

  networking.firewall.enable = false; # disable firewall for ESP voice

}
