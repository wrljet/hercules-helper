#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/lib/hercules-helper/common.sh"

work_dir="${PW3270_WORK_DIR:-$PWD/pw3270-build}"
install_prefix="${PW3270_PREFIX:-$HOME/.local/pw3270}"
assume_yes=false

usage()
{
    cat <<'EOF'
Usage: helper-build-pw3270-macm1.sh [OPTIONS]

  --work-dir=DIR  source and artifact workspace (default: ./pw3270-build)
  --prefix=DIR    private dependency prefix (default: ~/.local/pw3270)
  --yes           run without confirmation
  -h, --help      show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --work-dir=*) work_dir="${arg#*=}" ;;
        --prefix=*) install_prefix="${arg#*=}" ;;
        --yes) assume_yes=true ;;
        -h|--help) usage; exit 0 ;;
        *) hh_die "Unknown option: $arg"; usage >&2; exit 2 ;;
    esac
done

[ "$(uname -s)" = Darwin ] || hh_die "This helper supports macOS only"
[ "$(uname -m)" = arm64 ] || hh_die "This helper supports Apple Silicon only"
hh_require_command xcode-select
hh_require_command brew
xcode-select -p >/dev/null

case "$work_dir" in /*) ;; *) work_dir="$PWD/$work_dir" ;; esac
case "$install_prefix" in /*) ;; *) install_prefix="$PWD/$install_prefix" ;; esac

printf 'PW3270 workspace: %s\nPrivate dependency prefix: %s\n' "$work_dir" "$install_prefix"
if ! $assume_yes; then
    read -r -p 'Press Return to continue, or Ctrl+C to abort: ' _
fi

brew install xz automake binutils coreutils curl gettext libtool openssl pkgconfig adwaita-icon-theme imagemagick gtk+3

brew_prefix="$(brew --prefix)"
libtool_gnubin="$(brew --prefix libtool)/libexec/gnubin"
PATH="$libtool_gnubin:$PATH"
CPPFLAGS="-I$brew_prefix/include${CPPFLAGS:+ $CPPFLAGS}"
LDFLAGS="-L$brew_prefix/lib${LDFLAGS:+ $LDFLAGS}"
PKG_CONFIG_PATH="$install_prefix/lib/pkgconfig:$install_prefix/lib64/pkgconfig:$(brew --prefix curl)/lib/pkgconfig:$(brew --prefix openssl)/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export PATH CPPFLAGS LDFLAGS PKG_CONFIG_PATH

mkdir -p "$work_dir" "$install_prefix"
cd "$work_dir"

clone_project()
{
    local name="$1" repository="$2" commit="$3" replace=false
    if [ -e "$name" ]; then
        if $assume_yes; then
            replace=true
        else
            read -r -p "$name exists. Replace it? [y/N] " response
            case "$response" in [yY]|[yY][eE][sS]) replace=true ;; esac
        fi
        if $replace; then
            hh_safe_rm_rf "$work_dir" "$name"
        fi
    fi
    if [ ! -d "$name/.git" ]; then
        git clone "$repository" "$name"
    fi
    git -C "$name" checkout --detach "$commit"
    [ "$(git -C "$name" rev-parse HEAD)" = "$commit" ] || hh_die "Unexpected commit for $name"
}

clone_project lib3270 https://github.com/PerryWerneck/lib3270.git 5a295e862cdb151eab05f5aad1d321be412dd5d9
clone_project libv3270 https://github.com/PerryWerneck/libv3270.git b290a714b7b6ca4dd0f556dfae278c3a939ae458
clone_project pw3270 https://github.com/PerryWerneck/pw3270.git 88fc0c73b343188b3455770686dbc18f7536dc06

cd "$work_dir/lib3270"
./autogen.sh --prefix="$install_prefix" --with-libiconv-prefix="$(brew --prefix gettext)"
make -j "$(sysctl -n hw.logicalcpu)"
make install

cd "$work_dir/libv3270"
./autogen.sh --prefix="$install_prefix"
make -j "$(sysctl -n hw.logicalcpu)"
make install

cd "$work_dir/pw3270"
chmod +x mac/bundle
./autogen.sh --prefix="$install_prefix"
make -j "$(sysctl -n hw.logicalcpu)"

cd mac
./bundle
[ -d pw3270.app ] || hh_die "PW3270 bundle was not created"
hh_safe_rm_rf "$work_dir/pw3270" pw3270.app
cp -R pw3270.app ..
cd ..
rm -f "$work_dir/pw3270-macos-arm64.zip"
zip -r "$work_dir/pw3270-macos-arm64.zip" pw3270.app
printf 'Bundle: %s\nArchive: %s\n' "$work_dir/pw3270/pw3270.app" "$work_dir/pw3270-macos-arm64.zip"
