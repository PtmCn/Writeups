#!/bin/bash

# Target paths
QUARTZ_DIR="$HOME/Documents/quartz"
QUARTZ_CONTENT="$QUARTZ_DIR/content"
VAULT_ASSETS="$HOME/Documents/Obsidian Vault/Assets"

# 1. Detect your private vault root automatically from the active note path
# This looks for "Obsidian Vault/" to safely split the directory path
VAULT_ROOT=$(echo "$1" | grep -o '.*Obsidian Vault/')

# 2. Calculate the relative subfolder path (e.g., "PG_Play", "PG_Practice", or "OSCP")
RELATIVE_FOLDER=$(dirname "${1#$VAULT_ROOT}")

# 3. Dynamically create the matching folder structure inside Quartz content folder
mkdir -p "$QUARTZ_CONTENT/$RELATIVE_FOLDER"

# 4. Copy the markdown note into its designated directory instead of flat root
cp "$1" "$QUARTZ_CONTENT/$RELATIVE_FOLDER/"

# 5. Extract image names (handling spaces natively) and copy them over
grep -oE '[^\[\|]*\.(png|jpg|jpeg|gif)' "$1" | sed 's/^ *//' | while read -r filename; do
    find "$VAULT_ASSETS" -name "$filename" -exec cp {} "$QUARTZ_CONTENT/assets/" \; 2>/dev/null
done

# 6. Deploy to GitHub Pages
cd "$QUARTZ_DIR" && npx quartz sync --no-pull
