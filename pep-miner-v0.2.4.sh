#!/bin/bash
#
# Pep Miner
# One-click Apple Silicon Scrypt setup + benchmark + PEP Stratum mining
#
# Made by 0xAlexWu
# X: @0xAlexWu
#
# Upstream miner:
#   https://github.com/JayDDee/cpuminer-opt
#
# NOTE:
#   The default mining mode in this script connects to AikaPool's PEP
#   Stratum pool. This validates real PEP-compatible Scrypt work and shares,
#   but it is NOT node-level solo mining.
#
# License suggestion for this wrapper script: MIT
#

set -Eeuo pipefail

VERSION="0.2.4"
AUTHOR="0xAlexWu"
X_HANDLE="@0xAlexWu"

MINER_DIR="$HOME/mining/cpuminer-opt"
MINER="$MINER_DIR/cpuminer"
LOG_DIR="$HOME/pep-miner"
BUILD_LOG="$LOG_DIR/build.log"
MINE_LOG="$LOG_DIR/mining.log"

POOL_HOST="${PEP_POOL_HOST:-stratum.aikapool.com}"
POOL_PORT="${PEP_POOL_PORT:-7941}"

# ANSI terminal colors. Set NO_COLOR=1 to disable.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RESET=$'\033[0m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  BLUE=$'\033[34m'
  MAGENTA=$'\033[35m'
  CYAN=$'\033[36m'
  WHITE=$'\033[37m'
else
  RESET=""
  BOLD=""
  DIM=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  MAGENTA=""
  CYAN=""
  WHITE=""
fi

mkdir -p "$LOG_DIR"

banner() {
  local pep_lines=(
'██████╗ ███████╗██████╗ '
'██╔══██╗██╔════╝██╔══██╗'
'██████╔╝█████╗  ██████╔╝'
'██╔═══╝ ██╔══╝  ██╔═══╝ '
'██║     ███████╗██║     '
'╚═╝     ╚══════╝╚═╝     '
  )

  local miner_lines=(
'███╗   ███╗ ██╗ ███╗   ██╗ ███████╗ ██████╗'
'████╗ ████║ ██║ ████╗  ██║ ██╔════╝ ██╔══██╗'
'██╔████╔██║ ██║ ██╔██╗ ██║ █████╗   ██████╔╝'
'██║╚██╔╝██║ ██║ ██║╚██╗██║ ██╔══╝   ██╔══██╗'
'██║ ╚═╝ ██║ ██║ ██║ ╚████║ ███████╗ ██║  ██║'
'╚═╝     ╚═╝ ╚═╝ ╚═╝  ╚═══╝ ╚══════╝ ╚═╝  ╚═╝'
  )

  echo
  printf "%b================================================================================%b\n\n" "$CYAN" "$RESET"

  local i
  for i in "${!pep_lines[@]}"; do
    printf "%b%s%b    %b%s%b\n" \
      "$BOLD$GREEN" "${pep_lines[$i]}" "$RESET" \
      "$BOLD$CYAN" "${miner_lines[$i]}" "$RESET"
  done

  echo
  printf "%b                              by X@0xAlexWu%b\n" "$MAGENTA" "$RESET"
  echo
  printf "%b                     Native Scrypt on Apple Silicon%b\n" "$WHITE" "$RESET"
  printf "%b                           Tested on Apple M2%b\n" "$DIM" "$RESET"
  echo
  printf "%b================================================================================%b\n\n" "$CYAN" "$RESET"
}

die() {
  echo
  printf "%b* ERROR%b      %s\n" "$BOLD$RED" "$RESET" "$*" >&2
  echo
  exit 1
}

warn() {
  printf "%b* WARN%b       %s\n" "$YELLOW" "$RESET" "$*"
}

info() {
  printf "%b* INFO%b       %s\n" "$CYAN" "$RESET" "$*"
}

ok() {
  printf "%b* OK%b         %s\n" "$GREEN" "$RESET" "$*"
}

kv() {
  local label="$1"
  shift
  printf "%b* %-10s%b %s\n" "$GREEN" "$label" "$RESET" "$*"
}

on_error() {
  local exit_code=$?
  local line_no=${1:-unknown}
  echo
  printf "%b================================================================================%b
" "$RED" "$RESET"
  printf "%b* ERROR%b      Script stopped at line %s (exit %s)
" "$BOLD$RED" "$RESET" "$line_no" "$exit_code"
  printf "%b* BUILD LOG%b  %s
" "$YELLOW" "$RESET" "$BUILD_LOG"
  printf "%b* MINING LOG%b %s
" "$YELLOW" "$RESET" "$MINE_LOG"
  printf "%b================================================================================%b
" "$RED" "$RESET"
  exit "$exit_code"
}
trap 'on_error $LINENO' ERR

detect_chip() {
  local chip=""
  chip="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
  if [[ -z "$chip" ]]; then
    chip="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip:/{print $2; exit}' || true)"
  fi
  echo "${chip:-Apple Silicon}"
}

choose_arch_flags() {
  local chip="$1"

  case "$chip" in
    *M4*|*M5*)
      echo "-O3 -march=armv9.2-a+crypto+sha3 -Wall"
      ;;
    *M2*|*M3*)
      echo "-O3 -march=armv8.6-a+crypto+sha3 -Wall"
      ;;
    *M1*)
      echo "-O3 -march=armv8.4-a+crypto+sha3 -Wall"
      ;;
    *)
      # Conservative Apple Silicon fallback.
      echo "-O3 -march=armv8.4-a+crypto -Wall"
      ;;
  esac
}

check_macos_arm64() {
  [[ "$(uname -s)" == "Darwin" ]] || die "This script currently supports macOS only."
  [[ "$(uname -m)" == "arm64" ]] || die "This script currently supports Apple Silicon (arm64) only."

  local chip
  chip="$(detect_chip)"

  kv "SYSTEM" "macOS $(sw_vers -productVersion)"
  kv "ARCH" "$(uname -m)"
  kv "CPU" "$chip"
  kv "THREADS" "$(sysctl -n hw.logicalcpu)"
}

ensure_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode Command Line Tools ready"
    return
  fi

  echo
  warn "Xcode Command Line Tools are not installed."
  echo "macOS will now open Apple's installer."
  xcode-select --install || true
  echo
  echo "After installation completes, run this script again."
  exit 0
}

ensure_brew_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

ensure_homebrew() {
  ensure_brew_path

  if command -v brew >/dev/null 2>&1; then
    ok "$(brew --version | head -1)"
    return
  fi

  echo
  info "Homebrew not found. Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  ensure_brew_path
  command -v brew >/dev/null 2>&1 || die "Homebrew installation completed but brew is not in PATH."
}

use_ustc_mirror() {
  info "Switching this process to USTC Homebrew mirrors..."
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
  export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
}

update_homebrew() {
  export HOMEBREW_NO_ASK=1
  export HOMEBREW_NO_ENV_HINTS=1
  export HOMEBREW_NO_INSTALL_CLEANUP=1

  info "Updating Homebrew..."

  if brew update; then
    return
  fi

  warn "Default Homebrew update failed."
  warn "Retrying once with USTC mirrors."
  use_ustc_mirror
  brew update
}

install_dependencies() {
  # Minimal set verified for native Apple Silicon build.
  # curl is explicit because cpuminer needs libcurl for Stratum/RPC linking.
  local deps=(
    autoconf
    automake
    ca-certificates
    curl
    gettext
    gmp
    jansson
    libunistring
    lz4
    m4
    mpfr
    pcre2
    pkgconf
    zstd
  )

  info "Installing build dependencies..."
  brew install "${deps[@]}"
}

prepare_source() {
  mkdir -p "$HOME/mining"

  if [[ -d "$MINER_DIR/.git" ]]; then
    info "Updating existing cpuminer-opt source..."
    cd "$MINER_DIR"
    git reset --hard
    git pull --ff-only
  else
    info "Cloning cpuminer-opt..."
    rm -rf "$MINER_DIR"
    git clone https://github.com/JayDDee/cpuminer-opt.git "$MINER_DIR"
    cd "$MINER_DIR"
  fi
}

build_miner() {
  local chip cflags
  chip="$(detect_chip)"
  cflags="$(choose_arch_flags "$chip")"

  info "Building cpuminer-opt for: $chip"
  info "CFLAGS: $cflags"
  info "Build log: $BUILD_LOG"

  cd "$MINER_DIR"

  export PATH="/opt/homebrew/opt/curl/bin:/opt/homebrew/opt/gettext/bin:$PATH"
  export CPPFLAGS="-I/opt/homebrew/opt/curl/include -I/opt/homebrew/include"
  export LDFLAGS="-L/opt/homebrew/opt/curl/lib -L/opt/homebrew/lib"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/curl/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

  {
    ./autogen.sh
    make clean || true
    CFLAGS="$cflags" ./configure --with-curl=/opt/homebrew/opt/curl
    make -j"$(sysctl -n hw.logicalcpu)"
  } 2>&1 | tee "$BUILD_LOG"

  [[ -x "$MINER" ]] || die "Build finished but cpuminer binary was not created."

  echo
  ok "Miner built successfully"
  ls -lh "$MINER"
}

benchmark() {
  [[ -x "$MINER" ]] || die "Miner binary not found: $MINER"

  echo
  kv "MODE" "benchmark"
  kv "ALGO" "scrypt"
  kv "PARAMS" "N=1024 r=1"
  kv "THREADS" "$(sysctl -n hw.logicalcpu)"
  kv "DURATION" "60 seconds"
  echo

  "$MINER" \
    -a scrypt \
    --benchmark \
    -t "$(sysctl -n hw.logicalcpu)" \
    --time-limit=60
}

mine_aikapool() {
  [[ -x "$MINER" ]] || die "Miner binary not found: $MINER"

  echo
  echo "============================================================"
  echo " PEP STRATUM MINING"
  echo " Pool: AikaPool low-diff VarDiff"
  echo " Endpoint: ${POOL_HOST}:${POOL_PORT}"
  echo "============================================================"
  echo
  echo "IMPORTANT:"
  echo "  This is shared pool mining, not node-level SOLO."
  echo "  AikaPool expects: UserName.WorkerName + WorkerPassword."
  echo

  local username worker workerpass login

  read -r -p "AikaPool username: " username
  read -r -p "Worker name (example: m2): " worker
  read -r -s -p "Worker password: " workerpass
  echo

  [[ -n "$username" ]] || die "Username cannot be empty."
  [[ -n "$worker" ]] || die "Worker name cannot be empty."
  [[ -n "$workerpass" ]] || die "Worker password cannot be empty."

  login="${username}.${worker}"

  echo
  kv "MODE" "PEP Stratum pool mining"
  kv "POOL" "${POOL_HOST}:${POOL_PORT}"
  kv "WORKER" "$login"
  kv "ALGO" "scrypt N=1024 r=1"
  kv "CPU" "$(detect_chip)"
  kv "THREADS" "$(sysctl -n hw.logicalcpu)"
  kv "LOG" "$MINE_LOG"

  if command -v nc >/dev/null 2>&1; then
    if nc -z -G 5 "$POOL_HOST" "$POOL_PORT" >/dev/null 2>&1; then
      ok "Stratum TCP connectivity ready"
    else
      warn "TCP preflight failed; cpuminer will still attempt to connect."
    fi
  fi

  echo
  echo "Watch for:"
  echo "  Stratum connection established"
  echo "  New Stratum Diff"
  echo "  accepted"
  echo
  echo "Press Ctrl+C to stop mining."
  echo

  "$MINER" \
    -a scrypt \
    -o "stratum+tcp://${POOL_HOST}:${POOL_PORT}" \
    -u "$login" \
    -p "$workerpass" \
    -t "$(sysctl -n hw.logicalcpu)" \
    2>&1 | tee -a "$MINE_LOG"
}


safe_reset() {
  echo
  warn "Safe Reset removes only Pep Miner build files and logs."
  warn "Homebrew, Xcode Command Line Tools, and shared Homebrew packages are kept."
  echo

  rm -rf "$MINER_DIR"
  rm -rf "$LOG_DIR"
  rm -f "$HOME/pep_m2_setup.log" "$HOME/pep_m2_mining.log"

  mkdir -p "$LOG_DIR"
  ok "Pep Miner local build state removed"
  info "Run '$0 all' to test a fresh clone/build."
}

install_and_build() {
  check_macos_arm64
  ensure_clt
  ensure_homebrew
  update_homebrew
  install_dependencies
  prepare_source
  build_miner
}

show_menu() {
  printf "%bChoose an action:%b

" "$BOLD" "$RESET"
  printf "  %b1%b) Full setup -> build -> benchmark -> start PEP mining
" "$GREEN" "$RESET"
  printf "  %b2%b) Install/build only
" "$GREEN" "$RESET"
  printf "  %b3%b) Benchmark only
" "$GREEN" "$RESET"
  printf "  %b4%b) Start PEP mining only
" "$GREEN" "$RESET"
  printf "  %b5%b) Safe Reset (remove local miner build + logs)
" "$YELLOW" "$RESET"
  printf "  %b6%b) Exit

" "$DIM" "$RESET"
}

main() {
  banner
  echo "Version: $VERSION"
  echo

  case "${1:-}" in
    install)
      install_and_build
      ;;
    benchmark)
      check_macos_arm64
      benchmark
      ;;
    mine)
      check_macos_arm64
      mine_aikapool
      ;;
    all)
      install_and_build
      benchmark
      mine_aikapool
      ;;
    reset)
      safe_reset
      ;;
    "")
      show_menu
      read -r -p "Selection [1-6]: " choice
      case "$choice" in
        1)
          install_and_build
          benchmark
          mine_aikapool
          ;;
        2)
          install_and_build
          ;;
        3)
          check_macos_arm64
          benchmark
          ;;
        4)
          check_macos_arm64
          mine_aikapool
          ;;
        5)
          safe_reset
          ;;
        6)
          exit 0
          ;;
        *)
          die "Invalid selection."
          ;;
      esac
      ;;
    -h|--help|help)
      cat <<EOF
Pep Miner v$VERSION
Made by $AUTHOR
X: $X_HANDLE

Usage:
  $0              Interactive menu
  $0 all          Install/build, benchmark, then mine
  $0 install      Install dependencies and build miner
  $0 benchmark    Run 60-second Scrypt benchmark
  $0 mine         Start AikaPool PEP Stratum mining
  $0 reset        Remove local miner build and Pep Miner logs

Environment overrides:
  PEP_POOL_HOST   Default: stratum.aikapool.com
  PEP_POOL_PORT   Default: 7941
EOF
      ;;
    *)
      die "Unknown command: $1. Use --help."
      ;;
  esac
}

main "$@"
