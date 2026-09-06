# fix

Small system-configuration scripts.

## Debian

`Debian-fix.sh` installs a practical Debian development and administration
baseline, configures Bash history and Neovim, and preserves the invoking
user's `HOME` under sudo. The sudo behavior is scoped to that user instead of
being enabled globally.

Preserving `HOME` is deliberate: privileged commands may consequently use
configuration from the selected user's home directory. Use `sudo -H` for a
command that must use root's home directory instead.

Run the read-only preflight first:

```sh
sudo ./Debian-fix.sh
```

Review the output, then apply it explicitly:

```sh
sudo ./Debian-fix.sh --apply
```

When running directly from a root login, specify the non-root account:

```sh
./Debian-fix.sh --user USER --apply
```

The script is idempotent: APT only installs missing packages and configuration
is maintained in marked blocks. Changed configuration files are backed up
under `/var/backups/debian-fix/`. It does not perform a general upgrade,
remove packages, or reboot the system. APT may update a dependency if that is
required to install one of the missing packages.
