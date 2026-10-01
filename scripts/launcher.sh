#!/bin/bash
set -eu
app=${1:?App bundle path required}
stop_langswitch=${2:-0}
previous_server=''
while :; do
  # The core may be installed somewhere other than /Applications.
  current_server=$(/usr/bin/pgrep -f '[/]deskflow-core server( |$)' | /usr/bin/head -n 1 || :)
  if [ -n "$current_server" ] && [ "$current_server" != "$previous_server" ]; then
    /bin/sleep 3
    stable_server=$(/usr/bin/pgrep -f '[/]deskflow-core server( |$)' | /usr/bin/head -n 1 || :)
    if [ "$stable_server" = "$current_server" ]; then
      if [ "$stop_langswitch" = 1 ]; then /usr/bin/pkill -x LangSwitch 2>/dev/null || :; fi
      /usr/bin/pkill -x DeskflowGlobe 2>/dev/null || :
      /usr/bin/open "$app"
      previous_server=$current_server
    fi
  elif [ -z "$current_server" ]; then
    previous_server=''
  fi
  if [ "$stop_langswitch" = 1 ] && /usr/bin/pgrep -x DeskflowGlobe >/dev/null; then
    /usr/bin/pkill -x LangSwitch 2>/dev/null || :
  fi
  /bin/sleep 5
done
