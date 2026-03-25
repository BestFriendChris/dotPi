#!/bin/bash
# Sync all dotfiles and directories from mounted user home directories
# Links files/folders that don't already exist in the agent home

echo "Syncing settings from mounted directories..."

for user_home in /Users/*/; do
    if [ ! -d "$user_home" ]; then continue; fi
    
    username=$(basename "$user_home")
    echo "Found user home: $user_home (user: $username)"
    
    # Link all files and directories from the user home
    for item in "$user_home".*; do
        if [ ! -e "$item" ]; then continue; fi  # Skip if doesn't exist
        
        basename_item=$(basename "$item")
        target="$HOME/$basename_item"
        
        # Skip if target already exists and is not a symlink
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "  Skipping $basename_item (already exists)"
            continue
        fi
        
        # Remove existing symlink if present
        [ -L "$target" ] && rm "$target"
        
        # Create new symlink
        echo "  Linking $basename_item -> $target"
        ln -sf "$item" "$target"
    done
done

echo "Settings sync complete!"
