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
./Debian-fix.sh
```

Review the output, then apply it explicitly:

```sh
./Debian-fix.sh --apply
```

Preflight does not need sudo. Checks that require access to protected files are
reported as deferred. In apply mode the script requests sudo itself, performs
the complete preflight as root, and only then makes changes.

The invoking account is selected by default. Bare `--user` explicitly makes
the same selection, so these commands are equivalent:

```sh
./Debian-fix.sh --apply
./Debian-fix.sh --user --apply
```

To configure a particular non-root account instead, pass its name:

```sh
./Debian-fix.sh --user USER --apply
```

In each case, the script configures the selected user's `.bashrc`, root's
`.bashrc`, and `/etc/skel/.bashrc`, in addition to the system-wide settings.

When running directly from a root login, specify the non-root account:

```sh
./Debian-fix.sh --user USER --apply
```

The script is idempotent: APT only installs missing packages and configuration
is maintained in marked blocks. Changed configuration files are backed up
under `/var/backups/debian-fix/`. It does not perform a general upgrade,
remove packages, or reboot the system. APT may update a dependency if that is
required to install one of the missing packages.
