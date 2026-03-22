# nixos/modules/grimmory.nix
self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.grimmory;
in
with lib;
{
  options.services.grimmory = {
    enable = mkEnableOption "grimmory service";

    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.grimmory;
      description = "grimmory package";
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
        default = "grimmory";
      };

      user = mkOption {
        type = types.str;
        default = "grimmory";
      };
    };
  };

  config = mkIf cfg.enable {

    services.mysql = {
      enable = mkDefault true;
      package = mkDefault pkgs.mariadb;
    };

    systemd.services.grimmory-init-db = {
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

    systemd.services.grimmory = {
      description = "grimmory";
      wantedBy = [ "multi-user.target" ];
      requires = [
        "mysql.service"
        "grimmory-init-db.service"
        "network-online.target"
      ];
      after = [
        "mysql.service"
        "grimmory-init-db.service"
      ];
      serviceConfig = {
        DynamicUser = true;
        User = "grimmory";
        Group = "grimmory";
        SupplementaryGroups = lib.concatStringsSep "" cfg.extraGroups;
        StateDirectory = "grimmory grimmory/data grimmory/bookdrop grimmory/books";
        ExecStart = "${pkgs.bash}/bin/bash -c 'export DATABASE_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/db_password); exec ${cfg.package}/bin/grimmory'";
        LoadCredential = "db_password:${cfg.database.passwordFile}";
      };
      environment = {
        DATABASE_URL = "jdbc:mariadb://${cfg.database.host}:${builtins.toString config.services.mysql.settings.mysqld.port}/grimmory";
        DATABASE_USERNAME = cfg.database.user;
        APP_PATH_CONFIG="/var/lib/grimmory/data";
        APP_BOOKDROP_FOLDER="/var/lib/grimmory/bookdrop";
      };
    };
  };
}
