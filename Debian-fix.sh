#!/usr/bin/env bash

set -Eeuo pipefail

readonly PROGRAM=${0##*/}
readonly BASH_BEGIN='# BEGIN Debian-fix managed settings'
readonly BASH_END='# END Debian-fix managed settings'
readonly NVIM_BEGIN='" BEGIN Debian-fix managed settings'
readonly NVIM_END='" END Debian-fix managed settings'

readonly -a PACKAGES=(
    bash-completion
    build-essential
    byobu
    ca-certificates
    curl
    fd-find
    file
    git
    jq
    less
    locales
    man-db
    neovim
    pkg-config
    python3-pynvim
    ripgrep
    rsync
    shellcheck
    sudo
    tmux
    unzip
    wget
    xxd
    zip
)

APPLY=0
USER_ONLY=0
SYSTEM_TARGET_SET=0
TARGET_USER=''
WORK_DIR=''
BACKUP_DIR=''
declare -a MISSING_PACKAGES=()

if ((EUID == 0)) && [[ -n ${SUDO_USER:-} && ${SUDO_USER:-} != root ]]; then
    readonly INVOKING_USER=$SUDO_USER
else
    INVOKING_USER=$(id -un) || exit 1
    readonly INVOKING_USER
fi

usage() {
    cat <<EOF
Usage: bash ./$PROGRAM [--user [USER] | --target-user USER] [--apply]

With no options, request sudo and perform a full-system read-only preflight.
With --apply, apply the selected scope after its preflight checks pass.

Options:
  --user [USER]       Limit work to the invoking user, or USER when supplied;
                      never request sudo
  --target-user USER  Select USER for full-system work (normally unnecessary)
  --apply             Apply changes after all preflight checks pass
  -h, --help          Show this help
EOF
}

log() {
    printf '%s\n' "$*"
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

can_inspect_file() {
    local file=$1
    local parent

    if [[ -e $file || -L $file ]]; then
        [[ -L $file || -r $file ]]
    else
        parent=$(dirname -- "$file")
        [[ -x $parent ]]
    fi
}

cleanup() {
    if [[ -n $WORK_DIR && -d $WORK_DIR ]]; then
        rm -rf -- "$WORK_DIR"
    fi
}

trap cleanup EXIT

while (($#)); do
    case $1 in
        --apply)
            APPLY=1
            ;;
        --user)
            ((SYSTEM_TARGET_SET == 0)) ||
                die '--user and --target-user cannot be used together'
            USER_ONLY=1
            if (($# > 1)) && [[ $2 != -* ]]; then
                TARGET_USER=$2
                shift
            else
                TARGET_USER=$INVOKING_USER
            fi
            ;;
        --target-user)
            ((USER_ONLY == 0)) ||
                die '--user and --target-user cannot be used together'
            shift
            if (($# == 0)) || [[ $1 == -* ]]; then
                die '--target-user requires a user name'
            fi
            TARGET_USER=$1
            SYSTEM_TARGET_SET=1
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
    shift
done

if [[ -z $TARGET_USER ]]; then
    TARGET_USER=$INVOKING_USER
fi
[[ -n $TARGET_USER && $TARGET_USER != root ]] ||
    die 'cannot determine the non-root target user; pass --target-user USER'
[[ $TARGET_USER =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] ||
    die "invalid user name: $TARGET_USER"

[[ -r /etc/os-release ]] || die '/etc/os-release is missing'
# shellcheck source=/dev/null
. /etc/os-release
[[ ${ID:-} == debian ]] || die "this script supports Debian only (found: ${ID:-unknown})"

for command in apt-cache apt-get awk cmp dpkg-query flock getent install locale mktemp stat; do
    command -v "$command" >/dev/null 2>&1 || die "required command is missing: $command"
done

passwd_entry=$(getent passwd "$TARGET_USER") || die "user does not exist: $TARGET_USER"
IFS=: read -r _ _ TARGET_UID TARGET_GID _ TARGET_HOME TARGET_SHELL <<<"$passwd_entry"
[[ $TARGET_UID =~ ^[0-9]+$ && $TARGET_UID -ne 0 ]] || die "$TARGET_USER is not a regular non-root user"
[[ $TARGET_GID =~ ^[0-9]+$ ]] || die "invalid primary group for $TARGET_USER"
[[ $TARGET_HOME == /* && -d $TARGET_HOME ]] || die "invalid home directory: $TARGET_HOME"
[[ $TARGET_SHELL == */bash ]] || die "$TARGET_USER does not use Bash: $TARGET_SHELL"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
readonly SCRIPT_DIR
readonly SCRIPT_PATH=$SCRIPT_DIR/${BASH_SOURCE[0]##*/}

if ((EUID != 0 && !USER_ONLY)); then
    command -v sudo >/dev/null 2>&1 ||
        die 'sudo is required for full-system mode; use --user for user-only mode'
    if ((APPLY)); then
        log "Requesting sudo for full-system apply for $TARGET_USER..."
        exec sudo -- /bin/bash "$SCRIPT_PATH" --target-user "$TARGET_USER" --apply
    else
        log "Requesting sudo for full-system preflight for $TARGET_USER..."
        exec sudo -- /bin/bash "$SCRIPT_PATH" --target-user "$TARGET_USER"
    fi
fi

available_locales=$(locale -a)
awk 'BEGIN { found=0 }
     { value=tolower($0); gsub(/[._-]/, "", value); if (value == "cutf8") found=1 }
     END { exit !found }' <<<"$available_locales" ||
    die 'C.UTF-8 is not available on this system'

WORK_DIR=$(mktemp -d)
chmod 0700 "$WORK_DIR"
readonly NVIM_SETTINGS=$WORK_DIR/nvim-settings.vim

cat >"$NVIM_SETTINGS" <<'EOF'
" System-wide Neovim preferences installed by Debian-fix.sh.

" Enable mouse support in every mode.
set mouse=a

" Complete the longest common match, list alternatives, then cycle matches.
set wildmode=longest,list,full

" Use four-column indentation when editing C source and header files.
augroup vimrcEx
  au!
  autocmd FileType text setlocal textwidth=78
  autocmd FileType c setlocal shiftwidth=4 softtabstop=4
augroup END
EOF

cat >"$WORK_DIR/bash.block" <<'EOF'
# BEGIN Debian-fix managed settings
if [[ $- == *i* ]]; then
    export EDITOR=nvim
    export VISUAL=nvim
    export LC_COLLATE=C.UTF-8

    if ! declare -F _completion_loader >/dev/null &&
        [[ -r /usr/share/bash-completion/bash_completion ]]; then
        # shellcheck source=/usr/share/bash-completion/bash_completion
        . /usr/share/bash-completion/bash_completion
    fi

    # Keep a large, shared history and remove duplicate entries.
    HISTCONTROL=ignoredups:erasedups
    HISTSIZE=100000
    HISTFILESIZE=100000
    shopt -s histappend

    __debian_fix_history_sync() {
        builtin history -a
        builtin history -c
        builtin history -r
    }

    if [[ $(declare -p PROMPT_COMMAND 2>/dev/null || :) == 'declare -a'* ]]; then
        __debian_fix_prompt_found=0
        for __debian_fix_prompt_item in "${PROMPT_COMMAND[@]}"; do
            if [[ $__debian_fix_prompt_item == __debian_fix_history_sync ]]; then
                __debian_fix_prompt_found=1
                break
            fi
        done
        if ((!__debian_fix_prompt_found)); then
            PROMPT_COMMAND+=(__debian_fix_history_sync)
        fi
        unset __debian_fix_prompt_found __debian_fix_prompt_item
    elif [[ ${PROMPT_COMMAND-} != *'__debian_fix_history_sync'* ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND};}__debian_fix_history_sync"
    fi
fi
# END Debian-fix managed settings
EOF

{
    printf '%s\n' "$NVIM_BEGIN"
    cat "$NVIM_SETTINGS"
    printf '%s\n' "$NVIM_END"
} >"$WORK_DIR/nvim.block"

render_managed_file() {
    local source_file=$1
    local block_file=$2
    local begin_marker=$3
    local end_marker=$4
    local output_file=$5
    local input_file=$source_file

    if [[ -e $source_file || -L $source_file ]]; then
        [[ -f $source_file && ! -L $source_file ]] ||
            die "refusing to replace a non-regular file or symlink: $source_file"
        [[ -r $source_file ]] || die "cannot read: $source_file"
    else
        input_file=/dev/null
    fi

    awk -v block_file="$block_file" -v begin="$begin_marker" -v end="$end_marker" '
        BEGIN {
            while ((getline line < block_file) > 0) block[++block_count] = line
            close(block_file)
        }
        $0 == begin {
            if (seen || in_block) exit 40
            seen=1
            in_block=1
            for (i=1; i<=block_count; i++) print block[i]
            next
        }
        $0 == end {
            if (!in_block) exit 41
            in_block=0
            next
        }
        !in_block {
            print
            last=$0
        }
        END {
            if (in_block) exit 42
            if (!seen) {
                if (NR > 0 && last != "") print ""
                for (i=1; i<=block_count; i++) print block[i]
            }
        }
    ' "$input_file" >"$output_file" ||
        die "malformed or duplicate managed block in $source_file"
}

ensure_backup_dir() {
    if [[ -z $BACKUP_DIR ]]; then
        if ((EUID == 0)); then
            install -d -m 0700 /var/backups/debian-fix
            BACKUP_DIR=$(mktemp -d /var/backups/debian-fix/run-XXXXXXXX)
        else
            local backup_root=$TARGET_HOME/.local/state/debian-fix/backups
            install -d -m 0700 "$backup_root"
            BACKUP_DIR=$(mktemp -d "$backup_root/run-XXXXXXXX")
        fi
        chmod 0700 "$BACKUP_DIR"
    fi
}

backup_file() {
    local file=$1
    [[ -e $file || -L $file ]] || return 0
    ensure_backup_dir
    local backup_name=${file#/}
    backup_name=${backup_name//\//_}
    cp -a -- "$file" "$BACKUP_DIR/$backup_name"
}

install_file_atomically() {
    local source_file=$1
    local target_file=$2
    local default_mode=$3
    local default_uid=$4
    local default_gid=$5
    local mode=$default_mode
    local uid=$default_uid
    local gid=$default_gid
    local temporary_target
    local target_dir

    if [[ -e $target_file || -L $target_file ]]; then
        [[ -f $target_file && ! -L $target_file ]] ||
            die "refusing to replace a non-regular file or symlink: $target_file"
        if cmp -s -- "$source_file" "$target_file"; then
            log "unchanged: $target_file"
            return 0
        fi
        mode=$(stat -c '%a' "$target_file")
        uid=$(stat -c '%u' "$target_file")
        gid=$(stat -c '%g' "$target_file")
    fi

    if ((!APPLY)); then
        log "would update: $target_file"
        return 0
    fi

    backup_file "$target_file"
    target_dir=$(dirname -- "$target_file")
    if [[ ! -d $target_dir ]]; then
        install -d -m 0755 "$target_dir"
    fi
    temporary_target=$(mktemp "${target_file}.debian-fix.XXXXXXXX")
    if ! install -m "$mode" -o "$uid" -g "$gid" -- "$source_file" "$temporary_target"; then
        rm -f -- "$temporary_target"
        die "could not prepare replacement for $target_file"
    fi
    if ! mv -f -- "$temporary_target" "$target_file"; then
        rm -f -- "$temporary_target"
        die "could not replace $target_file"
    fi
    log "updated: $target_file"
}

prepare_bashrc() {
    local target=$1
    local label=$2
    local output=$WORK_DIR/$label.bashrc

    render_managed_file "$target" "$WORK_DIR/bash.block" "$BASH_BEGIN" "$BASH_END" "$output"
    bash -n "$output" || die "generated Bash configuration is invalid: $target"
    printf '%s\n' "$output"
}

readonly SKEL_BASHRC=/etc/skel/.bashrc
readonly USER_BASHRC=$TARGET_HOME/.bashrc
readonly ROOT_BASHRC=/root/.bashrc
readonly NVIM_SYSINIT=/etc/xdg/nvim/sysinit.vim

skel_rendered=''
user_rendered=''
root_rendered=''
sysinit_rendered=''

if ((EUID == 0 && !USER_ONLY)); then
    skel_rendered=$(prepare_bashrc "$SKEL_BASHRC" skel)
fi
if ((EUID == 0)) || can_inspect_file "$USER_BASHRC"; then
    user_rendered=$(prepare_bashrc "$USER_BASHRC" user)
fi
if ((EUID == 0 && !USER_ONLY)); then
    root_rendered=$(prepare_bashrc "$ROOT_BASHRC" root)
fi
if ((EUID == 0 && !USER_ONLY)); then
    sysinit_rendered=$WORK_DIR/sysinit.vim
    render_managed_file "$NVIM_SYSINIT" "$WORK_DIR/nvim.block" "$NVIM_BEGIN" "$NVIM_END" \
        "$sysinit_rendered"
fi

log "Debian ${VERSION_ID:-unknown}; target user: $TARGET_USER ($TARGET_HOME)"
log 'Baseline packages:'
for package in "${PACKAGES[@]}"; do
    if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | awk '$0 == "ii " { found=1 } END { exit !found }'; then
        printf '  installed  %s\n' "$package"
    else
        MISSING_PACKAGES+=("$package")
        candidate=$(apt-cache policy "$package" |
            awk '/Candidate:/ && !found { print $2; found=1 }')
        if [[ -n $candidate && $candidate != '(none)' ]]; then
            printf '  missing    %s (%s)\n' "$package" "$candidate"
        else
            printf '  missing    %s (candidate unknown until apt-get update)\n' "$package"
        fi
    fi
done

if ((!APPLY)); then
    if command -v nvim >/dev/null 2>&1; then
        nvim --headless -u "$NVIM_SETTINGS" '+qa!' >/dev/null 2>&1 ||
            die 'Neovim rejected the managed system settings'
        if [[ -n $sysinit_rendered ]]; then
            nvim --headless -u "$sysinit_rendered" '+qa!' >/dev/null 2>&1 ||
                die 'Neovim rejected the prospective system configuration'
        else
            log "deferred (requires root): Neovim validation of $NVIM_SYSINIT"
        fi
    else
        log 'Neovim validation deferred until the neovim package is installed.'
    fi
    if [[ -n $skel_rendered ]]; then
        install_file_atomically "$skel_rendered" "$SKEL_BASHRC" 0644 0 0
    else
        log "deferred (requires root): $SKEL_BASHRC"
    fi
    if [[ -n $user_rendered ]]; then
        install_file_atomically "$user_rendered" "$USER_BASHRC" 0644 "$TARGET_UID" "$TARGET_GID"
    else
        log "deferred (requires root): $USER_BASHRC"
    fi
    if [[ -n $root_rendered ]]; then
        install_file_atomically "$root_rendered" "$ROOT_BASHRC" 0644 0 0
    else
        log "deferred (requires root): $ROOT_BASHRC"
    fi
    if [[ -n $sysinit_rendered ]]; then
        install_file_atomically "$sysinit_rendered" "$NVIM_SYSINIT" 0644 0 0
    else
        log "deferred (requires root): $NVIM_SYSINIT"
    fi
    log
    if ((USER_ONLY)); then
        log 'User-only preflight passed; no persistent changes were made.'
        if [[ $TARGET_USER == "$INVOKING_USER" ]]; then
            log "Apply only $USER_BASHRC with: bash ./$PROGRAM --user --apply"
        else
            log "Apply only $USER_BASHRC with: bash ./$PROGRAM --user $TARGET_USER --apply"
        fi
        log "Run the full-system preflight with: bash ./$PROGRAM"
    else
        log 'Full-system preflight passed; no persistent changes were made.'
        if [[ $TARGET_USER == "$INVOKING_USER" ]]; then
            log "Apply all changes with: bash ./$PROGRAM --apply"
        else
            log "Apply all changes with: bash ./$PROGRAM --target-user $TARGET_USER --apply"
        fi
    fi
    exit 0
fi

if ((USER_ONLY)); then
    [[ -n $user_rendered ]] || die "cannot inspect user configuration: $USER_BASHRC"
    if ((EUID != 0 && TARGET_UID != EUID)); then
        die "user-only apply cannot modify another user's configuration: $TARGET_USER"
    fi
    install_file_atomically "$user_rendered" "$USER_BASHRC" 0644 "$TARGET_UID" "$TARGET_GID"

    log
    log "User-only configuration completed successfully for $TARGET_USER."
    if [[ -n $BACKUP_DIR ]]; then
        log "Backup of the changed file: $BACKUP_DIR"
    fi
    log 'Packages and system-wide configuration were not changed.'
    log 'Open a new login shell to load the updated environment.'
    exit 0
fi

((EUID == 0)) || die 'internal error: apply mode requires root'
[[ -n $skel_rendered && -n $user_rendered && -n $root_rendered &&
    -n $sysinit_rendered ]] ||
    die 'internal error: privileged configuration preflight was incomplete'

exec 9>/run/lock/debian-fix.lock
flock -n 9 || die 'another Debian-fix run is active'

export DEBIAN_FRONTEND=noninteractive
if ((${#MISSING_PACKAGES[@]})); then
    log 'Refreshing APT metadata...'
    apt-get update
    log 'Installing missing baseline packages...'
    apt-get install --yes --no-install-recommends --no-upgrade "${MISSING_PACKAGES[@]}"
else
    log 'All baseline packages are already installed; skipping APT.'
fi

for package in "${PACKAGES[@]}"; do
    dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null |
        awk '$0 == "ii " { found=1 } END { exit !found }' ||
        die "package is not installed after APT completed: $package"
done

command -v nvim >/dev/null 2>&1 || die 'nvim is unavailable after installing neovim'
nvim --headless -u "$NVIM_SETTINGS" '+qa!' >/dev/null 2>&1 ||
    die 'Neovim rejected the managed system settings'
nvim --headless -u "$sysinit_rendered" '+qa!' >/dev/null 2>&1 ||
    die 'Neovim rejected the prospective system configuration'

# Configuration was only planned above. Apply it now that packages and their
# validation tools are installed.
install_file_atomically "$skel_rendered" "$SKEL_BASHRC" 0644 0 0
install_file_atomically "$user_rendered" "$USER_BASHRC" 0644 "$TARGET_UID" "$TARGET_GID"
install_file_atomically "$root_rendered" "$ROOT_BASHRC" 0644 0 0
install_file_atomically "$sysinit_rendered" "$NVIM_SYSINIT" 0644 0 0

XDG_CONFIG_HOME="$WORK_DIR/xdg-home" XDG_CONFIG_DIRS=/etc/xdg \
    nvim --headless '+qa!' >/dev/null 2>&1 || die 'installed Neovim configuration failed validation'

log
log 'Debian baseline configuration completed successfully.'
if [[ -n $BACKUP_DIR ]]; then
    log "Backups of changed files: $BACKUP_DIR"
fi
log 'Open a new login shell to load the updated environment.'
