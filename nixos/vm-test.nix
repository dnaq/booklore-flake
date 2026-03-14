{ pkgs, ... }:
{
  networking.hostName = "booklore-vm";
  users.users.nixos = {
    isNormalUser = true;
    initialPassword = "nixos";
    extraGroups = [ "wheel" ];
  };
  services.booklore.enable = true;

  # For demonstration purposes we use a password file in the nix store
  # never do this on production systems, instead either set the path to a file
  # that you manually place on the host or use a secret manager of some kind
  # (e.g. agenix)
  services.booklore.database.passwordFile = pkgs.writeText "passwordFile" "secret";
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 2;
  };
  system.stateVersion = "26.06";
}
