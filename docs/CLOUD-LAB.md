# Cloud Lab — isolated offline sample-analysis workflow

This fork (`Septoff21/reverse-skill-learn`) is driven as a **skill book of worked
cases**: the owner feeds a sample file, and each sample becomes a reproducible
case (scope → evidence → finding → report). Samples are analyzed **offline** in a
**clean, credential-free Linux box**, never on the main workstation.

## Why a separate box (non-negotiable)

A reverse-engineering / CTF toolchain must not run where live credentials, SSH
keys, or trading/GitHub tokens live. Unknown or possibly-malicious samples are
handled only in a disposable environment. The bootstrap script refuses to run on
anything but Linux for this reason.

## Lab options

| Option | When | Notes |
|---|---|---|
| Claude cloud session (Linux) | default | Confirm it is Linux and allows `apt`/`pip` + outbound network before relying on it. Started from the desktop app — it cannot be launched from inside another session. |
| Throwaway VPS | full control | Spin a clean Linux VPS with no sensitive credentials; destroy after use. |
| Container | no new VPS | `docker run --rm -it kalilinux/kali-rolling` (or an Ubuntu image) on a Linux host. |

## Getting the (private) repo into the box — no token in plaintext

Do **not** paste a GitHub token into a prompt, env var, or command. Use one of:

- `gh auth login` **interactively once** inside the box, then
  `git clone https://github.com/Septoff21/reverse-skill-learn`; or
- upload a tarball of the repo into the box.

## One-command provisioning

From the repo root, inside the Linux box:

```bash
bash cloud-lab-bootstrap.sh            # offline file-analysis toolchain
bash cloud-lab-bootstrap.sh --with-pwn # also install pwntools (CTF pwn)
```

It reuses the repo's own manifest installers to set up the **offline
file-analysis tier** — `jadx apktool r2 rabin2 binwalk yara bkcrack`
(+ `pwntools` with `--with-pwn`) — regenerates `skills/tool-index.md`, and
verifies the core with `test-routing.sh` + `test-bootstrap-manifest.sh`.

It deliberately does **not** install live-target / network tools
(`nmap`, `agent-browser`, `proxycat`, `burpsuite`, `seclists`, `pentestswarm`).
Those belong to a separate, explicitly-scoped live-target lab, not the
offline sample track.

## Per-sample case loop

```text
1) drop sample -> ./samples/<file>
2) bash skills/scripts/case-init.sh --hint "<what the sample is>"
3) work/<case>/scope.md : auth.status=granted via the offline-sample preset
4) master-route -> open PRIMARY SKILL.md -> analyze -> record Evidence E-00x
5) python3 skills/case-review/scripts/review_case.py work/<case> --verify-hashes --strict
6) write work/<case>/report/report.md ; keep a copy under reports/
```

The result is a growing library of reference cases across skill domains
(APK reverse, ELF RE, firmware, pwn, forensics, malware triage, …), each one
proven and reproducible.
