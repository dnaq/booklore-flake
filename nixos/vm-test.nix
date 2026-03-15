{ pkgs, ... }:
{
  networking.hostName = "booklore-vm";
  users.users.nixos = {
    isNormalUser = true;
    initialPassword = "nixos";
    extraGroups = [ "wheel" ];
  };
  services.booklore.enable = true;
  services.booklore.database.passwordFile = pkgs.writeText "passwordFile" "secret";
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 2;
  };
}
