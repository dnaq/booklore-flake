# nixos/modules/booklore.nix
self:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.booklore;
in
{
  options.services.booklore = {
    enable = mkEnableOption "Booklore service";

    user = lib.mkOption {
      type = lib.types.str;
      default = "booklore";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "booklore";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.system}.booklore;
      description = "Booklore package";
    };

    database = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
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
    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      home = "/var/lib/booklore";
      createHome = true;
    };
    users.groups.${cfg.group} = { };

    services.mysql = {
      enable = mkDefault true;
      package = mkDefault pkgs.mariadb;
    };

    systemd.services.booklore-init-db = {
      wants = [ "mysql.service" ];
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

    systemd.tmpfiles.rules = [
      "d /var/lib/booklore/data 0755 booklore booklore -"
      "d /var/lib/booklore/books 0755 booklore booklore -"
      "d /var/lib/booklore/bookdrop 0755 booklore booklore -"
    ];

    systemd.services.booklore = {
      description = "Booklore";
      wantedBy = [ "multi-user.target" ];
      wants = [
        "mysql.service"
        "network-online.target"
      ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.bash}/bin/bash -c 'export DATABASE_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/db_password); exec ${cfg.package}/bin/booklore'";
        LoadCredential = "db_password:${cfg.database.passwordFile}";
        BindPaths = [
          "/var/lib/booklore/data:/app/data"
          "/var/lib/booklore/books:/books"
          "/var/lib/booklore/bookdrop:/bookdrop"
        ];
        BindReadOnlyPaths = [
          "/nix/store:/nix/store"
        ];
      };
      environment = {
        DATABASE_URL = "jdbc:mariadb://127.0.0.1:3306/booklore";
        DATABASE_USERNAME = cfg.database.user;
      };
    };
  };
}
