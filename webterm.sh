#!/bin/sh

# 1. Configuration
PORT=1031
URL="http://localhost:1031"
WIN_BASH_PATH="C:\\Program Files\\Git\\bin\\bash.exe"

# 2. Check if ttyd is available
if command -v ttyd > /dev/null 2>&1; then
    TTY_CMD="ttyd"
elif command -v ttyd.win32.exe > /dev/null 2>&1; then
    TTY_CMD="ttyd.win32.exe"
else
    echo "Error: ttyd could not be found."
    echo "Please run 'winget install tsl0922.ttyd' or download ttyd.win32.exe first."
    exit 1
fi

# 3. Check if port 1031 is already in use
if netstat -ano | grep ":${PORT} " > /dev/null 2>&1; then
    echo "Port ${PORT} is already in use. Opening browser tab to the existing session..."
    cmd.exe /c start "$URL"
    exit 0
fi

# 4. Launch the browser tab asynchronously after a 1-second pause
(sleep 1; cmd.exe /c start "$URL" > /dev/null 2>&1) #&


# 5. Start the web terminal server on port 1031
echo "Starting web terminal on ${URL}..."
echo "Press Ctrl+C in this window to shut down the browser server."
echo "------------------------------------------------------------------"

# Force ttyd to start inside your user profile directory
$TTY_CMD -W -p "$PORT" --cwd "C:\\Users\\ray" "$WIN_BASH_PATH" --login -i
