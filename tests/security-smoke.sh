#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_dir/lib/hercules-helper/common.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/work/inside" "$tmp/outside"
touch "$tmp/work/inside/file" "$tmp/outside/keep"

hh_safe_rm_rf "$tmp/work" inside
[ ! -e "$tmp/work/inside" ]

hh_validate_git_commit 5744d9b216a3dc38f6c4f96849b1eb94abe7a6c6
if hh_validate_git_commit 5744d9b 2>/dev/null; then
    echo "abbreviated Git commit was not rejected" >&2
    exit 1
fi

if hh_safe_rm_rf "$tmp/work" ../outside 2>/dev/null; then
    echo "workspace escape was not rejected" >&2
    exit 1
fi
[ -e "$tmp/outside/keep" ]

printf 'verified download\n' > "$tmp/source"
digest="$(hh_sha256 "$tmp/source")"
hh_download_verified "file://$tmp/source" "$tmp/download" "$digest" 2>/dev/null && {
    echo "non-HTTPS download unexpectedly accepted" >&2
    exit 1
}

mkdir -p "$tmp/archive/good" "$tmp/archive/links"
printf 'content\n' > "$tmp/archive/good/file"
ln -s ../good/file "$tmp/archive/links/link"
tar -czf "$tmp/good.tar.gz" -C "$tmp/archive/good" .
tar -czf "$tmp/link.tar.gz" -C "$tmp/archive/links" .
hh_archive_is_safe "$tmp/good.tar.gz"
if hh_archive_is_safe "$tmp/link.tar.gz" 2>/dev/null; then
    echo "archive symlink was not rejected" >&2
    exit 1
fi

if rg -n '\beval\b|curl[^\n]*\|[^\n]*(sh|bash)|brew (update|upgrade)|apk (-U )?upgrade|zypper update' \
    "$repo_dir" --glob '*.sh' --glob '!tests/security-smoke.sh' >/dev/null; then
    echo "prohibited dynamic execution or broad package upgrade found" >&2
    exit 1
fi

grep -Fq 'if [ "$hh_arg" = "--accept-root" ]' "$repo_dir/hercules-buildall.sh"
grep -Fq 'f13701ebd542e74d0fc83b2a7876a812b07d21e43400275ed65b1ac860204bd4' "$repo_dir/hercules-helper.conf"

for script in "$repo_dir"/*.sh "$repo_dir"/lib/hercules-helper/*.sh "$repo_dir"/tests/*.sh "$repo_dir"/packagers/debian/*.sh; do
    bash -n "$script"
done

echo "security smoke tests passed"
