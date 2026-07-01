# =============================================================================
# CLI Beautify - portable installer for Windows (PowerShell).
#
# Installs: starship, zoxide, eza, bat, fd, fzf, ripgrep, micro, tldr (tealdeer)
# via Scoop (no admin, installs into your user folder). Windows already has
# ghost-text suggestions + command coloring built into PSReadLine, so this turns
# those on instead of installing zsh plugins.
#
# Usage (in PowerShell):
#   irm https://<your-host>/beautify.ps1 | iex        # once hosted
#   .\beautify.ps1                                     # local run
#   .\beautify.ps1 -Uninstall                          # remove the profile block
#   .\beautify.ps1 -NoProfile                          # install tools only
# Reversible: -Uninstall removes the profile block; `scoop uninstall <tool>`
# removes any program.
# =============================================================================
param(
  [switch]$Uninstall,
  [switch]$NoProfile
)

$ErrorActionPreference = 'Continue'
function Say($m){ Write-Host "  $m" }
function Hr($m){ Write-Host "`n== $m ==" }

$MarkA = '# >>> cli-beautify >>>'
$MarkB = '# <<< cli-beautify <<<'

function Remove-Block {
  if (-not (Test-Path $PROFILE)) { return }
  $lines = Get-Content $PROFILE
  $out = @(); $skip = $false
  foreach ($l in $lines) {
    if ($l -eq $MarkA) { $skip = $true; continue }
    if ($l -eq $MarkB) { $skip = $false; continue }
    if (-not $skip) { $out += $l }
  }
  Set-Content -Path $PROFILE -Value $out -Encoding UTF8
}

if ($Uninstall) {
  Hr "CLI Beautify uninstall (Windows)"
  Remove-Block
  Say "Removed the CLI Beautify block from your PowerShell profile."
  Say "To remove programs too:  scoop uninstall starship zoxide eza bat fd fzf ripgrep micro tealdeer"
  return
}

Hr "CLI Beautify installer (Windows)"

# 1. Ensure Scoop (no admin needed)
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Say "Installing Scoop (user-level package manager, no admin)."
  try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  } catch { Say "Scoop install failed: $_"; return }
}

# 2. Install the toolkit
Say "Installing tools via Scoop"
scoop install starship zoxide eza bat fd fzf ripgrep micro tealdeer 2>$null

# 3. Wire the PowerShell profile (idempotent)
if (-not $NoProfile) {
  if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
  Copy-Item $PROFILE "$PROFILE.bak.cli-beautify" -Force -ErrorAction SilentlyContinue
  Remove-Block  # clear any prior block first

  $block = @"
$MarkA
# Added by CLI Beautify. Safe to delete this whole block.
if (Get-Command starship -ErrorAction SilentlyContinue) { Invoke-Expression (&starship init powershell) }
if (Get-Command zoxide  -ErrorAction SilentlyContinue) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }
if (Get-Command eza -ErrorAction SilentlyContinue) {
  function ls { eza --icons=auto --group-directories-first @args }
  function ll { eza -l --icons=auto --group-directories-first --git @args }
  function lt { eza --tree --level=2 --icons=auto @args }
}
if (Get-Command bat -ErrorAction SilentlyContinue) {
  function cat { bat @args }
  `$env:BAT_THEME = 'GitHub'
}
# Fish-like typing is native on Windows via PSReadLine:
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView   # gray ghost text; press right-arrow to accept
$MarkB
"@
  Add-Content -Path $PROFILE -Value "`n$block" -Encoding UTF8
  Say "Wired $PROFILE"
}

Hr "Done"
Say "Open a NEW PowerShell window (or run:  . `$PROFILE )."
Say "Ghost-text suggestions + coloring come from PSReadLine, already built in."
Say "Remove later with:  .\beautify.ps1 -Uninstall"
