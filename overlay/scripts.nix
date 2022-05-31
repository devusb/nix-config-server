{ pkgs, ... }:{

  helloWorld = pkgs.writeShellScriptBin "helloWorld" ''
    echo Hello World
  '';

}