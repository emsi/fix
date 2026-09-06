# fix

Small system-configuration scripts.

## Debian

`Debian-fix.sh` installs a practical Debian development and administration
baseline, configures Bash history and Neovim, and preserves the invoking
user's `HOME` under sudo. The sudo behavior is scoped to that user instead of
being enabled globally. The script is standalone and does not require any
companion configuration files.

Preserving `HOME` is deliberate: privileged commands may consequently use
configuration from the selected user's home directory. Use `sudo -H` for a
command that must use root's home directory instead.

The command determines both the scope and whether changes are applied:

| Command | Sudo | Result |
| --- | --- | --- |
| `bash ./Debian-fix.sh` | requested automatically | Full-system dry run |
| `bash ./Debian-fix.sh --user` | never requested | Current-user dry run |
| `bash ./Debian-fix.sh --apply` | requested automatically | Full-system apply |
| `bash ./Debian-fix.sh --user --apply` | never requested | Current-user apply |

Full-system mode covers package installation, the selected user's `.bashrc`,
root's `.bashrc`, `/etc/skel/.bashrc`, system-wide Neovim configuration, and
the selected user's sudoers rule. Its dry run executes with sudo so it can
inspect every protected target accurately before reporting what would change.

User-only mode never requests sudo. It reports package status for context but
does not install packages or inspect or modify system-owned configuration. Its
only configuration target is the selected user's `.bashrc`; protected checks
are shown as deferred in the dry run.

Bare `--user` selects the invoking account. An optional argument selects a
particular account while retaining user-only scope:

```sh
bash ./Debian-fix.sh --user USER
bash ./Debian-fix.sh --user USER --apply
```

A non-root process cannot apply user-only changes for another account. From a
direct root login, use `--target-user USER` to select the non-root account for
full-system mode:

```sh
bash ./Debian-fix.sh --target-user USER
bash ./Debian-fix.sh --target-user USER --apply
```

The script is idempotent: APT only installs missing packages and configuration
is maintained in marked blocks. Full-system backups are stored under
`/var/backups/debian-fix/`; user-only backups are stored under
`~/.local/state/debian-fix/backups/`. It does not perform a general upgrade,
remove packages, or reboot the system. APT may update a dependency if that is
required to install one of the missing packages.
