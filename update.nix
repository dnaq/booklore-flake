{
  writeShellApplication,
  inputs,
}:
writeShellApplication {
  name = "update";

  text = ''
    nix build .#grimmory.mitmCache.updateScript
    ./result
  '';
}
