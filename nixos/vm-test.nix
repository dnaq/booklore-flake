{ pkgs, ... }:
{
  networking.hostName = "booklore-vm";
  users.users.nixos = {
    isNormalUser = true;
    initialPassword = "nixos";
    extraGroups = [ "wheel" ];
  };
  services.booklore.enable = true;
  services.booklore.database.password = "secret";
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 2;
  };
}
