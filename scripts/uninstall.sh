#!/bin/bash
set -euo pipefail
support="$HOME/Library/Application Support/DeskflowGlobe"
agent="$HOME/Library/LaunchAgents/io.github.audit0.deskflowglobe.plist"
/bin/launchctl bootout "gui/$(/usr/bin/id -u)/io.github.audit0.deskflowglobe" 2>/dev/null || :
# Do not stop the separate prototype when this release is not installed.
if [ -d "$support/Deskflow Globe.app" ]; then /usr/bin/pkill -x DeskflowGlobe 2>/dev/null || :; fi
backup="$HOME/Library/Application Support/DeskflowGlobe-backup-$(/bin/date +%Y%m%d-%H%M%S)-$$"
if [ -e "$agent" ] || [ -d "$support/Deskflow Globe.app" ]; then
  mkdir -p "$backup"
  if [ -e "$agent" ]; then /bin/mv "$agent" "$backup/"; fi
  if [ -d "$support/Deskflow Globe.app" ]; then /bin/mv "$support" "$backup/files"; fi
fi
echo "Removed autostart. Backup: $backup"
echo 'You can restart your previous Fn utility. Remove Deskflow Globe from Input Monitoring if desired.'
