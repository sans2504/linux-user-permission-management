#!/bin/bash

# Linux Group Management Script
# Description: Manage groups and group memberships

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/group_management.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to create a group
create_group() {
    local groupname=$1
    
    if grep -q "^$groupname:" /etc/group; then
        echo "Error: Group $groupname already exists."
        log "Failed to create group: $groupname already exists"
        return 1
    fi
    
    groupadd "$groupname"
    
    if [ $? -eq 0 ]; then
        echo "Group $groupname created successfully."
        log "Group created: $groupname"
    else
        echo "Error: Failed to create group $groupname"
        log "Failed to create group: $groupname"
        return 1
    fi
}

# Function to delete a group
delete_group() {
    local groupname=$1
    
    if ! grep -q "^$groupname:" /etc/group; then
        echo "Error: Group $groupname does not exist."
        log "Failed to delete group: $groupname does not exist"
        return 1
    fi
    
    read -p "Are you sure you want to delete group $groupname? (y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        groupdel "$groupname"
        if [ $? -eq 0 ]; then
            echo "Group $groupname deleted successfully."
            log "Group deleted: $groupname"
        else
            echo "Error: Failed to delete group $groupname (may have users)"
            log "Failed to delete group: $groupname"
        fi
    else
        echo "Group deletion cancelled."
    fi
}

# Function to add user to group
add_user_to_group() {
    local username=$1
    local groupname=$2
    
    if ! id "$username" &>/dev/null; then
        echo "Error: User $username does not exist."
        return 1
    fi
    
    if ! grep -q "^$groupname:" /etc/group; then
        echo "Error: Group $groupname does not exist."
        return 1
    fi
    
    usermod -aG "$groupname" "$username"
    
    if [ $? -eq 0 ]; then
        echo "User $username added to group $groupname successfully."
        log "User $username added to group $groupname"
    else
        echo "Error: Failed to add user to group"
        log "Failed to add user $username to group $groupname"
    fi
}

# Function to remove user from group
remove_user_from_group() {
    local username=$1
    local groupname=$2
    
    if ! id "$username" &>/dev/null; then
        echo "Error: User $username does not exist."
        return 1
    fi
    
    if ! grep -q "^$groupname:" /etc/group; then
        echo "Error: Group $groupname does not exist."
        return 1
    fi
    
    gpasswd -d "$username" "$groupname"
    
    if [ $? -eq 0 ]; then
        echo "User $username removed from group $groupname successfully."
        log "User $username removed from group $groupname"
    else
        echo "Error: Failed to remove user from group"
        log "Failed to remove user $username from group $groupname"
    fi
}

# Function to list groups
list_groups() {
    echo "System Groups:"
    echo "=============="
    cut -d: -f1 /etc/group | sort
}

# Function to show group members
show_group_members() {
    local groupname=$1
    
    if ! grep -q "^$groupname:" /etc/group; then
        echo "Error: Group $groupname does not exist."
        return 1
    fi
    
    echo "Members of group $groupname:"
    grep "^$groupname:" /etc/group | cut -d: -f4
}

# Main menu
main_menu() {
    while true; do
        echo ""
        echo "Linux Group Management System"
        echo "============================"
        echo "1) Create Group"
        echo "2) Delete Group"
        echo "3) Add User to Group"
        echo "4) Remove User from Group"
        echo "5) List Groups"
        echo "6) Show Group Members"
        echo "7) Exit"
        echo ""
        read -p "Select an option [1-7]: " choice
        
        case $choice in
            1)
                read -p "Enter group name: " groupname
                create_group "$groupname"
                ;;
            2)
                read -p "Enter group name to delete: " groupname
                delete_group "$groupname"
                ;;
            3)
                read -p "Enter username: " username
                read -p "Enter group name: " groupname
                add_user_to_group "$username" "$groupname"
                ;;
            4)
                read -p "Enter username: " username
                read -p "Enter group name: " groupname
                remove_user_from_group "$username" "$groupname"
                ;;
            5)
                list_groups
                ;;
            6)
                read -p "Enter group name: " groupname
                show_group_members "$groupname"
                ;;
            7)
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
