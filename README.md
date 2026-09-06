# fix

Small system-configuration scripts.

## Debian

`Debian-fix.sh` installs a practical Debian development and administration
baseline and configures Bash history and Neovim. The script is standalone and
does not require any companion configuration files.

The command determines both the scope and whether changes are applied:

| Command | Sudo | Result |
| --- | --- | --- |
| `bash ./Debian-fix.sh` | requested automatically | Full-system dry run |
| `bash ./Debian-fix.sh --user` | never requested | Current-user dry run |
| `bash ./Debian-fix.sh --apply` | requested automatically | Full-system apply |
| `bash ./Debian-fix.sh --user --apply` | never requested | Current-user apply |

Full-system mode covers package installation, the selected user's `.bashrc`,
root's `.bashrc`, `/etc/skel/.bashrc`, and system-wide Neovim configuration.
Its dry run executes with sudo so it can inspect every protected target
accurately before reporting what would change.
The Neovim settings are kept directly in a managed block in
`/etc/xdg/nvim/sysinit.vim`.

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
