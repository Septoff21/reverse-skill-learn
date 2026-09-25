#!/usr/bin/env bash
# cloud-lab-bootstrap.sh — stand up an ISOLATED offline sample-analysis RE lab
#
# Fork addition (Septoff21/reverse-skill-learn) for the cloud-lab workflow:
# analyze user-supplied sample FILES (APK / ELF / firmware / PCAP / archives)
# offline, inside a CLEAN, CREDENTIAL-FREE Linux box.
#
# HARD RULE: run this ONLY inside a disposable Linux environment
#   (a Claude cloud session, a throwaway VPS, or a container).
#   NEVER run it on a workstation that holds live credentials, SSH keys,
#   trading accounts, or GitHub tokens. It refuses to run on non-Linux.
#
# It reuses the repo's own manifest-driven installers; it does not invent a
# toolchain. It installs the offline FILE-ANALYSIS tier only. Live-target /
# network tools (nmap, agent-browser, proxycat, burpsuite, seclists) are NOT
# installed here — those belong to a separate, explicitly-scoped live-target lab.
#
# Usage:
#   bash cloud-lab-bootstrap.sh            # core static file-analysis toolchain
#   bash cloud-lab-bootstrap.sh --with-pwn # also install pwntools (CTF pwn)
#   bash cloud-lab-bootstrap.sh --help

set -euo pipefail

# ---- 0. Args first (so --help works on any OS, before the Linux gate) ----------
WITH_PWN=false
for a in "$@"; do
  case "$a" in
    --with-pwn) WITH_PWN=true ;;
    --help|-h) sed -n '2,33p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $a (see --help)" >&2; exit 1 ;;
  esac
done

# ---- 1. Hard gate: Linux only -------------------------------------------------
OS="$(uname -s 2>/dev/null || echo unknown)"
if [ "$OS" != "Linux" ]; then
  echo "REFUSED: cloud-lab-bootstrap is Linux-only (detected: $OS)." >&2
  echo "Run it inside a clean, credential-free Linux box:" >&2
  echo "  - a Claude cloud session (Linux)," >&2
  echo "  - a throwaway VPS, or" >&2
  echo "  - a Kali/Ubuntu container." >&2
  echo "Do NOT run a reverse/pentest toolchain on your main workstation." >&2
  exit 2
fi

# ---- 2. Locate repo root ------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
cd "$REPO_ROOT"
if [ ! -f "skills/scripts/bootstrap-reverse.sh" ]; then
  echo "ERROR: run from the repo root (skills/scripts/bootstrap-reverse.sh not found)." >&2
  exit 1
fi

# ---- 3. Select toolchain tier -------------------------------------------------
# Offline file-analysis tier. Names must match skills/scripts/bootstrap-manifest.json.
CORE="jadx apktool r2 rabin2 binwalk yara bkcrack"
[ "$WITH_PWN" = true ] && CORE="$CORE pwntools"

PRETTY="$(sed -n 's/^PRETTY_NAME=//p' /etc/os-release 2>/dev/null | tr -d '\"')"
echo "=== reverse-skill-learn — cloud lab bootstrap ==="
echo "Repo:  $REPO_ROOT"
echo "OS:    ${PRETTY:-Linux}"
echo "Host:  $(hostname 2>/dev/null || echo '?')  user: $(whoami)"
echo "Install (offline file-analysis): $CORE"
echo "NOT installed (live-target/network): nmap agent-browser proxycat burpsuite-mcp seclists pentestswarm"
echo

# ---- 4. First-run tool index --------------------------------------------------
echo "--- refresh tool-index (first run) ---"
bash skills/scripts/refresh-tool-index.sh || true
echo

# ---- 5. Install the analysis toolchain via the repo's manifest bootstrap -------
echo "--- install analysis toolchain (repo manifest, no MCP host, no service) ---"
set +e
bash skills/scripts/bootstrap-reverse.sh $CORE --skip-refresh --mcp-host=none
BOOT_RC=$?
set -e
echo

# ---- 6. Regenerate index after installs ---------------------------------------
echo "--- refresh tool-index (post-install) ---"
bash skills/scripts/refresh-tool-index.sh || true
echo

# ---- 7. Verify repo core is intact in this environment ------------------------
echo "--- verify: routing regression + bootstrap manifest ---"
bash skills/scripts/test-routing.sh
bash skills/scripts/test-bootstrap-manifest.sh
echo

# ---- 8. Ready summary ---------------------------------------------------------
echo "=== LAB READY ==="
echo "Tool index: $REPO_ROOT/skills/tool-index.md"
echo
echo "Next — build a case from a sample you provide:"
echo "  1) drop the sample file into this box (e.g. ./samples/<file>)"
echo "  2) bash skills/scripts/case-init.sh --hint \"<what the sample is>\""
echo "  3) in work/<case>/scope.md set auth.status=granted via the offline-sample preset"
echo "  4) route -> open PRIMARY SKILL.md -> analyze -> record Evidence E-00x"
echo "  5) python3 skills/case-review/scripts/review_case.py work/<case> --verify-hashes --strict"
if [ "$BOOT_RC" -ne 0 ]; then
  echo
  echo "NOTE: one or more tools reported manual-install-required (see install output above)."
  echo "      That is expected for commercial/manual tools; the lab is still usable for the rest."
fi
exit 0
