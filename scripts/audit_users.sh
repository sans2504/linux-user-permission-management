#!/bin/bash

# User Audit Script
# Description: Audit user accounts and permissions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_FILE="/tmp/user_audit_report_$(date +%Y%m%d_%H%M%S).txt"
LOG_FILE="/var/log/user_audit.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to generate audit report
generate_audit_report() {
    {
        echo "USER AUDIT REPORT"
        echo "Generated on: $(date)"
        echo "=========================================="
        
        echo -e "\n1. SYSTEM INFORMATION"
        echo "===================="
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "OS: $(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
        
        echo -e "\n2. USER ACCOUNTS"
        echo "================"
        echo "Total users: $(wc -l < /etc/passwd)"
        echo "Total groups: $(wc -l < /etc/group)"
        
        echo -e "\n3. RECENTLY CREATED USERS (last 30 days)"
        echo "========================================"
        find /home -type d -mtime -30 -exec ls -ld {} \; 2>/dev/null || echo "No recent home directories found"
        
        echo -e "\n4. USERS WITH LOGIN SHELLS"
        echo "=========================="
        grep -v "/nologin\|/false" /etc/passwd | cut -d: -f1,7
        
        echo -e "\n5. USERS WITH UID 0 (ROOT PRIVILEGES)"
        echo "======================================"
        awk -F: '$3 == 0 {print $1}' /etc/passwd
        
        echo -e "\n6. USERS WITHOUT PASSWORD"
        echo "========================="
        awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow
        
        echo -e "\n7. PASSWORD EXPIRY INFORMATION"
        echo "============================="
        for user in $(cut -d: -f1 /etc/passwd); do
            expiry=$(chage -l "$user" 2>/dev/null | grep "Password expires" | cut -d: -f2)
            if [ -n "$expiry" ]; then
                echo "$user: $expiry"
            fi
        done
        
        echo -e "\n8. SUDO PRIVILEGES"
        echo "================="
        grep -r -h "^[^#].*" /etc/sudoers /etc/sudoers.d/* 2>/dev/null || echo "No sudo configurations found"
        
        echo -e "\n9. WORLD-WRITABLE FILES"
        echo "======================="
        find / -type f -perm -0002 ! -path "/proc/*" ! -path "/sys/*" -exec ls -la {} \; 2>/dev/null | head -20
        
        echo -e "\n10. SETUID/SETGID FILES"
        echo "======================"
        find / -type f \( -perm -4000 -o -perm -2000 \) ! -path "/proc/*" ! -path "/sys/*" -exec ls -la {} \; 2>/dev/null | head -20
        
    } > "$REPORT_FILE"
    
    echo "Audit report generated: $REPORT_FILE"
    log "Audit report generated: $REPORT_FILE"
}

# Function to check user login history
check_login_history() {
    local username=$1
    local days=${2:-7}
    
    echo "Login history for $username (last $days days):"
    echo "============================================"
    
    if last -n 100 -s "-${days}days" "$username" 2>/dev/null; then
        echo "No login history found for $username in the last $days days"
    fi
}

# Function to check file permissions
check_file_permissions() {
    local directory=${1:-/etc}
    
    echo "Checking sensitive file permissions in $directory:"
    echo "================================================"
    
    sensitive_files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/gshadow"
        "/etc/sudoers"
        "/etc/ssh/sshd_config"
    )
    
    for file in "${sensitive_files[@]}"; do
        if [ -f "$file" ]; then
            perms=$(stat -c "%a %U:%G" "$file")
            echo "$file: $perms"
        fi
    done
}

# Main function
main() {
    echo "User Audit System"
    echo "================="
    
    generate_audit_report
    
    read -p "Check login history for specific user? (y/n): " check_login
    if [[ $check_login == [yY] ]]; then
        read -p "Enter username: " username
        read -p "Enter number of days to check (default 7): " days
        check_login_history "$username" "$days"
    fi
    
    check_file_permissions "/etc"
    
    echo -e "\nAudit completed. Report saved to: $REPORT_FILE"
    log "User audit completed"
}

# Execute main function
main
