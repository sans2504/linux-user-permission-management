#!/bin/bash

# Linux Permission Management Script
# Description: Manage file and directory permissions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/permission_manager.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to set permissions
set_permissions() {
    local path=$1
    local permissions=$2
    local recursive=$3
    
    if [ ! -e "$path" ]; then
        echo "Error: Path $path does not exist."
        log "Failed to set permissions: $path does not exist"
        return 1
    fi
    
    if [ "$recursive" == "true" ]; then
        chmod -R "$permissions" "$path"
        echo "Permissions set to $permissions recursively on $path"
        log "Permissions set to $permissions recursively on $path"
    else
        chmod "$permissions" "$path"
        echo "Permissions set to $permissions on $path"
        log "Permissions set to $permissions on $path"
    fi
}

# Function to set ownership
set_ownership() {
    local path=$1
    local owner=$2
    local group=$3
    local recursive=$4
    
    if [ ! -e "$path" ]; then
        echo "Error: Path $path does not exist."
        log "Failed to set ownership: $path does not exist"
        return 1
    fi
    
    if [ -n "$group" ]; then
        ownership="$owner:$group"
    else
        ownership="$owner"
    fi
    
    if [ "$recursive" == "true" ]; then
        chown -R "$ownership" "$path"
        echo "Ownership set to $ownership recursively on $path"
        log "Ownership set to $ownership recursively on $path"
    else
        chown "$ownership" "$path"
        echo "Ownership set to $ownership on $path"
        log "Ownership set to $ownership on $path"
    fi
}

# Function to check permissions
check_permissions() {
    local path=$1
    
    if [ ! -e "$path" ]; then
        echo "Error: Path $path does not exist."
        return 1
    fi
    
    echo "Permissions for: $path"
    echo "===================="
    ls -la "$path" | head -2
    
    if [ -d "$path" ]; then
        echo -e "\nDirectory Contents:"
        echo "==================="
        ls -la "$path"
    fi
}

# Function to set special permissions
set_special_permissions() {
    local path=$1
    local type=$2
    
    case $type in
        "setuid")
            chmod u+s "$path"
            echo "SetUID bit set on $path"
            log "SetUID bit set on $path"
            ;;
        "setgid")
            chmod g+s "$path"
            echo "SetGID bit set on $path"
            log "SetGID bit set on $path"
            ;;
        "sticky")
            chmod +t "$path"
            echo "Sticky bit set on $path"
            log "Sticky bit set on $path"
            ;;
        *)
            echo "Invalid special permission type"
            ;;
    esac
}

# Function to reset permissions to default
reset_permissions() {
    local path=$1
    local recursive=$2
    
    if [ ! -e "$path" ]; then
        echo "Error: Path $path does not exist."
        return 1
    fi
    
    # Default permissions: 644 for files, 755 for directories
    if [ -d "$path" ]; then
        if [ "$recursive" == "true" ]; then
            find "$path" -type d -exec chmod 755 {} \;
            find "$path" -type f -exec chmod 644 {} \;
            echo "Default permissions set recursively on directory $path"
            log "Default permissions set recursively on directory $path"
        else
            chmod 755 "$path"
            echo "Default permissions set on directory $path"
            log "Default permissions set on directory $path"
        fi
    else
        chmod 644 "$path"
        echo "Default permissions set on file $path"
        log "Default permissions set on file $path"
    fi
}

# Main menu
main_menu() {
    while true; do
        echo ""
        echo "Linux Permission Management System"
        echo "================================="
        echo "1) Set Permissions"
        echo "2) Set Ownership"
        echo "3) Check Permissions"
        echo "4) Set Special Permissions"
        echo "5) Reset to Default Permissions"
        echo "6) Exit"
        echo ""
        read -p "Select an option [1-6]: " choice
        
        case $choice in
            1)
                read -p "Enter path: " path
                read -p "Enter permissions (e.g., 755, 644): " permissions
                read -p "Apply recursively? (true/false): " recursive
                set_permissions "$path" "$permissions" "$recursive"
                ;;
            2)
                read -p "Enter path: " path
                read -p "Enter owner: " owner
                read -p "Enter group (optional): " group
                read -p "Apply recursively? (true/false): " recursive
                set_ownership "$path" "$owner" "$group" "$recursive"
                ;;
            3)
                read -p "Enter path: " path
                check_permissions "$path"
                ;;
            4)
                read -p "Enter path: " path
                echo "Special permissions: setuid, setgid, sticky"
                read -p "Enter permission type: " perm_type
                set_special_permissions "$path" "$perm_type"
                ;;
            5)
                read -p "Enter path: " path
                read -p "Apply recursively? (true/false): " recursive
                reset_permissions "$path" "$recursive"
                ;;
            6)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    done
}

# Check if script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or using sudo"
    exit 1
fi

# Execute main menu if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_menu
fi
