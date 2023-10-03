#!/bin/bash

# Set up error handling
set -euo pipefail

# GitHub Action Environment Variable Inputs
PROFILE_FILE="${PROFILE_FILE:-}"
PROFILE_PIN="${PROFILE_PIN:-}"
VPN_MODE="${VPN_MODE:-}"
CLIENT_VERSION="${CLIENT_VERSION:-}"
START_CONNECTION="${START_CONNECTION:-}"

## Other Environent Variables (Optional)
# Wait Established Connection Timeout
CONNECTION_TIMEOUT="${CONNECTION_TIMEOUT:-30}"

# Normalize the VPN mode
VPN_MODE_FAMILY=""
normalize_vpn_mode() {
  VPN_MODE_LOWERCASE=$(echo "$VPN_MODE" | tr '[:upper:]' '[:lower:]')
  case "$VPN_MODE_LOWERCASE" in
    ovpn|openvpn)
      VPN_MODE_FAMILY="ovpn"
      ;;
    wg|wireguard)
      VPN_MODE_FAMILY="wg"
      ;;
    *)
      echo "Invalid VPN mode: $VPN_MODE"
      exit 1
      ;;
  esac
}
normalize_vpn_mode

# Validate version against raw source version file
validate_version() {
  local version="$1"
  local version_pattern="^[0-9]+(\.[0-9]+)+$"
  local pritunl_client_repo="pritunl/pritunl-client-electron"
  local version_file="https://raw.githubusercontent.com/$pritunl_client_repo/master/CHANGES"

  # Validate Client Version Pattern
  if [[ ! "$version" =~ $version_pattern ]]; then
    echo "Invalid version pattern for $version"
    exit 1
  fi

  # Use curl to fetch the raw file and pipe it to grep
  if ! [[ $(curl -sL $version_file | grep -c "$version") -ge 1 ]]; then
    echo "Invalid Version: '$version' does not exist in the '$pritunl_client_repo' CHANGES file."
    exit 1
  fi
}

# Installation process for Linux
install_linux() {
  if [[ "$CLIENT_VERSION" != "from-package-manager" ]]; then
    validate_version "$CLIENT_VERSION"
    echo "Installing Version Specific from GitHub Releases"
    deb_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$CLIENT_VERSION/pritunl-client_$CLIENT_VERSION-0ubuntu1.$(lsb_release -cs)_amd64.deb"
    curl -sL "$deb_url" -o "$RUNNER_TEMP/pritunl-client.deb"
    sudo apt-get --assume-yes install -f "$RUNNER_TEMP/pritunl-client.deb"
  else
    echo "Installing latest from Prebuilt Apt Repository"
    echo "deb https://repo.pritunl.com/stable/apt $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/pritunl.list
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
    gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A | sudo tee /etc/apt/trusted.gpg.d/pritunl.asc
    sudo apt-get --assume-yes update
    sudo apt-get --assume-yes install pritunl-client
  fi

  install_vpn_dependent_packages "Linux"
}

# Installation process for macOS
install_macos() {
  if [[ "$CLIENT_VERSION" != "from-package-manager" ]]; then
    validate_version "$CLIENT_VERSION"
    pkg_zip_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$CLIENT_VERSION/Pritunl.pkg.zip"
    curl -sL "$pkg_zip_url" -o "$RUNNER_TEMP/Pritunl.pkg.zip"
    unzip -qq -o "$RUNNER_TEMP/Pritunl.pkg.zip" -d "$RUNNER_TEMP"
    sudo installer -pkg "$RUNNER_TEMP/Pritunl.pkg" -target /
  else
    brew install --cask pritunl
  fi
  mkdir -p "$HOME/bin" && ln -s "/Applications/Pritunl.app/Contents/Resources/pritunl-client" "$HOME/bin/pritunl-client"

  install_vpn_dependent_packages "macOS"
}

# Installation process for Windows
install_windows() {
  if [[ "$CLIENT_VERSION" != "from-package-manager" ]]; then
    validate_version "$CLIENT_VERSION"
    exe_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$CLIENT_VERSION/Pritunl.exe"
    curl -sL "$exe_url" -o "$RUNNER_TEMP/Pritunl.exe"
    echo "Starting Pritunl installation..."
    pwsh -ExecutionPolicy Bypass -Command "Start-Process -FilePath '$RUNNER_TEMP\Pritunl.exe' -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' -Wait"
    echo "Pritunl installation completed."
  else
    choco install --confirm --no-progress pritunl-client
  fi
  mkdir -p "$HOME/bin" && ln -s "/c/Program Files (x86)/Pritunl/pritunl-client.exe" "$HOME/bin/pritunl-client"

  install_vpn_dependent_packages "Windows"

  if [[ "$VPN_MODE_FAMILY" == "wg" ]]; then
    # Restarting the `pritunl` service to determine the latest changes of the `PATH` values
    # from the `System Environment Variables` during the WireGuard installation is needed.
    pwsh -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock { net stop 'pritunl' ; net start 'pritunl' }"
  fi
}

# Install VPN dependent packages based on OS
install_vpn_dependent_packages() {
  local os_type="$1"
  if [[ "$VPN_MODE_FAMILY" == "wg" ]]; then
    if [[ "$os_type" == "Linux" ]]; then
      sudo apt-get --assume-yes install wireguard-tools
    elif [[ "$os_type" == "macOS" ]]; then
      brew install wireguard-tools
    elif [[ "$os_type" == "Windows" ]]; then
      choco install --confirm --no-progress wireguard
    fi
  else
    if [[ "$os_type" == "Linux" ]]; then
      sudo apt-get --assume-yes install openvpn-systemd-resolved
    fi
  fi
}

# Main installation process based on OS
install_platform() {
  local os_type="$1"
  case "$os_type" in
    Linux)
      install_linux
      ;;
    macOS)
      install_macos
      ;;
    Windows)
      install_windows
      ;;
    *)
      echo "Unsupported OS: $os_type"
      exit 1
      ;;
  esac
}

# Main script execution
if [[ "$RUNNER_OS" == "Linux" || "$RUNNER_OS" == "macOS" || "$RUNNER_OS" == "Windows" ]]; then
  install_platform "$RUNNER_OS"
else
  echo "Unsupported OS: $RUNNER_OS"
  exit 1
fi

# Show Pritunl Client Version
pritunl-client version

# Load Pritunl Profile File
decode_and_add_profile() {
  # Save the `base64` text file format and convert it back to `tar` archive file format.
  echo "$PROFILE_FILE" > "$RUNNER_TEMP/profile-file.base64"
  base64 --decode "$RUNNER_TEMP/profile-file.base64" > "$RUNNER_TEMP/profile-file.tar"

  # Add the Profile File to Pritunl Client
  pritunl-client add "$RUNNER_TEMP/profile-file.tar"

  # Set `client-id` as step output
  client_id=$(
    pritunl-client list |
      awk -F'|' 'NR==4{print $2}' |
      sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
  )
  echo "client-id=$client_id" >> "$GITHUB_OUTPUT"

  # Disable autostart option
  pritunl-client disable "$client_id"
}

# Load the Pritunl Profile File
decode_and_add_profile

if [[ "$START_CONNECTION" == "true" ]]; then

  # Start VPN connection
  start_vpn_connection() {
    local client_id="$1"
    local vpn_flags=()

    if [[ -n "$VPN_MODE_FAMILY" ]]; then
      vpn_flags+=( "--mode" "$VPN_MODE_FAMILY" )
    fi

    if [[ -n "$PROFILE_PIN" ]]; then
      vpn_flags+=( "--password" "$PROFILE_PIN" )
    fi

    pritunl-client start "$client_id" "${vpn_flags[@]}"
  }

  # Start the VPN connection
  start_vpn_connection "$client_id"

  # Waiting for Established Connection
  wait_established_connection() {
    # Define the total number of steps
    local total_steps="${CONNECTION_TIMEOUT}"

    # Initialize the progress variable
    local progress=1

    # Clear the initial line
    echo -n -e "\r\033[K"

    # Loop until the progress reaches the total number of steps
    while [[ "$progress" -le "$total_steps" ]]; do
      if pritunl-client list |
        awk -F '|' 'NR==4{print $8}' |
        sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' |
        grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]{1,2})?$' --quiet --color=never; then
          echo "Connection established..."
          break
      else
        # Calculate the percentage progress
        percentage=$((progress * 100 / total_steps))

        # Calculate the number of completed and remaining characters for the progress bar
        completed=$((percentage / 2))
        remaining=$((50 - completed))

        # Print the connection check progress on the same line
        echo -n -e "Establishing connection: ["
        for ((i = 0; i < completed; i++)); do
            echo -n -e "#"
        done
        for ((i = 0; i < remaining; i++)); do
            echo -n -e "-"
        done
        echo -n -e "] checking $progress out of $total_steps total connection timeout"

        # Increment the progress
        progress=$((progress + 1))

        # Sleep for a moment (simulating work)
        sleep 1

        # Clear the line again for the next update
        echo -n -e "\r\033[K"

        # Print the timeout message and exit error
        if [[ "$progress" -ge "$total_steps" ]]; then
          echo "Timeout reached! Exiting..."
          exit 1
        fi
      fi
    done

    # Print a newline to end the progress loader
    echo ""
  }

  # Waiting for Established Connection
  wait_established_connection

  # Display VPN Connection Status
  display_connection_status() {
    local pritunl_client_info=$(pritunl-client list)
    local profile_name=$(echo "$pritunl_client_info" | awk -F '|' 'NR==4{print $3}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    local profile_ip=$(echo "$pritunl_client_info" | awk -F '|' 'NR==4{print $8}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    echo "Connected as '$profile_name' with a private address of '$profile_ip'."
  }

  # Display VPN Connection Status
  display_connection_status
fi
