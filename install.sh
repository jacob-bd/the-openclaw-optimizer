#!/bin/sh
# OpenClaw Optimizer - One-liner Installer
# https://github.com/jacob-bd/the-openclaw-optimizer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jacob-bd/the-openclaw-optimizer/main/install.sh | sh
#   sh install.sh --help
#   sh install.sh --tools claude,openclaw
#

set -e

REPO_URL="https://github.com/jacob-bd/the-openclaw-optimizer"
TARBALL_URL="${REPO_URL}/archive/refs/heads/main.tar.gz"
SKILL_FOLDER="openclaw-optimizer"

setup_colors() {
    if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ -n "$(tput colors 2>/dev/null)" ]; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        BOLD=$(tput bold)
        RESET=$(tput sgr0)
    else
        RED="" GREEN="" YELLOW="" BLUE="" BOLD="" RESET=""
    fi
}

info()    { printf "%s[INFO]%s  %s\n" "$BLUE" "$RESET" "$1"; }
warn()    { printf "%s[WARN]%s  %s\n" "$YELLOW" "$RESET" "$1"; }
error()   { printf "%s[ERROR]%s %s\n" "$RED" "$RESET" "$1" >&2; }
success() { printf "%s[OK]%s    %s\n" "$GREEN" "$RESET" "$1"; }

die() {
    error "$1"
    exit 1
}

TOOLS_FILTER=""
SHOW_HELP=false

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                SHOW_HELP=true
                shift
                ;;
            --tools)
                if [ -z "${2:-}" ]; then
                    die "--tools requires a comma-separated list (e.g., --tools claude,openclaw)"
                fi
                TOOLS_FILTER="$2"
                shift 2
                ;;
            --tools=*)
                TOOLS_FILTER="${1#--tools=}"
                shift
                ;;
            *)
                warn "Unknown argument: $1"
                shift
                ;;
        esac
    done
}

show_help() {
    cat <<'HELP'
OpenClaw Optimizer - Installer

Usage:
  sh install.sh [OPTIONS]

Options:
  --help, -h        Show this help message
  --tools LIST      Comma-separated list of tools to install to
                    (skips auto-detection)
                    Valid: claude,gemini,antigravity,opencode,openclaw,
                           codex,goose,roo,cursor,cline

Examples:
  sh install.sh                           # Auto-detect and install
  sh install.sh --tools claude,openclaw   # Install to specific tools only

What this does:
  1. Detects which AI coding tools you have installed
  2. Downloads the OpenClaw Optimizer skill from GitHub
  3. Installs it to all detected tools (or the ones you specify)
HELP
}

DETECTED_TOOLS=""
DETECTED_COUNT=0

detect_tools() {
    info "Detecting installed AI tools..."
    echo ""

    check_tool "Claude Code"    "$HOME/.claude"                 "$HOME/.claude/skills"
    check_tool "Gemini CLI"     "$HOME/.gemini"                 "$HOME/.gemini/skills"
    check_tool "Anti-Gravity"   "$HOME/.gemini/antigravity"     "$HOME/.gemini/antigravity/skills"
    check_tool "OpenCode"       "$HOME/.config/opencode"        "$HOME/.config/opencode/skills"
    check_tool "OpenClaw"       "$HOME/.openclaw"               "$HOME/.openclaw/workspace/skills"
    check_tool "OpenAI Codex"   "$HOME/.codex"                  "$HOME/.codex/skills"
    check_tool "block/goose"    "$HOME/.config/goose"           "$HOME/.config/goose/skills"
    check_tool "Roo Code"       "$HOME/.roo"                    "$HOME/.roo/skills"
    check_tool "Cursor"         "$HOME/.cursor"                 "$HOME/.cursor/skills"
    check_tool "Cline"          "$HOME/.cline"                  "$HOME/.cline/skills"

    if [ "$DETECTED_COUNT" -eq 0 ]; then
        echo ""
        warn "No supported AI tools detected on this system."
        warn "Install one of these tools first, then re-run this script."
        exit 0
    fi

    echo ""
    info "Found $DETECTED_COUNT tool(s)"
}

check_tool() {
    tool_name="$1"
    tool_dir="$2"
    skills_dir="$3"

    if [ -d "$tool_dir" ]; then
        DETECTED_TOOLS="${DETECTED_TOOLS}${tool_name}|${skills_dir}
"
        DETECTED_COUNT=$((DETECTED_COUNT + 1))
        success "Found: $tool_name"
    fi
}

filter_tools() {
    if [ -z "$TOOLS_FILTER" ]; then
        return
    fi

    FILTERED=""
    FILTERED_COUNT=0

    OLD_IFS="$IFS"
    IFS=','
    # shellcheck disable=SC2086
    set -- $TOOLS_FILTER
    IFS="$OLD_IFS"

    for short_name in "$@"; do
        case "$short_name" in
            claude)       match="Claude Code" ;;
            gemini)       match="Gemini CLI" ;;
            antigravity)  match="Anti-Gravity" ;;
            opencode)     match="OpenCode" ;;
            openclaw)     match="OpenClaw" ;;
            codex)        match="OpenAI Codex" ;;
            goose)        match="block/goose" ;;
            roo)          match="Roo Code" ;;
            cursor)       match="Cursor" ;;
            cline)        match="Cline" ;;
            *)
                warn "Unknown tool: $short_name (skipping)"
                continue
                ;;
        esac

        OLD_IFS="$IFS"
        IFS='
'
        for entry in $DETECTED_TOOLS; do
            [ -z "$entry" ] && continue
            entry_name=$(echo "$entry" | cut -d'|' -f1)
            if [ "$entry_name" = "$match" ]; then
                FILTERED="${FILTERED}${entry}
"
                FILTERED_COUNT=$((FILTERED_COUNT + 1))
            fi
        done
        IFS="$OLD_IFS"
    done

    if [ "$FILTERED_COUNT" -eq 0 ]; then
        die "None of the specified tools (${TOOLS_FILTER}) were detected on this system."
    fi

    DETECTED_TOOLS="$FILTERED"
    DETECTED_COUNT="$FILTERED_COUNT"
}

TEMP_DIR=""
SKILL_SOURCE=""

download_repo() {
    TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'skill_install')
    trap 'rm -rf "$TEMP_DIR"' EXIT

    echo ""
    info "Downloading OpenClaw Optimizer..."

    if command -v git >/dev/null 2>&1; then
        if git clone --depth 1 --quiet "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null; then
            SKILL_SOURCE="$TEMP_DIR/repo/$SKILL_FOLDER"
        else
            warn "git clone failed, falling back to curl..."
            download_via_curl
        fi
    else
        download_via_curl
    fi

    if [ ! -f "$SKILL_SOURCE/SKILL.md" ]; then
        die "Download failed: SKILL.md not found in downloaded content."
    fi

    success "Downloaded successfully"
}

download_via_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        die "Neither git nor curl found. Please install one of them."
    fi

    curl -fsSL "$TARBALL_URL" -o "$TEMP_DIR/repo.tar.gz" || \
        die "Failed to download from $TARBALL_URL"

    tar -xzf "$TEMP_DIR/repo.tar.gz" -C "$TEMP_DIR" || \
        die "Failed to extract downloaded archive."

    EXTRACTED_DIR=""
    for dir in "$TEMP_DIR"/the-openclaw-optimizer-*; do
        if [ -d "$dir" ]; then
            EXTRACTED_DIR="$dir"
            break
        fi
    done

    if [ -z "$EXTRACTED_DIR" ]; then
        die "Could not find extracted repository directory."
    fi

    SKILL_SOURCE="$EXTRACTED_DIR/$SKILL_FOLDER"
}

INSTALLED_COUNT=0
FAILED_COUNT=0

install_to_tools() {
    echo ""
    info "Installing OpenClaw Optimizer..."
    echo ""

    OLD_IFS="$IFS"
    IFS='
'
    for entry in $DETECTED_TOOLS; do
        [ -z "$entry" ] && continue
        tool_name=$(echo "$entry" | cut -d'|' -f1)
        skills_dir=$(echo "$entry" | cut -d'|' -f2)
        dest_dir="${skills_dir}/${SKILL_FOLDER}"

        mkdir -p "$skills_dir" 2>/dev/null || true

        if [ -d "$dest_dir" ]; then
            rm -rf "${dest_dir}.bak" 2>/dev/null || true
            mv "$dest_dir" "${dest_dir}.bak"
        fi

        if cp -r "$SKILL_SOURCE" "$dest_dir" 2>/dev/null; then
            success "Installed to $tool_name: $dest_dir"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
            rm -rf "${dest_dir}.bak" 2>/dev/null || true
        else
            error "Failed to install to $tool_name: $dest_dir"
            if [ -d "${dest_dir}.bak" ]; then
                mv "${dest_dir}.bak" "$dest_dir"
                warn "Restored previous version for $tool_name"
            fi
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    done
    IFS="$OLD_IFS"
}

show_summary() {
    echo ""
    echo "${BOLD}========================================${RESET}"
    echo "${BOLD}  Installation Complete!${RESET}"
    echo "${BOLD}========================================${RESET}"
    echo ""
    printf "  Installed to: %s%d%s tool(s)\n" "$GREEN" "$INSTALLED_COUNT" "$RESET"
    if [ "$FAILED_COUNT" -gt 0 ]; then
        printf "  Failed:       %s%d%s tool(s)\n" "$RED" "$FAILED_COUNT" "$RESET"
    fi
    echo ""
    echo "  ${BOLD}Next steps:${RESET}"
    echo "  1. Restart your AI coding tool to pick up the new skill"
    echo "  2. Try: \"Audit my OpenClaw setup for cost, reliability, and context bloat\""
    echo ""
    echo "  The systems directory (~/.openclaw-optimizer/systems/) will be"
    echo "  created automatically on first run."
    echo ""
    echo "  Docs: https://github.com/jacob-bd/the-openclaw-optimizer"
    echo ""
}

main() {
    setup_colors
    parse_args "$@"

    if [ "$SHOW_HELP" = true ]; then
        show_help
        exit 0
    fi

    echo ""
    echo "${BOLD}OpenClaw Optimizer - Installer${RESET}"
    echo ""

    detect_tools
    filter_tools
    download_repo
    install_to_tools
    show_summary
}

main "$@"
