#!/usr/bin/env bash

# Shared safety primitives for Hercules Helper. Keep this file compatible with
# Bash 3.2 because several supported operating systems still ship it.

hh_die()
{
    printf 'ERROR: %s\n' "$*" >&2
    return 1
}

hh_script_dir()
{
    local source_path="${1:-${BASH_SOURCE[1]}}"
    local source_dir
    while [ -L "$source_path" ]; do
        source_dir="$(cd -P "$(dirname "$source_path")" >/dev/null 2>&1 && pwd)" || return 1
        source_path="$(readlink "$source_path")" || return 1
        case "$source_path" in
            /*) ;;
            *) source_path="$source_dir/$source_path" ;;
        esac
    done
    cd -P "$(dirname "$source_path")" >/dev/null 2>&1 && pwd
}

hh_print_command()
{
    local arg
    printf '$'
    for arg in "$@"; do
        printf ' %q' "$arg"
    done
    printf '\n'
}

hh_run()
{
    hh_print_command "$@"
    "$@"
}

hh_words_from_string()
{
    local value="$1"
    case "$value" in
        *';'*|*'&'*|*'|'*|*'<'*|*'>'*|*'`'*|*'$('*|*$'\n'*)
            hh_die "Shell syntax is not allowed in option values: $value" || return 1
            ;;
    esac
    HH_WORDS=()
    [ -n "$value" ] || return 0
    read -r -a HH_WORDS <<< "$value"
}

hh_require_command()
{
    command -v "$1" >/dev/null 2>&1 || hh_die "Required command not found: $1"
}

hh_sha256()
{
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$1" | awk '{print $NF}'
    else
        hh_die "No SHA-256 implementation found"
    fi
}

hh_download_verified()
{
    local url="$1"
    local output="$2"
    local expected_sha256="$3"
    local output_dir tmp actual

    [ -n "$expected_sha256" ] || hh_die "A SHA-256 value is required for $url" || return 1
    case "$expected_sha256" in
        *[!0-9a-fA-F]*|'') hh_die "Invalid SHA-256 value for $url" || return 1 ;;
    esac
    [ "${#expected_sha256}" -eq 64 ] || hh_die "Invalid SHA-256 length for $url" || return 1

    output_dir="$(dirname "$output")"
    mkdir -p "$output_dir" || return 1
    tmp="$(mktemp "$output_dir/.hh-download.XXXXXX")" || return 1

    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error --output "$tmp" "$url" || {
            rm -f "$tmp"
            return 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget --https-only --output-document="$tmp" "$url" || {
            rm -f "$tmp"
            return 1
        }
    else
        rm -f "$tmp"
        hh_die "Neither curl nor wget is available" || return 1
    fi

    actual="$(hh_sha256 "$tmp")" || {
        rm -f "$tmp"
        return 1
    }
    if [ "$(printf '%s' "$actual" | tr '[:upper:]' '[:lower:]')" != "$(printf '%s' "$expected_sha256" | tr '[:upper:]' '[:lower:]')" ]; then
        rm -f "$tmp"
        hh_die "SHA-256 mismatch for $url (expected $expected_sha256, got $actual)" || return 1
    fi
    chmod 0644 "$tmp"
    mv -f "$tmp" "$output"
}

hh_archive_is_safe()
{
    local archive="$1" listing member
    listing="$(tar -tf "$archive")" || return 1
    while IFS= read -r member; do
        case "$member" in
            /*|../*|*/../*|*/..|'..')
                hh_die "Unsafe archive member: $member" || return 1
                ;;
        esac
    done <<< "$listing"

    # Reject links. They are unnecessary for the source archives used here and
    # make containment dependent on tar implementation details.
    if tar -tvf "$archive" | awk 'substr($1,1,1) == "l" || substr($1,1,1) == "h" { found=1 } END { exit found ? 0 : 1 }'; then
        hh_die "Archive contains symbolic or hard links: $archive" || return 1
    fi
}

hh_extract_tar_gz()
{
    local archive="$1" destination="$2"
    hh_archive_is_safe "$archive" || return 1
    mkdir -p "$destination" || return 1
    tar -xf "$archive" -C "$destination"
}

hh_real_directory()
{
    [ -d "$1" ] || return 1
    (cd -P "$1" >/dev/null 2>&1 && pwd)
}

hh_safe_rm_rf()
{
    local base="$1" target="$2" base_real parent_real leaf resolved
    [ -n "$target" ] || hh_die "Refusing an empty recursive-delete target" || return 1
    case "$target" in /|.|..|~|-*) hh_die "Refusing unsafe recursive-delete target: $target" || return 1 ;; esac
    base_real="$(hh_real_directory "$base")" || hh_die "Invalid cleanup base: $base" || return 1
    case "$target" in /*) resolved="$target" ;; *) resolved="$base_real/$target" ;; esac
    leaf="$(basename "$resolved")"
    parent_real="$(hh_real_directory "$(dirname "$resolved")")" || hh_die "Cleanup parent does not exist: $resolved" || return 1
    resolved="$parent_real/$leaf"
    case "$resolved" in "$base_real"/*) ;; *) hh_die "Cleanup target escapes workspace: $resolved" || return 1 ;; esac
    [ "$resolved" != "$base_real" ] || hh_die "Refusing to remove the workspace root" || return 1
    rm -rf -- "$resolved"
}

hh_git_clone_pinned()
{
    local repository="$1" branch="$2" commit="$3" destination="$4" resolved
    hh_validate_git_commit "$commit" || return 1
    git clone --branch "$branch" --no-single-branch "$repository" "$destination" || return 1
    git -C "$destination" checkout --detach "$commit" || return 1
    resolved="$(git -C "$destination" rev-parse HEAD)" || return 1
    [ "$resolved" = "$commit" ] || hh_die "Resolved commit $resolved does not match required $commit" || return 1
}

hh_validate_git_commit()
{
    local commit="$1"
    [ "${#commit}" -eq 40 ] || hh_die "A full 40-character Git commit is required: $commit" || return 1
    case "$commit" in *[!0-9a-f]*) hh_die "Git commits must use lowercase hexadecimal: $commit" || return 1 ;; esac
}
