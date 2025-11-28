# Linux User Management Guide

## Overview
This guide covers user and permission management in Red Hat Linux systems.

## User Management Commands

### Creating Users
```bash
# Basic user creation
useradd username

# User with specific home directory
useradd -m -d /home/username username

# User with specific shell
useradd -s /bin/bash username

# User with specific UID
useradd -u 1001 username
