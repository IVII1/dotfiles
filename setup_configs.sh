#!/bin/bash
# This script creates symlinks from the home directory to the configuration files in this repo.

set -e

# Get the absolute path of the script's directory
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"

# --- Main Function ---

setup_dotfiles() {
    echo "Creating backup directory for existing dotfiles at: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    # Directories whose CONTENTS will be symlinked.
    # This handles cases like .config where you only version control specific subfolders.
    dirs_to_symlink_contents=(".config" ".local/share/applications")

    for dir in "${dirs_to_symlink_contents[@]}"; do
        local source_dir="$DIR/$dir"
        local target_dir="$HOME/$dir"

        if [ ! -d "$source_dir" ]; then
            echo "WARNING: Source directory '$source_dir' not found, skipping."
            continue
        fi

        echo "Processing contents of '$dir'..."
        # Ensure the target directory exists (e.g., ~/.config)
        mkdir -p "$target_dir"

        # Loop over all items in the source directory (e.g., 'hypr' in .config, or 'Claude.desktop' in .local/share/applications)
        for source_item_path in "$source_dir"/*; do
            local item_name=$(basename "$source_item_path")
            local target_item_path="$target_dir/$item_name"

            # If the item from dotfiles is a DIRECTORY (like 'hypr')
            if [ -d "$source_item_path" ]; then
                echo "  Processing config directory: '$item_name'"
                # Ensure the target subdirectory exists (e.g., ~/.config/hypr)
                mkdir -p "$target_item_path"

                # Loop over the files INSIDE this directory
                for source_file_path in "$source_item_path"/*; do
                    local file_name=$(basename "$source_file_path")
                    local target_file_path="$target_item_path/$file_name"

                    # Backup existing file if it exists
                    if [ -e "$target_file_path" ] || [ -L "$target_file_path" ]; then
                        echo "    -> Backing up existing '$target_file_path'"
                        mkdir -p "$BACKUP_DIR/$dir/$item_name"
                        mv "$target_file_path" "$BACKUP_DIR/$dir/$item_name/"
                    fi

                    echo "    -> Creating symlink: $target_file_path -> $source_file_path"
                    ln -s "$source_file_path" "$target_file_path"
                done
            # If the item from dotfiles is a FILE (like 'Claude.desktop')
            elif [ -f "$source_item_path" ]; then
                echo "  Processing config file: '$item_name'"
                # Backup existing file if it exists
                if [ -e "$target_item_path" ] || [ -L "$target_item_path" ]; then
                    echo "    -> Backing up existing '$target_item_path'"
                    mkdir -p "$BACKUP_DIR/$dir"
                    mv "$target_item_path" "$BACKUP_DIR/$dir/"
                fi

                echo "    -> Creating symlink: $target_item_path -> $source_item_path"
                ln -s "$source_item_path" "$target_item_path"
            fi
        done
    done

    # Individual files/folders to symlink directly in the home directory
    files_to_link=(".env")
    for item in "${files_to_link[@]}"; do
        local source_path="$DIR/$item"
        local target_path="$HOME/$item"

        if [ ! -e "$source_path" ]; then
            echo "WARNING: '$source_path' not found, skipping."
            continue
        fi

        if [ -e "$target_path" ] || [ -L "$target_path" ]; then
            echo "Backing up existing '$target_path' to '$BACKUP_DIR'"
            mv "$target_path" "$BACKUP_DIR/"
        fi

        echo "Creating symlink for '$item' -> '$target_path'"
        ln -s "$source_path" "$target_path"
    done

    echo "✅ Dotfiles setup complete."
    echo "NOTE: You may need to log out and log back in for all changes to take effect."
}

# --- Main Script Logic ---

# Check for a command-line argument
if [ "$1" == "--setup" ]; then
    setup_dotfiles
else
    echo "Usage: $0 --setup"
    echo "  --setup: Creates symlinks for your configuration files."
    exit 1
fi
