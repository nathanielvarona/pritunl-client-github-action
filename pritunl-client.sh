#!/usr/bin/env bash

# Refer to these links for Pritunl Client installation and setup guides:
# https://client.pritunl.com/#install
# https://docs.pritunl.com/docs/installation-client
# https://github.com/pritunl/pritunl-client-electron

# Set up error handling to ensure the script fails on errors and pipes
set -euo pipefail  # Enables error handling and pipefail

# Define environment variables based on GitHub Action inputs
# Default values are set if inputs are not provided

# GitHub Action Inputs as Environment Variables
PRITUNL_PROFILE_FILE="${PRITUNL_PROFILE_FILE:-}"  # Pritunl Profile File
PRITUNL_PROFILE_PIN="${PRITUNL_PROFILE_PIN:-}"  # Pritunl Profile PIN
PRITUNL_PROFILE_SERVER="${PRITUNL_PROFILE_SERVER:-}"  # Pritunl Profile Server
PRITUNL_VPN_MODE="${PRITUNL_VPN_MODE:-}"  # VPN Connection Mode
PRITUNL_CLIENT_VERSION="${PRITUNL_CLIENT_VERSION:-}"  # Pritunl Client Version
PRITUNL_START_CONNECTION="${PRITUNL_START_CONNECTION:-}"  # Start VPN Connection
PRITUNL_READY_PROFILE_TIMEOUT="${PRITUNL_READY_PROFILE_TIMEOUT:-}"  # Ready Profile Timeout
PRITUNL_ESTABLISHED_CONNECTION_TIMEOUT="${PRITUNL_ESTABLISHED_CONNECTION_TIMEOUT:-}"  # Established Connection Timeout

# ---------------------------------------------------------------

# Emoji Icons
TTY_EMOJI_ROCKET='\xf0\x9f\x9a\x80'  # Rocket emoji for visual feedback

# ---------------------------------------------------------------

# Terminal Colors
TTY_RED_NORMAL='\033[0;31m'  # Normal red color
TTY_RED_BOLD='\033[1;31m'  # Bold red color
TTY_GREEN_NORMAL='\033[0;32m'  # Normal green color
TTY_GREEN_BOLD='\033[1;32m'  # Bold green color
TTY_YELLOW_NORMAL='\033[0;33m'  # Normal yellow color
TTY_YELLOW_BOLD='\033[1;33m'  # Bold yellow color
TTY_BLUE_NORMAL='\033[0;34m'  # Normal blue color
TTY_BLUE_BOLD='\033[1;34m'  # Bold blue color
TTY_COLOR_RESET='\033[0m'  # Reset terminal color

# Installation process for Linux
install_for_linux() {
  # This function contains code to install the Pritunl client on Linux.
  # It installs dependent packages, configures repositories, and installs the client.

  install_vpn_dependencies

  if [[ "$PRITUNL_CLIENT_VERSION" == "from-package-manager" ]]; then
    # Installing using Pritunl Prebuilt Apt Repository
    # This section sets up the Pritunl repository and installs the client using the package manager.

    # Set the Pritunl Linux runner GPG key
    # Default value: 7568D9BB55FF9E5287D586017AE645C0CF8E292A
    # Check https://keyserver.ubuntu.com/ for the latest key
    PRITUNL_LINUX_RUNNER_GPG_KEY="${PRITUNL_LINUX_RUNNER_GPG_KEY:-7568D9BB55FF9E5287D586017AE645C0CF8E292A}"

    # Note: If the default key fails, you can override it with a new key
    # Example: In GitHub Actions, use the 'env' key to set a new GPG key
    # See the example workflow below:
    # ```
    # - name: Setup Pritunl Profile and Start VPN Connection
    #   uses: nathanielvarona/pritunl-client-github-action@v1
    #   with:
    #     profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    #   env:
    #     PRITUNL_LINUX_RUNNER_GPG_KEY: '<YOUR OVERRIDE GPG KEY>'
    # ```

    # Add Pritunl repository to the system
    echo "deb https://repo.pritunl.com/stable/apt $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/pritunl.list
    # Import Pritunl's GPG key
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ${PRITUNL_LINUX_RUNNER_GPG_KEY} > /dev/null 2>&1
    # Export the GPG key and add it to the trusted keyring
    gpg --armor --export ${PRITUNL_LINUX_RUNNER_GPG_KEY} | sudo tee /etc/apt/trusted.gpg.d/pritunl.asc > /dev/null
    # Update the package list and install Pritunl client
    sudo apt-get update -qq -y && sudo apt-get install -qq -o=Dpkg::Use-Pty=0 -y pritunl-client

  else
    # Installing Version Specific using Debian Package from Pritunl GitHub Releases
    # This section installs a specific version of the client from GitHub releases.

    # Define distributed installable file
    local pritunl_install_file
    local deb_url

    validate_client_version "$PRITUNL_CLIENT_VERSION"

    pritunl_install_file="$RUNNER_TEMP/pritunl-client.deb"
    deb_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$PRITUNL_CLIENT_VERSION/pritunl-client_$PRITUNL_CLIENT_VERSION-0ubuntu1.$(lsb_release -cs)_amd64.deb"

    curl -sSL "$deb_url" -o "$pritunl_install_file"

    # Installing using APT package handling utility
    if sudo apt-get install -qq -o=Dpkg::Use-Pty=0 -y "$pritunl_install_file"; then
      rm -f "$pritunl_install_file"
    fi
  fi
}

# Installation process for macOS
install_for_macos() {
  # This function installs the Pritunl client on macOS.
  # It uses Homebrew or specific GitHub releases for installation.

  # Define linking paths
  local pritunl_client_bin
  local user_bin_directory

  install_vpn_dependencies

  if [[ "$PRITUNL_CLIENT_VERSION" == "from-package-manager" ]]; then
    # Installing using Homebrew Package Manager for macOS

    brew install -q --cask pritunl

  else
    # Installing Version Specific using macOS Package from Pritunl GitHub Releases

    local pritunl_install_file
    local pkg_zip_url
    local pkg_arch

    validate_client_version "$PRITUNL_CLIENT_VERSION"

    pkg_arch=$([[ "$RUNNER_ARCH" == "ARM64" ]] && echo 'arm64.' || echo '')

    pritunl_install_file="$RUNNER_TEMP/Pritunl.${pkg_arch}pkg.zip"
    pkg_zip_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$PRITUNL_CLIENT_VERSION/Pritunl.${pkg_arch}pkg.zip"

    curl -sSL "$pkg_zip_url" -o "$pritunl_install_file"
    unzip -qq -o "$pritunl_install_file" -d "$RUNNER_TEMP"

    # Installing using MacOS `installer` a system software and .pkg package installer tool
    if sudo installer -pkg "$RUNNER_TEMP/Pritunl.${pkg_arch}pkg" -target /; then
      rm -f "$pritunl_install_file" "$RUNNER_TEMP/Pritunl.${pkg_arch}pkg"
    fi
  fi

  pritunl_client_bin="/Applications/Pritunl.app/Contents/Resources/pritunl-client"
  user_bin_directory="$HOME/bin/"

  link_executable_to_bin "$pritunl_client_bin" "$user_bin_directory"
}

# Installation process for Windows
install_for_windows() {
  # This function installs the Pritunl client on Windows.
  # It uses Chocolatey or specific GitHub releases for installation.

  # Define linking paths
  local pritunl_client_bin
  local user_bin_directory

  install_vpn_dependencies

  if [[ "$PRITUNL_CLIENT_VERSION" == "from-package-manager" ]]; then
    # Installing using Choco Package Manager for Windows

    choco install --no-progress -y pritunl-client

  else
    # Install Version Specific using Windows Package from Pritunl GitHub Releases

    local pritunl_install_file
    local exe_url

    validate_client_version "$PRITUNL_CLIENT_VERSION"

    pritunl_install_file="$RUNNER_TEMP\Pritunl.exe"
    exe_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$PRITUNL_CLIENT_VERSION/Pritunl.exe"

    curl -sSL "$exe_url" -o "$pritunl_install_file"

    # Installing using Ad hoc PowerShell Script
    if pwsh -ExecutionPolicy Bypass -Command "Start-Process -FilePath '$pritunl_install_file' -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' -Wait"; then
      rm -f "$pritunl_install_file"
    fi
  fi

  pritunl_client_bin="/c/Program Files (x86)/Pritunl/pritunl-client.exe"
  user_bin_directory="$HOME/bin/"

  link_executable_to_bin "$pritunl_client_bin" "$user_bin_directory"
}

# Link Executable File to Binary Directory
link_executable_to_bin() {
  # This function creates a symbolic link to the Pritunl client executable in the user's binary directory.
  # It's used to make the client executable available from the command line.

  # Define linking paths
  local executable_file
  local bin_directory

  executable_file="$1"
  bin_directory="$2"

  if [[ -e "$executable_file" ]]; then
    if ! [[ -d "$bin_directory" ]]; then
      mkdir -p "$bin_directory"
    fi
    ln -s "$executable_file" "$bin_directory"
  else
    echo -e "${TTY_RED_NORMAL}Installation of the executable \`$executable_file\` failed.${TTY_COLOR_RESET}" && exit 1
  fi
}

# Install VPN dependent packages based on OS
install_vpn_dependencies() {
  # This function installs dependencies required for VPN connections based on the operating system.

  case "$RUNNER_OS" in
    Linux)
      # Install base dependent packages for `pritunl-client` on Linux
      sudo apt-get update -qq -y
      sudo apt-get install -qq -o=Dpkg::Use-Pty=0 -y net-tools iptables openvpn resolvconf
      if [[ "$PRITUNL_VPN_MODE" == "ovpn" ]]; then
        sudo apt-get install -qq -o=Dpkg::Use-Pty=0 -y openvpn-systemd-resolved
      elif [[ "$PRITUNL_VPN_MODE" == "wg" ]]; then
        sudo apt-get install -qq -o=Dpkg::Use-Pty=0 -y wireguard-tools
      fi
      ;;
    macOS)
      if [[ "$PRITUNL_VPN_MODE" == "wg" ]]; then
        brew install -q wireguard-tools
      fi
      ;;
    Windows)
      if [[ "$PRITUNL_VPN_MODE" == "wg" ]]; then
        choco install --no-progress -y wireguard
      fi
      ;;
  esac
}

# Function to decode and add a profile
setup_profile_file() {
  # This function decodes a base64-encoded profile file and adds it to the Pritunl client.

  # Define the total number of steps and initialize the current step variable
  local timeout_seconds
  local start_time
  local end_time
  local current_time
  local progression_count
  local elapsed_count

  # Define Profile File Base64 Data
  local profile_base64
  local profile_file

  # Define Profile Server Information
  local profile_server_json

  # Progress Status
  timeout_seconds="${PRITUNL_READY_PROFILE_TIMEOUT}"
  start_time=$(date +%s)
  end_time=$(( start_time + timeout_seconds ))
  current_time=$(date +%s)

  # Store the base64 data in a variable
  profile_base64="$PRITUNL_PROFILE_FILE"
  profile_file="$RUNNER_TEMP/profile-file.tar"

  # Check if the base64 data is valid
  if ! [[ $(base64 -d <<< "$profile_base64" 2>/dev/null | tr -d '\0') ]]; then
    echo -e "${TTY_RED_NORMAL}Base64 data is not valid.${TTY_COLOR_RESET}" && exit 1
  fi

  # If the base64 data is valid, decode it and store it to tempotary file.
  echo "$profile_base64" | base64 -d > "$profile_file"

  if [[ -e "$profile_file" ]]; then
    # Check if the file is a valid tar archive
    if ! file "$profile_file" | grep -q 'tar archive'; then
      echo -e "${TTY_RED_NORMAL}The file is not a valid tar archive.${TTY_COLOR_RESET}" && exit 1
    fi
  fi

  if ! pritunl-client add "$profile_file"; then
    echo -e "${TTY_RED_NORMAL}It appears that the profile file cannot be loaded.${TTY_COLOR_RESET}" && exit 1
  else
    rm -f "$profile_file"
  fi

  # Loop until the current step reaches the total number of steps
  while [[ "$end_time" -ge "$current_time" ]]; do

    profile_server_json=$(fetch_profile_server)

    if [[ $(echo "$profile_server_json" | jq ". | length") -gt 0 ]]; then
      client_id=$(echo $profile_server_json | jq -c "[.[] | {name: .name, id: .id}]")
      if [[ -n "$GITHUB_ACTIONS" ]]; then
        # Setting output parameter `client-id`.
        echo "client-id="$client_id"" >> "$GITHUB_OUTPUT"
      fi

      # Display the profile name and client id in the logs.
      echo "======================================================="
      echo -e "Profile is set, the step output \`${TTY_BLUE_NORMAL}client-id${TTY_COLOR_RESET}\` is created."
      echo "======================================================="
      echo "$client_id" | jq -C
      echo "======================================================="

      # Break the loop
      break
    else
      # Calculate the time consumed
      progression_count=$((current_time - start_time))

      # Present the time consumed as lapsed count
      elapsed_count=$([[ "$progression_count" -lt 1 ]] && echo 0 || echo $progression_count)

      # Print the attempt progress using the progress bar function
      display_progress "$elapsed_count" "$timeout_seconds" "Ready profile"

      # Sleep for a moment (simulating work)
      sleep 1

      # Update the current time
      current_time=$(date +%s)

      # Print the timeout message and exit error if needed
      if [[ "$current_time" -ge "$end_time" ]]; then
        echo -e "${TTY_RED_NORMAL}No server entries found for a profile.${TTY_COLOR_RESET}" && exit 1
      fi
    fi
  done
}

# Start VPN connection
start_vpn_connection() {
  # This function starts the VPN connection using the Pritunl client.

  # Define the start connection options
  local pritunl_client_start_flags
  local profile_server_array
  local profile_server_json
  local profile_server_item

  # Empty initialization
  pritunl_client_start_flags=()
  profile_server_array=()

  # Get Profile
  profile_server_json=$(fetch_profile_server)

  if [[ -n "$PRITUNL_VPN_MODE" ]]; then
    pritunl_client_start_flags+=( "--mode" "$PRITUNL_VPN_MODE" )
  fi

  if [[ -n "$PRITUNL_PROFILE_PIN" ]]; then
    pritunl_client_start_flags+=( "--password" "$PRITUNL_PROFILE_PIN" )
  fi

  # Convert the JSON data into a Bash array
  while read -r line; do
    profile_server_array+=("$line")
  done < <(echo "$profile_server_json" | jq -c '.[]')

  for profile_server_item in "${profile_server_array[@]}"; do
    pritunl-client start "$(echo "$profile_server_item" | jq -r ".id")" "${pritunl_client_start_flags[@]}"
    sleep 1
  done
}

# Function to wait for an established connection
establish_vpn_connection() {
  # This function waits for the VPN connection to be fully established.

  # Define the total number of steps and initialize the current step variable
  local timeout_seconds
  local start_time
  local end_time
  local current_time
  local progression_count
  local elapsed_count

  # Define Profile Server Information
  local profile_server_json
  local profile_server_array
  local profile_server_item

  # Initialize an empty JSON array for the connection statuses
  local connections_connected
  local connections_expected
  local connections_status
  local connection_status

  # Progress status
  timeout_seconds="${PRITUNL_ESTABLISHED_CONNECTION_TIMEOUT}"
  start_time=$(date +%s)
  end_time=$(( start_time + timeout_seconds ))
  current_time=$(date +%s)

  # Empty initialization
  profile_server_array=()
  connections_status='[]'

  # Loop until the current step reaches the total number of steps
  while [[ "$current_time" -le "$end_time" ]]; do

    profile_server_json=$(fetch_profile_server)

    # Convert the JSON data into a Bash array
    while read -r line; do
      profile_server_array+=("$line")
    done < <(echo "$profile_server_json" | jq -c '.[]')

    # Update the current time
    current_time=$(date +%s)

    # Calculate the time consumed
    progression_count=$((current_time - start_time))

    # Present the time consumed as lapsed count
    elapsed_count=$([[ "$progression_count" -lt 1 ]] && echo 0 || echo $progression_count)

    # Print the connection check progress using the progress bar function
    display_progress "$elapsed_count" "$timeout_seconds" "Establishing connection"

    for profile_server_item in "${profile_server_array[@]}"; do
      profile_name="$(echo "$profile_server_item" | jq -r ".name")"
      profile_id="$(echo "$profile_server_item" | jq -r ".id")"
      profile_ip="$(echo "$profile_server_item" | jq -r ".client_address")"

      if [[ "$profile_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]{1,2})?$ ]]; then

        # Check if the object with the given ID already exists in the array
        connection_status=$(
          echo "$connections_status" |
            jq --arg profile_id "$profile_id" '.[] | select(.id == $profile_id)'
        )

        if [ -n "$connection_status" ]; then
          # If the object already exists, filter it out and append the updated object
          connections_status=$(
            echo "$connections_status" |
              jq --arg profile_id "$profile_id" '. | map(select(.id != $profile_id)) + [{"id": $profile_id, "status": "connected"}]'
          )
        else
          # If the object does not exist, use jq to append it to the JSON array
          connections_status=$(
            echo "$connections_status" |
              jq --arg profile_id "$profile_id" '. + [{"id": $profile_id, "status": "connected"}]'
          )
          echo -e "The connection for profile \`${TTY_GREEN_NORMAL}${profile_name}${TTY_COLOR_RESET}\` has been fully established."
        fi

      fi
    done

    connections_connected="$(echo $connections_status | jq ". | length")"
    connections_expected="$(echo $profile_server_json | jq ". | length")"

    if [[ "$connections_connected" -eq "$connections_expected" ]]; then
      echo -e "${TTY_GREEN_BOLD}The profile, which has designated server(s), has been successfully set up.${TTY_COLOR_RESET}"
      break
    fi

    # Sleep for a moment
    sleep 1

    # Update once again the current time
    current_time=$(date +%s)
  done

  # Print the timeout message and exit error if needed
  if [[ "$current_time" -gt "$end_time" ]]; then
    echo "Timeout reached!"
    if [[ "$connections_connected" -gt 0 ]] && [[ "$connections_connected" -lt "$connections_expected" ]]; then
      echo -e "${TTY_YELLOW_BOLD}We could not establish a connection to other servers, but we will go ahead and proceed anyway.${TTY_COLOR_RESET}"
      break
    else
      echo -e "${TTY_RED_BOLD}We could not connect to the server(s) specified in the profile. The process has been terminated.${TTY_COLOR_RESET}" && exit 1
    fi
  fi
}

# Get the Profile Server
fetch_profile_server() {
  # This function retrieves the Pritunl profile server information.

  # Define `pritunl-client` information fetching options.
  local profile_list_json
  local profile_server_array
  local profile_server_json
  local profile_server_array_item
  local profile_server_matching
  local profile_server_item
  local profile_server_object

  # Fetch the profile list JSON
  profile_list_json=$(pritunl-client list -j | jq -c 'sort_by(.name)')

  if [[ -n "$PRITUNL_PROFILE_SERVER" ]]; then

    if [[ "$PRITUNL_PROFILE_SERVER" == "all-profile-server" ]]; then
      # If "all-profile-server" is set, return the entire profile list
      profile_server_json="$profile_list_json"
    else

      # Split the comma-separated profile server names into an array
      IFS=',' read -r -a profile_server_array <<< "$PRITUNL_PROFILE_SERVER"

      # Remove leading and trailing spaces from each element in the array
      for profile_server_array_item in "${!profile_server_array[@]}"; do
        profile_server_array[$profile_server_array_item]=$(
          echo "${profile_server_array[$profile_server_array_item]}" |
            sed -e 's/^[[:space:]]*//; s/[[:space:]]*$//'
        )
      done

      # Initialize an empty array to store matching profiles
      profile_server_matching=()

      for profile_server_item in "${profile_server_array[@]}"; do
        # Try to find the profile server JSON based on the current profile server name
        profile_server_object=$(
          echo "$profile_list_json" |
            jq -c --arg profile "$profile_server_item" '.[] | select(.name | contains($profile))'
        )

        if [[ -n "$profile_server_object" ]]; then
          profile_server_matching+=("$profile_server_object")
        fi
      done

      if [[ ${#profile_server_matching[@]} -gt 0 ]]; then
        # If matching profiles were found, print them as a JSON array
        profile_server_json=$(
          echo "["
            for ((i=0; i<${#profile_server_matching[@]}; i++)); do
              echo "${profile_server_matching[i]}"
              if [ $i -lt $((${#profile_server_matching[@]}-1)) ]; then
                echo ","
              fi
            done
          echo "]"
        )
      else
        profile_server_json="[]"
      fi
    fi
  else
    # If environment variable is not set, return the first profile
    profile_server_json="[$(echo "$profile_list_json" | jq -c ".[0]")]"
  fi

  echo "$profile_server_json" | jq -c -M
}

# Function to print a progress bar
display_progress() {
  # This function displays a progress bar for various tasks.
  # It's used to provide visual feedback on the progress of certain actions.

  # Define the current, the total step in the process and the message to display
  local current_step
  local total_steps
  local message

  # Calculate the percentage progress
  local percentage

  # Calculate the number of completed and remaining characters for the progress bar
  local completed
  local remaining

  # Progress Counter
  current_step="$1"
  total_steps="$2"
  message="$3"
  percentage=$((current_step * 100 / total_steps))
  completed=$((percentage / 2))
  remaining=$((50 - completed))

  # Print the progress bar
  echo -n -e "$message: ["
  for ((i = 0; i < completed; i++)); do
    echo -n -e "${TTY_YELLOW_NORMAL}#${TTY_COLOR_RESET}"
  done
  for ((i = 0; i < remaining; i++)); do
    echo -n -e "${TTY_GREEN_NORMAL}-${TTY_COLOR_RESET}"
  done
  echo -n -e "] ${TTY_YELLOW_NORMAL}${current_step}s${TTY_COLOR_RESET} elapsed (out of ${TTY_GREEN_NORMAL}${total_steps}s${TTY_COLOR_RESET} allowed)."

  # Print new line
  echo -n -e "\n"
}

# Normalize the VPN mode
normalize_vpn_mode() {
  # This function normalizes the VPN mode input to ensure it matches supported values.
  # It ensures the input is either "ovpn" or "wg" (OpenVPN or WireGuard).

  # Normalization of characters and variable substitution
  case "$(echo "$PRITUNL_VPN_MODE" | tr '[:upper:]' '[:lower:]')" in
    ovpn|openvpn)
      PRITUNL_VPN_MODE="ovpn"
      ;;
    wg|wireguard)
      PRITUNL_VPN_MODE="wg"
      ;;
    *)
      echo -e "${TTY_RED_NORMAL}Invalid VPN mode for \`$PRITUNL_VPN_MODE\`.${TTY_COLOR_RESET}" && exit 1
      ;;
  esac
}

# Validate version against raw source version file
validate_client_version() {
  # This function validates the provided client version against a version file in the GitHub repository.
  # It ensures that the version exists in the source.

  # Define Version File and Originated Repository
  local version
  local pritunl_client_repo
  local version_file

  # Version Argument
  version="$1"

  # Version Source
  pritunl_client_repo="pritunl/pritunl-client-electron"
  version_file="https://raw.githubusercontent.com/$pritunl_client_repo/master/CHANGES"

  # Validate Client Version Pattern
  if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    echo -e "${TTY_RED_NORMAL}Invalid version pattern for \`$version\`.${TTY_COLOR_RESET}" && exit 1
  fi

  # Use curl to fetch the raw file and pipe it to grep
  if ! [[ $(curl -sSL $version_file | grep -c "$version") -ge 1 ]]; then
    echo -e "${TTY_RED_NORMAL}Version \`$version\` does not exist in the \`$pritunl_client_repo\` source.${TTY_COLOR_RESET}" && exit 1
  fi
}

# Function to display the installed Pritunl client version
display_installed_client() {
  # Print the Pritunl client version with colorful output
  # Using awk to format the output
  pritunl-client version |
    awk 'BEGIN {
      # Define ASCII art rocket and color codes
      rocket="'${TTY_EMOJI_ROCKET}'"  # Rocket emoji for visual feedback
      blue="'${TTY_BLUE_BOLD}'"  # Blue color for version text
      green="'${TTY_GREEN_BOLD}'"  # Green color for version status
      reset="'${TTY_COLOR_RESET}'"  # Reset terminal color
    }
    # Format the output with rocket ASCII art and colors
    {
      # Print the version information with colors and rocket ASCII art
      printf "%s %s%s %s%s %s%s%s\n", # Render Format
        rocket, # TTY Emoji Rocket
        blue, # TTY Color Blue
        $1,  # Client name
        $2,  # Client name
        reset, # TTY Color Reset
        green, # TTY Green Color
        $3,  # Version Number
        reset # TTY Color Reset
    }'
}

# Installation process based on OS
install_vpn_platform() {
  # This function selects the appropriate installation process based on the operating system.

  # Install Packages by OS
  case "$RUNNER_OS" in
    Linux)
      install_for_linux
      ;;
    macOS)
      install_for_macos
      ;;
    Windows)
      install_for_windows
      ;;
  esac
}

# Main script execution
case "${RUNNER_OS}" in
  Linux|macOS|Windows)
    # Check the operating system and proceed with installation, setup, and starting the VPN connection if specified

    # Normalize the VPN mode to ensure consistency
    normalize_vpn_mode

    # Install the VPN client based on the operating system
    if install_vpn_platform; then
      # Display the installed Pritunl client version for reference
      display_installed_client
    fi

    # Load the Pritunl Profile File for configuration
    setup_profile_file

    # Check if the VPN connection should be started automatically
    if [[ "${PRITUNL_START_CONNECTION}" == "true" ]]; then
      # Start the VPN connection
      start_vpn_connection

      # Wait for the VPN connection to be established
      establish_vpn_connection
    fi
    ;;
  *)
    # If the operating system is not supported, print an error message and exit
    echo -e "${TTY_RED_BOLD}Unsupported OS: ${RUNNER_OS}.${TTY_COLOR_RESET}" && exit 1
    ;;
esac
