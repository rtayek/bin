#!/bin/bash 

### Find the Git project root dynamically

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) 

### Fallback to current directory if not inside a Git repo

if [ -z "$PROJECT_ROOT" ]; then
PROJECT_ROOT=$(pwd)
echo "⚠️  Not in a Git repository. Using current directory as root: $PROJECT_ROOT"
else
echo "🎯 Detected project root: $PROJECT_ROOT"
fi 

### Define the source file (assumes the handoff markdown file is in the current working directory)

### Change "handoff.md" if your file uses a different naming pattern

SOURCE_FILE="handoff.md"
TARGET_DIR="$PROJECT_ROOT"
TARGET_FILE="
𝑇𝐴𝑅𝐺𝐸𝑇𝐷𝐼𝑅

/
SOURCE_FILE" 

### 1. Check if the file exists in the current directory

if [ ! -f "$SOURCE_FILE" ]; then
echo "❌ Error: '
𝑆𝑂𝑈𝑅𝐶𝐸𝐹𝐼𝐿𝐸′

𝑛𝑜𝑡𝑓𝑜𝑢𝑛𝑑𝑖𝑛𝑡ℎ𝑒𝑐𝑢𝑟𝑟𝑒𝑛𝑡𝑑𝑖𝑟𝑒𝑐𝑡𝑜𝑟𝑦

(
(pwd))."
exit 1
fi 

### 2. Copy the file to the project root if run from a subdirectory

if [ "(pwd)" != "PROJECT_ROOT" ]; then
echo "📋 Copying $SOURCE_FILE to project root..."
cp "
𝑆𝑂𝑈𝑅𝐶𝐸𝐹𝐼𝐿𝐸

"

"
TARGET_FILE"
fi 

### 3. Git Automation (Only runs if inside a valid Git repo)

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
echo "⚙️  Staging $SOURCE_FILE..."
git -C "
𝑃𝑅𝑂𝐽𝐸𝐶𝑇𝑅𝑂𝑂𝑇

"

𝑎𝑑𝑑

"
SOURCE_FILE" 

echo "📝 Committing changes..."
git -C "$PROJECT_ROOT" commit -m "Automatic handoff update: $(date '+%Y-%m-%d %H:%M:%S')"

echo "🚀 Pushing to remote repository..."
git -C "$PROJECT_ROOT" push

echo "✅ Success! Handoff script execution complete."

else
echo "⏭️  Skipping Git push (Not a valid Git repository)."
fi