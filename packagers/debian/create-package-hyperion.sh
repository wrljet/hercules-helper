#!/usr/bin/env bash

# Create a Debian package for SDL-Hercules Hyperion.
# Rewritten to use the current repo layout and staged installs instead of
# modifying the live system during package creation.

set -euo pipefail

if [[ ${TRACE:-false} == true ]]; then
    set -x
fi

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CURRENT_TIME="$(date "+%Y-%m-%d")"
NPROCS="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"

log() {
    printf '%s\n' "$*"
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

run() {
    log "+ $*"
    if [[ $DRY_RUN == true ]]; then
        return 0
    fi
    "$@"
}

run_in_dir() {
    local dir="$1"
    shift

    log "+ (cd $dir && $*)"
    if [[ $DRY_RUN == true ]]; then
        return 0
    fi
    (
        cd "$dir"
        "$@"
    )
}

have_command() {
    command -v "$1" >/dev/null 2>&1
}

usage() {
    cat <<'EOF'
Usage: create-package-hyperion.sh [options]

Options:
  --build-root PATH          Working directory for clones, builds, and staging
  --output-dir PATH          Directory for the finished .deb
  --template NAME            Package template directory under packagers/debian
  --repo URL                 Hyperion git repo URL
  --branch NAME              Hyperion git branch to clone
  --commit SHA               Hyperion git commit/tag to check out
  --extpkgs-branch NAME      Branch to use for external package repos
  --install-prefix PATH      Install prefix to package, default /usr/local
  --install-deps             Install missing Debian packages with apt
  --test-install             Install the built .deb with sudo dpkg -i
  --no-check                 Skip make check
  --keep-work                Keep existing build directories instead of cleaning
  --dry-run                  Print commands without executing them
  --enable-regina-rexx       Force --enable-regina-rexx
  --disable-regina-rexx      Force --disable-regina-rexx
  -h, --help                 Show this help text

Environment overrides are also supported. Legacy variable names such as
git_repo_hyperion and build_path are still accepted.
EOF
}

default_template_dir=""

if [[ -d "$SCRIPT_DIR/hercules-hyperion" ]]; then
    default_template_dir="$SCRIPT_DIR/hercules-hyperion"
else
    default_template_dir="$(
        find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d -name 'hyperion-*' \
            | sort -V \
            | tail -n 1
    )"
fi

[[ -n "$default_template_dir" ]] || die "No Debian package template directory found under $SCRIPT_DIR"

PACKAGE_TEMPLATE="${PACKAGE_TEMPLATE:-${package_template:-$(basename "$default_template_dir")}}"
BUILD_ROOT="${BUILD_ROOT:-${build_path:-$HOME/hyperion-build-package}}"
OUTPUT_DIR="${OUTPUT_DIR:-}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"

GIT_REPO_HYPERION="${GIT_REPO_HYPERION:-${git_repo_hyperion:-https://github.com/SDL-Hercules-390/hyperion.git}}"
GIT_BRANCH_HYPERION="${GIT_BRANCH_HYPERION:-${git_branch_hyperion:-}}"
GIT_COMMIT_HYPERION="${GIT_COMMIT_HYPERION:-${git_commit_hyperion:-}}"
EXTPKGS_REPO_BASE="${EXTPKGS_REPO_BASE:-${git_repo_extpkgs:-https://github.com/SDL-Hercules-390}}"
EXTPKGS_BRANCH="${EXTPKGS_BRANCH:-${git_branch_extpkgs:-}}"

INSTALL_DEPS="${INSTALL_DEPS:-false}"
TEST_INSTALL="${TEST_INSTALL:-false}"
RUN_CHECK="${RUN_CHECK:-true}"
KEEP_WORK="${KEEP_WORK:-false}"
DRY_RUN="${DRY_RUN:-false}"
REXX_MODE="${REXX_MODE:-auto}"
OUTPUT_DIR_EXPLICIT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build-root)
            BUILD_ROOT="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            OUTPUT_DIR_EXPLICIT=true
            shift 2
            ;;
        --template)
            PACKAGE_TEMPLATE="$2"
            shift 2
            ;;
        --repo)
            GIT_REPO_HYPERION="$2"
            shift 2
            ;;
        --branch)
            GIT_BRANCH_HYPERION="$2"
            shift 2
            ;;
        --commit)
            GIT_COMMIT_HYPERION="$2"
            shift 2
            ;;
        --extpkgs-branch)
            EXTPKGS_BRANCH="$2"
            shift 2
            ;;
        --install-prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        --install-deps)
            INSTALL_DEPS=true
            shift
            ;;
        --test-install)
            TEST_INSTALL=true
            shift
            ;;
        --no-check)
            RUN_CHECK=false
            shift
            ;;
        --keep-work)
            KEEP_WORK=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --enable-regina-rexx)
            REXX_MODE=enable
            shift
            ;;
        --disable-regina-rexx)
            REXX_MODE=disable
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

if [[ $OUTPUT_DIR_EXPLICIT != true && -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$BUILD_ROOT"
fi

PACKAGE_TEMPLATE_DIR="$SCRIPT_DIR/$PACKAGE_TEMPLATE"
[[ -d "$PACKAGE_TEMPLATE_DIR" ]] || die "Package template directory not found: $PACKAGE_TEMPLATE_DIR"

mkdir -p "$BUILD_ROOT" "$OUTPUT_DIR"

LOGFILE="${LOGFILE:-$BUILD_ROOT/$(basename "${0%.*}")-$CURRENT_TIME.log}"
exec > >(tee -a "$LOGFILE") 2>&1

required_commands=(
    git
    cmake
    make
    autoreconf
    sed
    awk
    find
    grep
    du
    dpkg
    dpkg-deb
    dpkg-query
)

missing_commands=()
for cmd in "${required_commands[@]}"; do
    if ! have_command "$cmd"; then
        missing_commands+=("$cmd")
    fi
done

if (( ${#missing_commands[@]} > 0 )); then
    die "Missing required commands: ${missing_commands[*]}"
fi

debian_packages=(
    git
    build-essential
    cmake
    autoconf
    automake
    flex
    gawk
    m4
    libltdl-dev
    libtool-bin
    libcap2-bin
    libbz2-dev
    zlib1g-dev
)

check_installed_package() {
    local package="$1"
    local status

    status="$(dpkg-query --show --showformat='${db:Status-Status}\n' "$package" 2>/dev/null || true)"
    [[ "$status" == "installed" ]]
}

ensure_debian_packages() {
    local missing_packages=()
    local package

    for package in "${debian_packages[@]}"; do
        if ! check_installed_package "$package"; then
            missing_packages+=("$package")
        fi
    done

    if (( ${#missing_packages[@]} == 0 )); then
        return 0
    fi

    log "Missing Debian packages: ${missing_packages[*]}"
    if [[ $INSTALL_DEPS != true ]]; then
        die "Re-run with --install-deps after reviewing the package list above."
    fi

    run sudo apt-get update
    run sudo apt-get install -y "${missing_packages[@]}"
}

script_version="$(git -C "$REPO_ROOT" describe --long --tags --dirty --always 2>/dev/null || echo unknown)"

WORK_HYPERION_DIR="$BUILD_ROOT/hyperion"
WORK_EXTPKGS_DIR="$BUILD_ROOT/extpkgs"
STAGE_ROOT="$BUILD_ROOT/stage"
STAGE_DIR="$STAGE_ROOT/$PACKAGE_TEMPLATE"

clean_work_dirs() {
    if [[ $KEEP_WORK == true ]]; then
        return 0
    fi

    run rm -rf "$WORK_HYPERION_DIR"
    run rm -rf "$WORK_EXTPKGS_DIR"
    run rm -rf "$STAGE_DIR"
}

clone_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="${3:-}"

    run rm -rf "$target_dir"
    if [[ -n "$branch" ]]; then
        run git clone --branch "$branch" "$repo_url" "$target_dir"
    else
        run git clone "$repo_url" "$target_dir"
    fi
}

checkout_commit_if_requested() {
    local repo_dir="$1"
    local commit="$2"

    if [[ -n "$commit" ]]; then
        run_in_dir "$repo_dir" git checkout "$commit"
    fi
}

detect_extpkgs_lib_subdir() {
    case "$(uname -m)" in
        i*86|x86*|amd64*)
            printf '%s\n' ""
            ;;
        aarch64*|arm64*)
            printf '%s\n' "/aarch64"
            ;;
        arm*)
            printf '%s\n' "/arm"
            ;;
        e2k*)
            printf '%s\n' "/e2k"
            ;;
        mips*)
            printf '%s\n' "/mips"
            ;;
        ppc*|powerpc*)
            printf '%s\n' "/ppc"
            ;;
        sparc*)
            printf '%s\n' "/sparc"
            ;;
        s390x*)
            printf '%s\n' "/s390x"
            ;;
        xscale*)
            printf '%s\n' "/xscale"
            ;;
        riscv64*)
            printf '%s\n' "/riscv64"
            ;;
        *)
            printf '%s\n' "/unknown"
            ;;
    esac
}

detect_platform_bitness() {
    case "$(uname -s):$(uname -m)" in
        Linux:aarch64|Linux:x86_64|Linux:ia86|Linux:alpha|Linux:ppc64|Linux:ppc64le|Linux:s390x|Linux:e2k|Linux:riscv64)
            printf '%s\n' "64"
            ;;
        FreeBSD:amd64|FreeBSD:arm64|FreeBSD:sparc64|OpenBSD:amd64|OpenBSD:arm64|OpenBSD:sparc64|NetBSD:amd64|NetBSD:arm64|NetBSD:sparc64)
            printf '%s\n' "64"
            ;;
        *)
            printf '%s\n' "32"
            ;;
    esac
}

build_extpkgs() {
    local lib_subdir
    local bitness
    local pkg
    local build_dir

    lib_subdir="$(detect_extpkgs_lib_subdir)"
    bitness="$(detect_platform_bitness)"
    run mkdir -p "$WORK_EXTPKGS_DIR/build"

    for pkg in crypto decNumber SoftFloat telnet; do
        clone_repo "$EXTPKGS_REPO_BASE/$pkg.git" "$WORK_EXTPKGS_DIR/$pkg" "$EXTPKGS_BRANCH"
        build_dir="$WORK_EXTPKGS_DIR/build/${pkg}${bitness}.Release"
        run mkdir -p "$build_dir"
        run rm -f "$build_dir/CMakeCache.txt"
        run_in_dir "$build_dir" \
            cmake \
            -D "INSTALL_PREFIX=$WORK_EXTPKGS_DIR" \
            -D "LIB_INSTALL_DIR=lib$lib_subdir" \
            "$WORK_EXTPKGS_DIR/$pkg"
        run_in_dir "$build_dir" make clean
        run_in_dir "$build_dir" make -j "$NPROCS" all
        run_in_dir "$build_dir" make install
    done
}

detect_rexx_option() {
    case "$REXX_MODE" in
        enable)
            printf '%s\n' "--enable-regina-rexx"
            ;;
        disable)
            printf '%s\n' "--disable-regina-rexx"
            ;;
        auto)
            if have_command rexx && find /usr/include /usr/local/include -name rexxsaa.h -print -quit 2>/dev/null | grep -q .; then
                printf '%s\n' "--enable-regina-rexx"
            else
                printf '%s\n' "--disable-regina-rexx"
            fi
            ;;
        *)
            die "Unsupported REXX_MODE: $REXX_MODE"
            ;;
    esac
}

build_hyperion() {
    local rexx_option
    local configure_args

    clone_repo "$GIT_REPO_HYPERION" "$WORK_HYPERION_DIR" "$GIT_BRANCH_HYPERION"
    checkout_commit_if_requested "$WORK_HYPERION_DIR" "$GIT_COMMIT_HYPERION"

    rexx_option="$(detect_rexx_option)"
    configure_args=(
        "--enable-optimization=-g -g3 -ggdb3 -O3"
        "--enable-extpkgs=$WORK_EXTPKGS_DIR"
        "--prefix=$INSTALL_PREFIX"
        "--libdir=$INSTALL_PREFIX/lib"
        "--enable-custom=Built using Hercules-Helper ($script_version)"
        "$rexx_option"
    )

    run_in_dir "$WORK_HYPERION_DIR" autoreconf --force --install
    run_in_dir "$WORK_HYPERION_DIR" ./autogen.sh
    run_in_dir "$WORK_HYPERION_DIR" ./configure "${configure_args[@]}"
    run_in_dir "$WORK_HYPERION_DIR" ./config.status --config
    run_in_dir "$WORK_HYPERION_DIR" make clean
    run_in_dir "$WORK_HYPERION_DIR" make -j "$NPROCS"

    if [[ $RUN_CHECK == true ]]; then
        run_in_dir "$WORK_HYPERION_DIR" make check
    fi
}

determine_hyperion_version() {
    if [[ -x "$WORK_HYPERION_DIR/_dynamic_version" ]]; then
        (
            cd "$WORK_HYPERION_DIR"
            ./_dynamic_version . VERSION \
                | awk '{sub("-modified","", $0); print}' \
                | tr -d '"'
        )
    else
        git -C "$WORK_HYPERION_DIR" describe --tags --dirty --always 2>/dev/null || echo unknown
    fi
}

rewrite_control_metadata() {
    local control_file="$1"
    local package_version="$2"
    local package_arch="$3"
    local installed_size_kb="$4"

    run sed -i \
        -e "s/^Version:.*/Version: $package_version/" \
        -e "s/^Architecture:.*/Architecture: $package_arch/" \
        -e "s/^Installed-Size:.*/Installed-Size: $installed_size_kb/" \
        "$control_file"
}

rewrite_changelog() {
    local changelog_file="$1"
    local package_name="$2"
    local package_version="$3"
    local maintainer="$4"
    local date_rfc2822

    date_rfc2822="$(LC_ALL=C date -R)"

    if [[ $DRY_RUN == true ]]; then
        log "+ rewrite changelog $changelog_file"
        return 0
    fi

    cat >"$changelog_file" <<EOF
$package_name ($package_version) stable; urgency=low

  * Automated package build.

 -- $maintainer  $date_rfc2822
EOF
}

rewrite_postinst_prefix() {
    local postinst_file="$1"

    if [[ "$INSTALL_PREFIX" == "/usr/local" ]]; then
        return 0
    fi

    run sed -i "s|/usr/local/|$INSTALL_PREFIX/|g" "$postinst_file"
}

stage_package_tree() {
    run rm -rf "$STAGE_DIR"
    run mkdir -p "$STAGE_ROOT"
    run cp -R "$PACKAGE_TEMPLATE_DIR" "$STAGE_DIR"
    run_in_dir "$WORK_HYPERION_DIR" make install "DESTDIR=$STAGE_DIR"
}

sanitize_debian_metadata_permissions() {
    local debian_dir="$STAGE_DIR/DEBIAN"
    local maintainer_script
    local metadata_file

    [[ -d "$debian_dir" ]] || die "Missing Debian metadata directory: $debian_dir"

    # `cp -R` preserves the template directory mode, including setgid bits.
    # On directories, a numeric chmod can preserve special bits, so clear the
    # setgid bit explicitly before applying the final mode for dpkg-deb.
    run chmod g-s "$STAGE_DIR" "$debian_dir"
    run chmod 0755 "$STAGE_DIR" "$debian_dir"

    while IFS= read -r -d '' maintainer_script; do
        run chmod 0755 "$maintainer_script"
    done < <(find "$debian_dir" -maxdepth 1 -type f \
        \( -name preinst -o -name postinst -o -name prerm -o -name postrm -o -name config \) \
        -print0)

    while IFS= read -r -d '' metadata_file; do
        run chmod 0644 "$metadata_file"
    done < <(find "$debian_dir" -maxdepth 1 -type f \
        ! \( -name preinst -o -name postinst -o -name prerm -o -name postrm -o -name config \) \
        -print0)
}

build_debian_package() {
    local control_file="$STAGE_DIR/DEBIAN/control"
    local postinst_file="$STAGE_DIR/DEBIAN/postinst"
    local changelog_file="$STAGE_DIR/DEBIAN/changelog"
    local package_name
    local maintainer
    local package_arch
    local package_version
    local installed_size_kb
    local output_deb

    if [[ $DRY_RUN == true ]]; then
        package_name="$(awk '/^Package:/ {print $2; exit}' "$PACKAGE_TEMPLATE_DIR/DEBIAN/control")"
        package_arch="$(dpkg --print-architecture)"
        log
        log "Dry run complete."
        log "Package would be built as:"
        log "  $OUTPUT_DIR/${package_name}_<hyperion-version>_${package_arch}.deb"
        return 0
    fi

    [[ -f "$control_file" ]] || die "Missing control file: $control_file"
    [[ -f "$postinst_file" ]] || die "Missing postinst file: $postinst_file"
    [[ -f "$changelog_file" ]] || die "Missing changelog file: $changelog_file"

    package_name="$(awk '/^Package:/ {print $2; exit}' "$control_file")"
    maintainer="$(awk 'BEGIN{FS=": "}/^Maintainer:/ {print $2; exit}' "$control_file")"
    package_arch="$(dpkg --print-architecture)"
    package_version="$(determine_hyperion_version)"
    installed_size_kb="$(du -sk "$STAGE_DIR" | awk '{print $1}')"
    output_deb="$OUTPUT_DIR/${package_name}_${package_version}_${package_arch}.deb"

    rewrite_control_metadata "$control_file" "$package_version" "$package_arch" "$installed_size_kb"
    rewrite_postinst_prefix "$postinst_file"
    rewrite_changelog "$changelog_file" "$package_name" "$package_version" "$maintainer"
    sanitize_debian_metadata_permissions

    run rm -f "$output_deb"
    run dpkg-deb --root-owner-group --build "$STAGE_DIR" "$output_deb"

    log
    log "Package created:"
    log "  $output_deb"

    if [[ $TEST_INSTALL == true ]]; then
        run sudo dpkg -i "$output_deb"
        run dpkg-deb -f "$output_deb"
        run dpkg -L "$package_name"
    fi
}

main() {
    log "Using logfile: $LOGFILE"
    log "Repo root           : $REPO_ROOT"
    log "Package template    : $PACKAGE_TEMPLATE_DIR"
    log "Build root          : $BUILD_ROOT"
    log "Output directory    : $OUTPUT_DIR"
    log "Install prefix      : $INSTALL_PREFIX"
    log "Hyperion repo       : $GIT_REPO_HYPERION"

    if [[ -n "$GIT_BRANCH_HYPERION" ]]; then
        log "Hyperion branch     : $GIT_BRANCH_HYPERION"
    fi

    if [[ -n "$GIT_COMMIT_HYPERION" ]]; then
        log "Hyperion commit     : $GIT_COMMIT_HYPERION"
    fi

    if [[ -n "$EXTPKGS_BRANCH" ]]; then
        log "External pkg branch : $EXTPKGS_BRANCH"
    fi

    ensure_debian_packages
    clean_work_dirs
    build_extpkgs
    build_hyperion
    stage_package_tree
    build_debian_package
}

main "$@"
