# nixos/modules/booklore.nix
self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.booklore;
in
with lib;
{
  options.services.booklore = {
    enable = mkEnableOption "Booklore service";

    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.booklore;
      description = "Booklore package";
    };

    database = {
      host = mkOption {
        type = types.str;
        default = "localhost";
      };

      passwordFile = mkOption {
        type = types.path;
        description = "Path to a file containing the database password";
      };

      name = mkOption {
        type = types.str;
        default = "booklore";
      };

      user = mkOption {
        type = types.str;
        default = "booklore";
      };
    };
  };

  config = mkIf cfg.enable {

    services.mysql = {
      enable = mkDefault true;
      package = mkDefault pkgs.mariadb;
    };

    systemd.services.booklore-init-db = {
      requires = [
        "mysql.service"
        "network-online.target"
      ];
      after = [ "mysql.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
        DB_PASS=$(cat ${cfg.database.passwordFile})
        ${config.services.mysql.package}/bin/mysql -u root -e "
          CREATE DATABASE IF NOT EXISTS ${cfg.database.name};
          DROP USER IF EXISTS '${cfg.database.user}'@'localhost';
          CREATE USER '${cfg.database.user}'@'localhost' IDENTIFIED BY '$DB_PASS';
          GRANT ALL PRIVILEGES ON ${cfg.database.name}.* TO '${cfg.database.user}'@'localhost';
          FLUSH PRIVILEGES;
        "
      '';
    };

    systemd.services.booklore = {
      description = "Booklore";
      wantedBy = [ "multi-user.target" ];
      requires = [
        "mysql.service"
        "booklore-init-db.service"
        "network-online.target"
      ];
      after = [
        "mysql.service"
        "booklore-init-db.service"
      ];
      serviceConfig = {
        DynamicUser = true;
        User = "booklore";
        Group = "booklore";
        SupplementaryGroups = lib.concatStringsSep "" cfg.extraGroups;
        StateDirectory = "booklore booklore/data booklore/bookdrop booklore/books";
        ExecStart = "${pkgs.bash}/bin/bash -c 'export DATABASE_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/db_password); exec ${cfg.package}/bin/booklore'";
        LoadCredential = "db_password:${cfg.database.passwordFile}";
      };
      environment = {
        DATABASE_URL = "jdbc:mariadb://${cfg.database.host}:${builtins.toString config.services.mysql.settings.mysqld.port}/booklore";
        DATABASE_USERNAME = cfg.database.user;
        APP_PATH_CONFIG="/var/lib/booklore/data";
        APP_BOOKDROP_FOLDER="/var/lib/booklore/bookdrop";
      };
    };
  };
}
