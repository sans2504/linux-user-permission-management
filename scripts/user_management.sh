#!/bin/bash

# Linux User Management Script
# Description: Create, modify, and manage user accounts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/default_settings.conf"
LOG_FILE="/var/log/user_management.log"

# Source configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    DEFAULT_HOME="/home"
    DEFAULT_SHELL="/bin/bash"
    DEFAULT_PASSWORD_EXPIRY=90
fi

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to create a user
create_user() {
    local username=$1
    local password=$2
    local groups=$3
    
    if id "$username" &>/dev/null; then
        echo "Error: User $username already exists."
        log "Failed to create user: $username already exists"
        return 1
    fi
    
    # Create user with home directory
    useradd -m -d "$DEFAULT_HOME/$username" -s "$DEFAULT_SHELL" "$username"
    
    if [ $? -eq 0 ]; then
        # Set password
        echo "$username:$password" | chpasswd
        
        # Add to additional groups if specified
        if [ -n "$groups" ]; then
            usermod -aG "$groups" "$username"
        fi
        
        # Set password expiry
        chage -M "$DEFAULT_PASSWORD_EXPIRY" "$username"
        
        echo "User $username created successfully."
        log "User created: $username"
        
        # Display user information
        echo "User Information:"
        id "$username"
        echo "Home Directory: $DEFAULT_HOME/$username"
    else
        echo "Error: Failed to create user $username"
        log "Failed to create user: $username"
        return 1
    fi
}

# Function to delete a user
delete_user() {
    local username=$1
    local remove_home=$2
    
    if ! id "$username" &>/dev/null; then
        echo "Error: User $username does not exist."
        log "Failed to delete user: $username does not exist"
        return 1
    fi
    
    read -p "Are you sure you want to delete user $username? (y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        if [ "$remove_home" == "true" ]; then
            userdel -r "$username"
            echo "User $username and home directory deleted."
            log "User deleted with home directory: $username"
        else
            userdel "$username"
            echo "User $username deleted (home directory preserved)."
            log "User deleted: $username"
        fi
    else
        echo "User deletion cancelled."
    fi
}

# Function to modify user
modify_user() {
    local username=$1
    local option=$2
    local value=$3
    
    if ! id "$username" &>/dev/null; then
        echo "Error: User $username does not exist."
        return 1
    fi
    
    case $option in
        "shell")
            usermod -s "$value" "$username"
            echo "Shell for $username changed to $value"
            log "User $username shell changed to $value"
            ;;
        "home")
            usermod -d "$value" -m "$username"
            echo "Home directory for $username changed to $value"
            log "User $username home directory changed to $value"
            ;;
        "expiry")
            chage -M "$value" "$username"
            echo "Password expiry for $username set to $value days"
            log "User $username password expiry set to $value days"
            ;;
        "lock")
            usermod -L "$username"
            echo "User $username account locked"
            log "User $username account locked"
            ;;
        "unlock")
            usermod -U "$username"
            echo "User $username account unlocked"
            log "User $username account unlocked"
            ;;
        *)
            echo "Invalid modification option"
            ;;
    esac
}

# Function to list all users
list_users() {
    echo "System Users:"
    echo "============="
    cut -d: -f1 /etc/passwd | sort
    
    echo -e "\nUser Details:"
    echo "============="
    while IFS=: read -r username _ uid gid desc home shell; do
        if [ $uid -ge 1000 ] && [ $uid -le 60000 ]; then
            echo "User: $username, UID: $uid, GID: $gid, Home: $home, Shell: $shell"
        fi
    done < /etc/passwd
}

# Main menu
main_menu() {
    while true; do
        echo ""
        echo "Linux User Management System"
        echo "============================"
        echo "1) Create User"
        echo "2) Delete User"
        echo "3) Modify User"
        echo "4) List Users"
        echo "5) Exit"
        echo ""
        read -p "Select an option [1-5]: " choice
        
        case $choice in
            1)
                read -p "Enter username: " username
                read -s -p "Enter password: " password
                echo
                read -p "Enter additional groups (comma separated, optional): " groups
                create_user "$username" "$password" "$groups"
                ;;
            2)
                read -p "Enter username to delete: " username
                read -p "Remove home directory? (true/false): " remove_home
                delete_user "$username" "$remove_home"
                ;;
            3)
                read -p "Enter username to modify: " username
                echo "Modification options: shell, home, expiry, lock, unlock"
                read -p "Enter option: " option
                read -p "Enter value: " value
                modify_user "$username" "$option" "$value"
                ;;
            4)
                list_users
                ;;
            5)
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
