#!/usr/bin/bash

# Exit on any error
set -e

FORCE_REINSTALL=false

# Function to display usage and help
usage() {
    echo "========================================="
    echo "Docker, OpenShift CLI, and VS Code Installer Script"
    echo "========================================="
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --update                  Update and upgrade the system."
    echo "  --create-user <username>  Create a non-root user and add them to the 'docker' and 'sudo' groups."
    echo "                            If no username is provided, it will prompt interactively."
    echo "  --install docker          Install Docker and configure permissions for the current user."
    echo "  --install oc              Install the latest OpenShift CLI (oc)."
    echo "  --install vscode          Install or update Visual Studio Code."
    echo "  --all                     Perform all tasks in sequence (update system, create user, install Docker, OpenShift CLI, and VS Code)."
    echo "  --force                   Force reinstall Docker and OpenShift CLI (oc) even if they are already installed."
    echo "  --help                    Show this help message."
    echo
    echo "========================================="
    echo "Examples:"
    echo
    echo "  1. To update and upgrade the system:"
    echo "      $0 --update"
    echo
    echo "  2. To create a non-root user named 'developer':"
    echo "      $0 --create-user developer"
    echo
    echo "  3. To install Docker:"
    echo "      $0 --install docker"
    echo
    echo "  4. To install the latest OpenShift CLI (oc):"
    echo "      $0 --install oc"
    echo
    echo "  5. To install or update Visual Studio Code:"
    echo "      $0 --install vscode"
    echo
    echo "  6. To force reinstall Docker and OpenShift CLI (oc):"
    echo "      $0 --force --install docker --install oc"
    echo
    echo "  7. To update the system, create a user, and install Docker:"
    echo "      $0 --update --create-user developer --install docker"
    echo
    echo "  8. To perform all tasks (update, create a user, and install all tools):"
    echo "      $0 --all"
    echo
    echo "  9. To install all tools with forced reinstall for Docker and OpenShift CLI:"
    echo "      $0 --all --force"
    echo "========================================="
}


# Function to update and upgrade the system
update_system() {
    echo "Updating and upgrading Ubuntu..."
    echo "Checking for available updates..."
    if sudo apt-get -s upgrade | grep -q 'upgraded,'; then
        echo "Updates are available. Proceeding with update and upgrade..."
        sudo apt update
        sudo apt -y upgrade
    else
        echo "No updates available. Skipping update and upgrade."
    fi
}

# Function to uninstall Docker
uninstall_docker() {
    echo "Uninstalling Docker..."
    sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo apt autoremove -y
    sudo rm -rf /var/lib/docker
    sudo rm -rf /etc/docker
    echo "Docker has been uninstalled."
}

# Function to install Docker
install_docker_logic() {
    echo "Installing prerequisites for Docker..."
    sudo apt install -y ca-certificates curl gnupg lsb-release tar

    echo "Adding Docker's official GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo "Setting up Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "Updating package index and installing Docker..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Verifying Docker installation..."
    if docker --version; then
        echo "Docker installed successfully."
    else
        echo "Docker installation failed."
        exit 1
    fi
}

# Function to enable and start Docker service
enable_docker_service() {
    echo "Enabling and starting Docker service..."
    sudo service docker start
    sudo systemctl enable docker

    TIMEOUT=30
    INTERVAL=2
    ELAPSED=0

    while [ $ELAPSED -lt $TIMEOUT ]; do
        DOCKER_STATUS=$(sudo service docker status)
        if echo "$DOCKER_STATUS" | grep -q "running"; then
            echo "Docker service is running."
            return 0
        fi
        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
    done

    echo "Docker service not running after $TIMEOUT seconds. Exiting."
    return 1
}

# Function to create a new non-root user or verify group membership
create_non_root_user() {
    if [ -z "$1" ]; then
        read -r -p "Enter the username for the non-root user: " NEW_USER
    else
        NEW_USER="$1"
    fi

    if [ -z "$NEW_USER" ]; then
        echo "Error: Username cannot be empty. Please provide a valid username."
        exit 1
    fi

    if id "$NEW_USER" &>/dev/null; then
        echo "User $NEW_USER already exists."
        # Check if the user belongs to the 'docker' group
        if groups "$NEW_USER" | grep -qw "docker"; then
            echo "User $NEW_USER already belongs to the 'docker' group."
        else
            echo "Adding user $NEW_USER to the 'docker' group."
            sudo usermod -aG docker "$NEW_USER"
        fi
        # Check if the user belongs to the 'sudo' group
        if groups "$NEW_USER" | grep -qw "sudo"; then
            echo "User $NEW_USER already belongs to the 'sudo' group."
        else
            echo "Adding user $NEW_USER to the 'sudo' group."
            sudo usermod -aG sudo "$NEW_USER"
        fi
    else
        echo "Creating a new non-root user: $NEW_USER"
        # The adduser command will still prompt for a password unless you disable it.
        # To avoid interactive prompts entirely, you could pass --disabled-password, then set the password via chpasswd.
        sudo adduser --disabled-password --gecos "" "$NEW_USER"

        # Option 1: Hardcode a password (replace 'YourPasswordHere' with your desired password)
        # echo "$NEW_USER:YourPasswordHere" | sudo chpasswd

        # Option 2: Prompt once for the password (hidden input) and then set it
        read -rs -p "Enter password for $NEW_USER: " USER_PASS
        echo
        read -rs -p "Confirm password for $NEW_USER: " USER_PASS_CONFIRM
        echo
        if [ "$USER_PASS" != "$USER_PASS_CONFIRM" ]; then
            echo "Error: Passwords do not match."
            exit 1
        fi
        echo "$NEW_USER:$USER_PASS" | sudo chpasswd

        echo "Adding $NEW_USER to the 'docker' and 'sudo' groups."
        sudo usermod -aG docker "$NEW_USER"
        sudo usermod -aG sudo "$NEW_USER"
    fi
}

# Function to check and optionally reinstall Docker
install_docker() {
    DOCKER_INSTALLED=$(command -v docker &>/dev/null && echo true || echo false)
    if [ "$DOCKER_INSTALLED" = true ]; then
        echo "Docker is already installed."
        if [ "$FORCE_REINSTALL" = true ]; then
            echo "Force reinstall is enabled. Reinstalling Docker..."
            uninstall_docker
            install_docker_logic
            enable_docker_service
            create_non_root_user
        fi
    else
        echo "Docker is not installed. Proceeding with installation..."
        install_docker_logic
        enable_docker_service
        create_non_root_user
    fi
}

# Function to install or reinstall the latest OpenShift CLI (oc)
install_openshift_cli() {
    if command -v oc &>/dev/null && [ "$FORCE_REINSTALL" = false ]; then
        echo "OpenShift CLI (oc) is already installed. Skipping installation."
    else
        echo "Installing or reinstalling OpenShift CLI (oc)..."
        HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/)
        if [ "$HTTP_STATUS" -ne 200 ]; then
            echo "Failed to fetch the latest OpenShift CLI URL. HTTP status code: $HTTP_STATUS. Exiting."
            exit 1
        fi

        OC_PAGE_CONTENT=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/)
        OC_LATEST_URL=$(echo "$OC_PAGE_CONTENT" | grep -o 'href="openshift-client-linux-.*\.tar\.gz"' | head -n 1 | cut -d '"' -f 2)
        OC_DOWNLOAD_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/$OC_LATEST_URL"

        if [ -z "$OC_LATEST_URL" ]; then
            echo "Failed to fetch the latest OpenShift CLI URL. Exiting."
            exit 1
        fi

        echo "Downloading from $OC_DOWNLOAD_URL"
        curl -LO "$OC_DOWNLOAD_URL"

        echo "Extracting OpenShift CLI..."
        tar -xzf $(basename "$OC_DOWNLOAD_URL")

        echo "Moving oc binary to /usr/local/bin..."
        sudo mv oc /usr/local/bin/
        sudo chmod +x /usr/local/bin/oc


        echo "Verifying oc installation..."
        oc version --client || { echo "Failed to verify OpenShift CLI installation."; exit 1; }

        rm -f $(basename "$OC_LATEST_URL") kubectl

        echo "Verifying oc installation..."
        oc version --client || { echo "Failed to verify OpenShift CLI installation."; exit 1; }
    fi
}

# Function to install or update Visual Studio Code
install_vscode() {
    echo "Checking for existing Visual Studio Code installation..."
    if command -v code >/dev/null 2>&1; then
        echo "Visual Studio Code is already installed. Checking for updates..."
        # Update package lists and upgrade VS Code
        sudo apt update
        sudo apt install --only-upgrade -y code
        echo "Visual Studio Code has been updated to the latest version."
    else
        echo "Visual Studio Code is not installed. Installing..."
        # Import the Microsoft GPG key
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
        # Add the VS Code repository
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        # Update package lists and install VS Code
        sudo apt update
        sudo apt install -y code
        # Clean up
        rm -f packages.microsoft.gpg
        echo "Visual Studio Code installation completed."
    fi
}

# Function to perform all tasks
perform_all_tasks() {
    update_system
    install_docker
    create_non_root_user
    install_openshift_cli
    install_vscode
}


if [ "$#" -eq 0 ]; then
    usage
fi

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --force) FORCE_REINSTALL=true; shift ;;
        --update) update_system; shift ;;
        --create-user)
            if [ -n "$2" ]; then
                create_non_root_user "$2"
                shift 2
            else
                echo "Error: --create-user requires a username."
                exit 1
            fi
            ;;
        --install)
                if [ -n "$2" ]; then
                    case "$2" in
                        docker) install_docker ;;
                        oc) install_openshift_cli ;;
                        vscode) install_vscode ;;
                        *) echo "Invalid option for --install. Use 'docker', 'oc', or 'vscode'." ;;
                    esac
                    shift 2
                else
                    echo "Error: --install requires an argument ('docker', 'oc', or 'vscode')."
                    exit 1
                fi
                ;;
        --all) perform_all_tasks; shift ;;
        --help) usage; shift ;;
        *) echo "Invalid option. Use --help to see the usage."; usage; exit 1 ;;
    esac
done