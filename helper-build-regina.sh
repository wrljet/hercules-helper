#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/lib/hercules-helper/common.sh"

regina_version="${HERCULES_REGINA_VERSION:-3.9.7}"
regina_dir="regina-rexx-$regina_version"
regina_archive="Regina-REXX-$regina_version.tar.gz"
regina_url="${HERCULES_REGINA_URL:-https://gist.github.com/wrljet/8581fda46d64392fc6874f0142ad5a80/raw/0f943d464acda87fb34882277a20dde770f77d0c/Regina-REXX-3.9.7.tar.gz}"
regina_sha256="${HERCULES_REGINA_SHA256:-f13701ebd542e74d0fc83b2a7876a812b07d21e43400275ed65b1ac860204bd4}"
work_dir="${HERCULES_REGINA_WORK_DIR:-$PWD/regina-build}"
install_dir="${HERCULES_REGINA_PREFIX:-$HOME/.local/regina-$regina_version}"
assume_yes=false
install_packages=true

usage()
{
    cat <<'EOF'
Usage: helper-build-regina.sh [OPTIONS]

Build and install a checksum-verified Regina REXX source release.

  --prefix=DIR    installation prefix (default: ~/.local/regina-VERSION)
  --work-dir=DIR  isolated build directory (default: ./regina-build)
  --no-packages   do not install prerequisite packages
  --yes           run without confirmation
  -h, --help      show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --prefix=*) install_dir="${arg#*=}" ;;
        --work-dir=*) work_dir="${arg#*=}" ;;
        --no-packages) install_packages=false ;;
        --yes) assume_yes=true ;;
        -h|--help) usage; exit 0 ;;
        *) hh_die "Unknown option: $arg"; usage >&2; exit 2 ;;
    esac
done

case "$install_dir" in /*) ;; *) install_dir="$PWD/$install_dir" ;; esac
case "$work_dir" in /*) ;; *) work_dir="$PWD/$work_dir" ;; esac

printf 'Regina REXX %s will be installed in %s\n' "$regina_version" "$install_dir"
printf 'Build workspace: %s\n' "$work_dir"
if ! $assume_yes; then
    read -r -p 'Press Return to continue, or Ctrl+C to abort: ' _
fi

if $install_packages; then
    case "$(uname -s)" in
        Darwin)
            hh_require_command brew
            brew install curl
            ;;
        Linux)
            printf '%s\n' 'Install the platform compiler, make, curl, and development headers if they are not already present.'
            ;;
    esac
fi

mkdir -p "$work_dir"
hh_safe_rm_rf "$work_dir" "$regina_dir"
rm -f -- "$work_dir/$regina_archive"
hh_download_verified "$regina_url" "$work_dir/$regina_archive" "$regina_sha256"
hh_extract_tar_gz "$work_dir/$regina_archive" "$work_dir"

cd "$work_dir/$regina_dir"
configure_args=(./configure "--prefix=$install_dir")
if [ "$(uname -s)" = Darwin ]; then
    export CFLAGS="${CFLAGS:-} -Wno-error=implicit-function-declaration -Wno-incompatible-function-pointer-types"
fi
hh_run "${configure_args[@]}"
hh_run make clean
# Regina's Makefile renames shared object files between targets and is not
# parallel-safe. A parallel build races rexx.o, extstack.o, and rexxbif.o.
hh_run make
hh_run make install

env_script="$install_dir/hercules-regina-env.sh"
mkdir -p "$install_dir"
cat >"$env_script" <<EOF
#!/usr/bin/env bash
export HERCULES_REGINA_PREFIX="$install_dir"
export PATH="$install_dir/bin\${PATH:+:\$PATH}"
export CPPFLAGS="-I$install_dir/include\${CPPFLAGS:+ \$CPPFLAGS}"
export LDFLAGS="-L$install_dir/lib\${LDFLAGS:+ \$LDFLAGS}"
if [ "\$(uname -s)" = Darwin ]; then
    export DYLD_LIBRARY_PATH="$install_dir/lib\${DYLD_LIBRARY_PATH:+:\$DYLD_LIBRARY_PATH}"
else
    export LD_LIBRARY_PATH="$install_dir/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
fi
EOF
chmod 0755 "$env_script"

HERCULES_REGINA_PREFIX="$install_dir"
export HERCULES_REGINA_PREFIX
source "$SCRIPT_DIR/lib/hercules-helper/regina.sh"
hh_regina_prepare_environment
hh_regina_version
printf 'Environment script: %s\n' "$env_script"
