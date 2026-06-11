#!/bin/bash

# Target paths (Note: QUARTZ_CONTENT is now relative to this script's folder)
QUARTZ_DIR="$HOME/Documents/quartz"
QUARTZ_CONTENT="$QUARTZ_DIR/content"
VAULT_ASSETS="$HOME/Documents/Obsidian Vault/Assets"

# 1. Copy the markdown note
cp "$1" "$QUARTZ_CONTENT/"

# 2. Extract image names (handling spaces natively) and copy them over
grep -oE '[^\[\|]*\.(png|jpg|jpeg|gif)' "$1" | sed 's/^ *//' | while read -r filename; do
    find "$VAULT_ASSETS" -name "$filename" -exec cp {} "$QUARTZ_CONTENT/assets/" \; 2>/dev/null
done

# 3. Deploy to GitHub Pages
cd "$QUARTZ_DIR" && npx quartz sync --no-pull
