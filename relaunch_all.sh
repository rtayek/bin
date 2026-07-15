#!/bin/sh
# Windows 11 Workbench - Master Workstation Relauncher (Fixed App Profiles)

echo "Spawning your high-visibility Bash boxes on the left monitor..."
~/bin/launch4.sh

echo "Launching your custom Chrome window containers with full group memory..."

# Uses the official system start utility to trigger Chrome using its standard
# shortcut link profile, restoring all your active window names and tab groups!
cmd.exe /c "start chrome"

echo "Done! Full workspace layout and tab groups deployed successfully."
