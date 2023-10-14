#!/usr/bin/env bash

# Set up error handling
set -euo pipefail

## GitHub Action Inputs as Environment Variables
PRITUNL_PROFILE_FILE="${PRITUNL_PROFILE_FILE:-}"
PRITUNL_PROFILE_PIN="${PRITUNL_PROFILE_PIN:-}"
PRITUNL_PROFILE_SERVER="${PRITUNL_PROFILE_SERVER:-}"
PRITUNL_VPN_MODE="${PRITUNL_VPN_MODE:-}"
PRITUNL_CLIENT_VERSION="${PRITUNL_CLIENT_VERSION:-}"
PRITUNL_START_CONNECTION="${PRITUNL_START_CONNECTION:-}"

## GitHub Action Setup and Checks Environent Variables
PRITUNL_READY_PROFILE_TIMEOUT="${PRITUNL_READY_PROFILE_TIMEOUT:-}"
PRITUNL_ESTABLISHED_CONNECTION_TIMEOUT="${PRITUNL_ESTABLISHED_CONNECTION_TIMEOUT:-}"

# Normalize the VPN mode
normalize_vpn_mode() {
  case "$(echo "$PRITUNL_VPN_MODE" | tr '[:upper:]' '[:lower:]')" in
    ovpn|openvpn)
      PRITUNL_VPN_MODE="ovpn"
      ;;
    wg|wireguard)
      PRITUNL_VPN_MODE="wg"
      ;;
    *)
      echo "Invalid VPN mode for '$PRITUNL_VPN_MODE'!" && exit 1
      ;;
  esac
}

# Validate version against raw source version file
validate_version() {
  local version="$1"
  local pritunl_client_repo="pritunl/pritunl-client-electron" # Link: https://github.com/pritunl/pritunl-client-electron
  local version_file="https://raw.githubusercontent.com/$pritunl_client_repo/master/CHANGES"

  # Validate Client Version Pattern
  if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    echo "Invalid version pattern for '$version'!" && exit 1
  fi

  # Use curl to fetch the raw file and pipe it to grep
  if ! [[ $(curl --silent --show-error --location $version_file | grep --count "$version") -ge 1 ]]; then
    echo "Version '$version' does not exist in the '$pritunl_client_repo' source!" && exit 1
  fi
}

# Installation process for Linux
install_linux() {
  if [[ "$PRITUNL_CLIENT_VERSION" == "from-package-manager" ]]; then
    # Installing using Pritunl Prebuilt Apt Repository
    echo "deb https://repo.pritunl.com/stable/apt $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/pritunl.list
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A > /dev/null 2>&1
    gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A | sudo tee /etc/apt/trusted.gpg.d/pritunl.asc > /dev/null
    sudo apt-get update -qq -y
    sudo apt-get install -qq -y pritunl-client
  else
    # Installing Version Specific using Debian Package from Pritunl GitHub Releases
    validate_version "$PRITUNL_CLIENT_VERSION"
    deb_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$PRITUNL_CLIENT_VERSION/pritunl-client_$PRITUNL_CLIENT_VERSION-0ubuntu1.$(lsb_release -cs)_amd64.deb"
    curl -sSL "$deb_url" -o "$RUNNER_TEMP/pritunl-client.deb"
    sudo apt-get install -qq -y -f "$RUNNER_TEMP/pritunl-client.deb"
  fi

  install_vpn_dependencies "Linux"
}

# Installation process for macOS
install_macos() {
  local pritunl_client_bin
  local user_bin_directory

  if [[ "$PRITUNL_CLIENT_VERSION" == "from-package-manager" ]]; then
    # Installing using Homebrew Package Manager for macOS
    brew install -q --cask pritunl
  else
    # Installing Version Specific using macOS Package from Pritunl GitHub Releases
    validate_version "$PRITUNL_CLIENT_VERSION"
    pkg_zip_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$PRITUNL_CLIENT_VERSION/Pritunl.pkg.zip"
    curl -sSL "$pkg_zip_url" --output "$RUNNER_TEMP/Pritunl.pkg.zip"
    unzip -qq -o "$RUNNER_TEMP/Pritunl.pkg.zip" -d "$RUNNER_TEMP"
    sudo installer -pkg "$RUNNER_TEMP/Pritunl.pkg" -target /
  fi

  pritunl_client_bin="/Applications/Pritunl.app/Contents/Resources/pritunl-client"
  user_bin_directory="$HOME/bin/"

  if [ -e "$pritunl_client_bin" ]; then
    if ! [[ -d "$HOME/bin" ]]; then
      mkdir -p "$user_bin_directory"
    fi
    ln -s "$pritunl_client_bin" "$user_bin_directory"
  else
    echo "Pritunl client installation failed!" && exit 1
  fi

  install_vpn_dependencies "macOS"
}

# Installation process for Windows
install_windows() {
  local pritunl_client_bin
  local user_bin_directory

  if [[ "$PRITUNL_CLIENT_VERSION" == "from-package-manager" ]]; then
    # Installing using Choco Package Manager for Windows
    choco install --no-progress -y pritunl-client
  else
    # Install Version Specific using Windows Package from Pritunl GitHub Releases
    validate_version "$PRITUNL_CLIENT_VERSION"
    exe_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$PRITUNL_CLIENT_VERSION/Pritunl.exe"
    curl -sSL "$exe_url" --output "$RUNNER_TEMP/Pritunl.exe"
    pwsh -ExecutionPolicy Bypass -Command "Start-Process -FilePath '$RUNNER_TEMP\Pritunl.exe' -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' -Wait"
  fi

  pritunl_client_bin="/c/Program Files (x86)/Pritunl/pritunl-client.exe"
  user_bin_directory="$HOME/bin/"

  if [ -e "$pritunl_client_bin" ]; then
    if ! [[ -d "$HOME/bin" ]]; then
      mkdir -p "$user_bin_directory"
    fi
    ln -s "$pritunl_client_bin" "$user_bin_directory"
  else
    echo "Pritunl client installation failed!" && exit 1
  fi

  install_vpn_dependencies "Windows"

  if [[ "$PRITUNL_VPN_MODE" == "wg" ]]; then
    # Restart the `pritunl` service to obtain the latest `PATH` values from the `System Environment Variables` during the WireGuard installation.
    pwsh -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock { net stop 'pritunl' ; net start 'pritunl' }"
  fi
}

# Install VPN dependent packages based on OS
install_vpn_dependencies() {
  local os_type="$1"
  if [[ "$PRITUNL_VPN_MODE" == "wg" ]]; then
    if [[ "$os_type" == "Linux" ]]; then
      sudo apt-get install -qq -y wireguard-tools
    elif [[ "$os_type" == "macOS" ]]; then
      brew install -q wireguard-tools
    elif [[ "$os_type" == "Windows" ]]; then
      choco install --no-progress -y wireguard
    fi
  else
    if [[ "$os_type" == "Linux" ]]; then
      sudo apt-get install -qq -y openvpn-systemd-resolved
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
      echo "Unsupported OS: $os_type" && exit 1
      ;;
  esac

  # Show the Pritunl Client version
  pritunl-client version
}

# Function to print a progress bar
display_progress_bar() {
  local current_step="$1"   # Current step in the process
  local total_steps="$2"    # Total steps in the process
  local message="$3"        # Message to display with the progress bar

  # Calculate the percentage progress
  local percentage=$((current_step * 100 / total_steps))

  # Calculate the number of completed and remaining characters for the progress bar
  local completed=$((percentage / 2))
  local remaining=$((50 - completed))

  # Print the progress bar
  echo -n -e "$message: ["
  for ((i = 0; i < completed; i++)); do
    echo -n -e "#"
  done
  for ((i = 0; i < remaining; i++)); do
    echo -n -e "-"
  done
  echo -n -e "] checking $current_step out of $total_steps allowed checks."

  # Print new line
  echo -n -e "\n"
}

# Get the Profile Server
get_profile_server() {
  local profile_list_json
  local profile_server_json

  profile_list_json=$(
    pritunl-client list --json
  )

  if [[ -n "$PRITUNL_PROFILE_SERVER" ]]; then
    profile_server_json=$(
      echo "$profile_list_json" |
        jq ".[] | select(.name | contains(\"$PRITUNL_PROFILE_SERVER\"))"
    )

    if [[ -n "$profile_server_json" ]]; then
      echo "$profile_server_json"
    else
      echo "Profile not exist!" && exit 1
    fi
  else
    echo "$profile_list_json" |
      jq ".[0]"
  fi
}

# Function to decode and add a profile
setup_profile_file() {
  # Define the total number of steps and initialize the current step variable
  local total_steps="${PRITUNL_READY_PROFILE_TIMEOUT}"
  local current_step=0

  # Define Profile Server Information
  local profile_server
  local profile_name

  # Save the `base64` text file format and convert it back to `tar` archive file format.
  echo "$PRITUNL_PROFILE_FILE" > "$RUNNER_TEMP/profile-file.base64"
  base64 --decode "$RUNNER_TEMP/profile-file.base64" > "$RUNNER_TEMP/profile-file.tar"

  # Add the Profile File to Pritunl Client
  pritunl-client add "$RUNNER_TEMP/profile-file.tar"

  # Loop until the current step reaches the total number of steps
  while [[ "$current_step" -le "$total_steps" ]]; do

    profile_server=$(get_profile_server)
    profile_name=$(echo $profile_server | jq -r ".name")
    client_id=$(echo $profile_server | jq -r ".id")

    if [[ "$client_id" =~ ^[a-z0-9]{16}$ ]]; then
      # Set `client-id` as step output
      echo "client-id=$client_id" >> "$GITHUB_OUTPUT"
      # Display the profile client id.
      echo "Profile '$profile_name' is set with client id '$client_id'."
      # Break the loop
      break
    else
      # Increment the current step
      current_step=$((current_step + 1))

      # Print the attempt progress using the progress bar function
      display_progress_bar "$current_step" "$total_steps" "Ready profile"

      # Sleep for a moment (simulating work)
      sleep 1

      # Print the timeout message and exit error if needed
      if [[ "$current_step" -eq "$total_steps" ]]; then
        echo "Profile setup failed, the client id not found!" && exit 1
      fi
    fi
  done
}


# Start VPN connection
start_vpn_connection() {
  local client_id="$1"
  local vpn_flags=()

  if [[ -n "$PRITUNL_VPN_MODE" ]]; then
    vpn_flags+=( "--mode" "$PRITUNL_VPN_MODE" )
  fi

  if [[ -n "$PRITUNL_PROFILE_PIN" ]]; then
    vpn_flags+=( "--password" "$PRITUNL_PROFILE_PIN" )
  fi

  pritunl-client start "$client_id" "${vpn_flags[@]}"
}

# Function to wait for an established connection
establish_vpn_connection() {
  # Define the total number of steps and initialize the current step variable
  local total_steps="${PRITUNL_ESTABLISHED_CONNECTION_TIMEOUT}"
  local current_step=0

  # Define Profile Server Information
  local profile_server
  local profile_name
  local profile_ip

  # Loop until the current step reaches the total number of steps
  while [[ "$current_step" -le "$total_steps" ]]; do
    profile_server=$(get_profile_server)
    profile_name=$(echo "$profile_server" | jq -r ".name")
    profile_ip=$(echo "$profile_server" | jq -r ".client_address")

    if [[ "$profile_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]{1,2})?$ ]]; then
      echo "Connected as '$profile_name' with a private client address of '$profile_ip'."
      break
    else
      # Increment the current step
      current_step=$((current_step + 1))

      # Print the connection check progress using the progress bar function
      display_progress_bar "$current_step" "$total_steps" "Establishing connection"

      # Sleep for a moment (simulating work)
      sleep 1

      # Print the timeout message and exit error if needed
      if [[ "$current_step" -eq "$total_steps" ]]; then
        echo "Timeout reached, exiting!" && exit 1
      fi
    fi
  done
}

# Main script execution
if [[ "$RUNNER_OS" == "Linux" || "$RUNNER_OS" == "macOS" || "$RUNNER_OS" == "Windows" ]]; then
  # Normalize the VPN mode
  normalize_vpn_mode

  # Main installation process based on OS
  install_platform "$RUNNER_OS"

  # Load the Pritunl Profile File
  setup_profile_file

  if [[ "$PRITUNL_START_CONNECTION" == "true" ]]; then
    # Start the VPN connection
    start_vpn_connection "$client_id"

    # Established VPN Connection
    establish_vpn_connection
  fi
else
  echo "Unsupported OS: $RUNNER_OS" && exit 1
fi
