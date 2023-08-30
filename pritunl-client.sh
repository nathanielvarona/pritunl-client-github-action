#!/bin/bash

# Set up error handling
set -euo pipefail

# GitHub Action Environment Variable Inputs
PROFILE_FILE="${PROFILE_FILE:-}"
PROFILE_PIN="${PROFILE_PIN:-}"
VPN_MODE="${VPN_MODE:-}"
CLIENT_VERSION="${CLIENT_VERSION:-}"
START_CONNECTION="${START_CONNECTION:-}"

# Connections
CONNECTION_TIMEOUT=${CONNECTION_TIMEOUT:-30}
LOADING_INDICATOR="."

# Validate the VPN Mode
VPN_MODE_FAMILY=""

if [[ "$VPN_MODE" == "ovpn" || "$VPN_MODE" == "openvpn" || "$VPN_MODE" == "OpenVPN" ]]; then
  VPN_MODE_FAMILY="ovpn"
elif [[ "$VPN_MODE" == "wg" || "$VPN_MODE" == "wireguard" || "$VPN_MODE" == "WireGuard" ]]; then
  VPN_MODE_FAMILY="wg"
else
  echo "Invalid VPN mode: $VPN_MODE"
  exit 1
fi

# Validate version pattern against GitHub API
validate_version() {
  local version="$1"
  local version_pattern="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"

  if [[ ! "$version" =~ $version_pattern ]]; then
    echo "Invalid version pattern for $version"
    exit 1
  fi

  local version_listing
  # To prevent rate limits for API calls from the `https://api.github.com/repos/pritunl/pritunl-client-electron/tags`.
  # We will use the generated file `valid-version.txt` for now as our source.
  # Use the script `valid-version.sh` to update the `valid-version.txt`
  version_listing=$(cat "$(dirname "$0")/valid-version.txt")

  if ! echo "$version_listing" | grep -v '^[#;]' | grep --quiet --color=never "$version"; then
    echo "Invalid version for $version"
    exit 1
  fi
}

# Installation process for Linux
install_linux() {
  if [[ "$CLIENT_VERSION" != "package-manager" ]]; then
    validate_version "$CLIENT_VERSION"
    echo "Installing Version Specific from GitHub Releases"
    deb_url="https://github.com/pritunl/pritunl-client-electron/releases/download/$CLIENT_VERSION/pritunl-client_$CLIENT_VERSION-0ubuntu1.$(lsb_release -cs)_amd64.deb"
    curl -sL "$deb_url" -o "$RUNNER_TEMP/pritunl-client.deb"
    sudo apt-get --assume-yes install -f "$RUNNER_TEMP/pritunl-client.deb"
  else
    echo "Installing latest from Prebuilt Apt Repository"
    echo "deb https://repo.pritunl.com/stable/apt $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/pritunl.list
    sudo apt-get --assume-yes install gnupg
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
    gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A | sudo tee /etc/apt/trusted.gpg.d/pritunl.asc
    sudo apt-get --assume-yes update
    sudo apt-get --assume-yes install pritunl-client
  fi

  install_vpn_dependent_packages "Linux"
}

# Installation process for macOS
install_macos() {
  if [[ "$CLIENT_VERSION" != "package-manager" ]]; then
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
  if [[ "$CLIENT_VERSION" != "package-manager" ]]; then
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
}

# Install VPN dependent packages based on OS
install_vpn_dependent_packages() {
  local os_type="$1"
  if [[ -n "$VPN_MODE_FAMILY" && "$VPN_MODE_FAMILY" == "wg" ]]; then
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

  # Check the Connection
  while [[ "${CONNECTION_TIMEOUT}" -gt 0 ]]; do
    if pritunl-client list |
      awk -F '|' 'NR==4{print $8}' |
      sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' |
      grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]{1,2})?$' --quiet --color=never; then
      echo "Connection established..."
      break
    else
      CONNECTION_TIMEOUT=$((CONNECTION_TIMEOUT - 1))
      if (( CONNECTION_TIMEOUT % 2 == 0 )); then
        SHOW_LOADING_INDICATOR="${LOADING_INDICATOR}${LOADING_INDICATOR}"
        echo -n "$SHOW_LOADING_INDICATOR"
      fi
      if [[ "$CONNECTION_TIMEOUT" -le 0 ]]; then
        echo "Timeout reached! Exiting..."
        exit 1
      fi
      sleep 1
    fi
  done

  # Display VPN Connection Status
  pritunl_client_info=$(pritunl-client list)
  profile_name=$(echo "$pritunl_client_info" | awk -F '|' 'NR==4{print $3}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
  profile_ip=$(echo "$pritunl_client_info" | awk -F '|' 'NR==4{print $8}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
  echo "Connected as '$profile_name' with a private address of '$profile_ip'."
fi
