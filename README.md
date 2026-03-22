# Grimmory Flake

This is a flake defining packages and a nixos module for running [Grimmory](https://github.com/grimmory-tools/grimmory)
on [NixOS](https://nixos.org).

## Getting Started

```
  imports = [
    inputs.grimmory-flake.nixosModules.grimmory
  ];
  services.grimmory = {
    enable = true;
    database.passwordFile = path-to-your-passwordfile;
  };
```

The password file should contain the database password for your grimmory instance. This should be a
long and secure password that should only be used for communicating between the grimmory instance
and the database. Main reason for this password is that grimmory does not (afaik) support using the
mysql/mariadb socket.

## Notes

Grimmory will listen to all network interfaces by default. Make sure to set up firewall rules
to hinder access if you don't want it to be publicly exposed.

## Cache

This flake is built by [garnix](https://garnix.io/), and a binary cache can be accessed at
https://cache.garnix.io with the key `cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=`.

See the [garnix documentation](https://garnix.io/docs/ci/caching) for more information.

## References

This flake is in large part based on the work done by carterjandrew on [booklore-nix](https://github.com/carterjandrew/booklore-nix).

The main differences are:

1. The source code of [grimmory](https://github.com/grimmory-app/grimmory) (the develop branch) is used as a flake input instead of being pinned.
   This means that this flake (as long as it builds) should use the latest released version of grimmory.
2. No nginx instance is used for mediating access between the API and the UI. Instead this flake does
   what the official docker image does and bakes the static assets from the UI into the api server.
  
