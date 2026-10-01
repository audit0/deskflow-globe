#!/bin/bash
set -euo pipefail
replace=0
check=0
case ${1:-} in
  '') ;;
  --replace-langswitch) replace=1 ;;
  --check) check=1 ;;
  *) printf '%s\n' 'Usage: Install.command [--replace-langswitch | --check]' >&2; exit 2 ;;
esac
base=$(cd "$(dirname "$0")" && pwd)
support="$HOME/Library/Application Support/DeskflowGlobe"
agent="$HOME/Library/LaunchAgents/io.github.audit0.deskflowglobe.plist"
app="$support/Deskflow Globe.app"
[ -d "$base/Deskflow Globe.app" ] || { echo 'Run the installer from the extracted release folder.' >&2; exit 1; }
/usr/bin/codesign --verify --strict "$base/Deskflow Globe.app"
/bin/bash -n "$base/launcher.sh"
if [ "$check" = 1 ]; then
  echo "Package verified. Install destination: $support (no changes made)."
  exit 0
fi
if /bin/launchctl print "gui/$(/usr/bin/id -u)/local.deskflow.globe.launcher" >/dev/null 2>&1; then
  echo 'The local prototype is active. Stop its launcher using its rollback command before installing the release.' >&2
  exit 1
fi
if [ -e "$support/Deskflow Globe.app" ] || [ -e "$agent" ]; then
  echo 'An installation already exists. Run Uninstall.command before reinstalling; it keeps a backup.' >&2
  exit 1
fi
mkdir -p "$support" "$HOME/Library/LaunchAgents"
/usr/bin/ditto "$base/Deskflow Globe.app" "$app"
cp "$base/launcher.sh" "$support/launcher.sh"
cp "$base/Uninstall.command" "$support/Uninstall.command"
/usr/bin/plutil -create xml1 "$agent"
/usr/bin/plutil -insert Label -string io.github.audit0.deskflowglobe "$agent"
/usr/bin/plutil -insert ProgramArguments -json '[]' "$agent"
/usr/bin/plutil -insert ProgramArguments.0 -string /bin/bash "$agent"
/usr/bin/plutil -insert ProgramArguments.1 -string "$support/launcher.sh" "$agent"
/usr/bin/plutil -insert ProgramArguments.2 -string "$app" "$agent"
/usr/bin/plutil -insert ProgramArguments.3 -string "$replace" "$agent"
/usr/bin/plutil -insert RunAtLoad -bool true "$agent"
/usr/bin/plutil -insert KeepAlive -bool true "$agent"
/usr/bin/plutil -insert ProcessType -string Background "$agent"
/usr/bin/plutil -insert StandardOutPath -string "$support/launcher.log" "$agent"
/usr/bin/plutil -insert StandardErrorPath -string "$support/launcher-error.log" "$agent"
/bin/launchctl bootstrap "gui/$(/usr/bin/id -u)" "$agent"
echo 'Installed. Allow Deskflow Globe in System Settings → Privacy & Security → Input Monitoring.'
echo 'Set Keyboard → Press Globe key to → Do Nothing, and quit other Fn language switchers.'
echo 'Start/restart Deskflow Globe after granting permission; the launcher waits for a Deskflow server.'
