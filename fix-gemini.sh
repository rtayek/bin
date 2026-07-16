#!/bin/sh
# -------------------------------------------------------------------------
# Gemini CLI Authentication Reset & Browser Login Trigger
# -------------------------------------------------------------------------

echo "🗑️  Clearing stuck or corrupted Gemini local session caches..."
# Expand the home directory to find and force-remove the stuck config folder
GEMINI_CACHE_DIR="$HOME/.gemini"

if [ -d "$GEMINI_CACHE_DIR" ]; then
    rm -rf "$GEMINI_CACHE_DIR"
    echo "✅ Local session folder wiped successfully."
else
    echo "ℹ️  No local session cache folder found. Starting fresh."
fi

echo ""
echo "🚀 Launching Gemini CLI interactive browser authentication..."
echo "👉 When the browser opens, select your primary Google account."
echo ""

# Force the CLI to run the global interactive login sequence
gemini /auth
