# CLI Beautify - portable install kit

One command to put your whole terminal toolkit on any machine: another Mac, a
Windows PC, or a Linux box (with or without sudo). Same look and feel everywhere,
and it uninstalls clean.

## What it installs

starship, zoxide, eza, bat, fd, fzf, ripgrep, micro, tldr, plus (on macOS/Linux)
the two zsh plugins that give the Fish-like typing feel: zsh-autosuggestions and
zsh-syntax-highlighting. On Windows those two are not needed, because PSReadLine
gives ghost-text suggestions and coloring built in.

It also wires your shell (`~/.zshrc` + `~/.bashrc`, or your PowerShell profile) so
the prompt, `z`, the aliases, and the typing help are on in every new terminal. A
timestamped backup of each shell file is made before it is touched.

## The one command (curl, nothing to download)

`curl ... | bash` fetches the script and runs it in one step. You do NOT need
`beautify.sh` on the machine; nothing is saved to disk. Pick your case:

### macOS or Linux, NO sudo (the default; installs into ~/.local)
```sh
curl -fsSL https://raw.githubusercontent.com/markykessaclaude-code/cli-beautify/main/beautify.sh | bash
```
On Linux this lands everything in `~/.local/bin` and `~/.local/share`. No admin,
nothing system-wide. Works on a locked-down or shared box where you are just a user.

### Linux, WITH sudo (you own the box, want it system-wide)
```sh
curl -fsSL https://raw.githubusercontent.com/markykessaclaude-code/cli-beautify/main/beautify.sh | bash -s -- --system
```
Uses the native package manager (apt, dnf, pacman, apk). Anything the distro does
not carry (often starship, eza, tldr) is filled into `~/.local/bin` so you still get
the full set. `--system` is the only case that uses sudo.

### Windows (PowerShell, uses Scoop, no admin)
```powershell
irm https://raw.githubusercontent.com/markykessaclaude-code/cli-beautify/main/beautify.ps1 | iex
```

### Offline / air-gapped (no internet on the box)
Copy `beautify.sh` (or `beautify.ps1`) over by scp, AirDrop, or USB, then run the
local form (this is the only time you need the file present):
```sh
bash beautify.sh            # add --system for the sudo path
```

Hosted at the public repo `https://github.com/markykessaclaude-code/cli-beautify`
(no secrets, safe to be public). This `install/` folder in the project is the source
of truth. To update the live installer: edit the files here, then re-publish (copy
them into the repo checkout at `~/Documents/Claude Code/cli-beautify` and push).

## When NOT to install on a box

For a server you touch rarely or do not own, the simplest move is to install
nothing on it: SSH in from your own nice terminal and keep the pretty tools local.
Install into a remote only when you will live there a while.

## Remove it (clean)

```sh
# macOS / Linux: remove the shell block, then it tells you the uninstall line
bash beautify.sh --uninstall
```
```powershell
.\beautify.ps1 -Uninstall
```
The shell block is bracketed by `# >>> cli-beautify >>>` / `# <<< cli-beautify <<<`
markers, so removal is exact. Binaries go with `brew uninstall ...` (mac),
`rm ~/.local/bin/<tool>` (Linux home install), or `scoop uninstall ...` (Windows).

## Files here

| File | What it is |
|---|---|
| `beautify.sh` | macOS + Linux installer (default no-sudo, `--system` for sudo, `--uninstall`) |
| `beautify.ps1` | Windows PowerShell installer (`-Uninstall`, `-NoProfile`) |
| `README.md` | this doc |

## How it stays reversible (the project rule)

- Every shell file is backed up before editing.
- All edits sit inside one clearly marked block that the uninstaller removes exactly.
- The no-sudo path only ever writes to your home folder.
- No secrets are read or written anywhere in these scripts.
