{
  writeShellApplication,
  inputs,
}:
writeShellApplication {
  name = "update";

  text = ''
    nix build .#booklore.mitmCache.updateScript
    ./result
  '';
}
