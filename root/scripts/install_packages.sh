#!/bin/bash

echo "########################################"
echo "[INFO] Installing packages..."
echo "########################################"

[ -n "${DEBUG}" ] && set -euxo pipefail

# Function to install apt packages
install_apt_packages() {
    local packages_file="$1"
    
    if [ ! -f "$packages_file" ]; then
        echo "Error: $packages_file not found"
        return 1
    fi

    echo "Updating apt cache..."
    apt-get $( [ -z "${DEBUG}" ] && echo "-qq" ) update

    while IFS= read -r package || [ -n "$package" ]; do
        # Skip lines that start with '#'
        [[ "$package" =~ ^#.*$ ]] || [[ -z "$repo_url" ]] && continue
        if [ -n "$package" ]; then
            echo "Installing apt package: $package..."
            apt-get install -y $( [ -z "${DEBUG}" ] && echo "-qq" ) "$package"
            if [ $? -eq 0 ]; then
                echo "$package installed successfully"
            else
                echo "Failed to install $package"
            fi
        fi
    done < "$packages_file"

    echo "Cleaning apt cache..."
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

# Function to install pip packages
install_pip_packages() {
    local packages_file="$1"
    
    if [ ! -f "$packages_file" ]; then
        echo "Error: $packages_file not found"
        return 1
    fi

    # Ensure pip is installed
    if ! command -v pip &> /dev/null; then
        echo "pip not found. Installing pip..."
        apt-get update && apt-get install -y $( [ -z "${DEBUG}" ] && echo "-qq" ) python3-pip
    fi

    while IFS= read -r package || [ -n "$package" ]; do
        if [ -n "$package" ]; then
            echo "Installing pip package: $package..."
            pip install $( [ -z "${DEBUG}" ] && echo "-q" ) "$package"
            if [ $? -eq 0 ]; then
                echo "$package installed successfully"
            else
                echo "Failed to install $package"
            fi
        fi
    done < "$packages_file"
}

# Main script execution
APT_PACKAGES_FILE="/config/packages_system.txt"
PIP_PACKAGES_FILE="/config/packages_pip.txt"

if [ -f "$APT_PACKAGES_FILE" ]; then
    echo "Installing apt packages..."
    install_apt_packages "$APT_PACKAGES_FILE"
fi

if [ -f "$PIP_PACKAGES_FILE" ]; then
    echo "Installing pip packages..."
    install_pip_packages "$PIP_PACKAGES_FILE"
fi

if [ -f "scripts/requirements.txt" ]; then
    pip install $( [ -z "${DEBUG}" ] && echo "-q" ) -r /config/requirements.txt
fi

echo "All installations completed"
