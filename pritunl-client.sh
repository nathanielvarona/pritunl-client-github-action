#!/bin/bash

## GitHub Action Environment Variable Inputs
PROFILE_FILE="${PROFILE_FILE:-}"
PROFILE_PIN="${PROFILE_PIN:-}"
VPN_MODE="${VPN_MODE:-}"
CLIENT_VERSION="${CLIENT_VERSION:-}"
START_CONNECTION="${START_CONNECTION:-}"

CONNECTION_TIMEOUT=${CONNECTION_TIMEOUT:-30}

## Validate the VPN Mode
WIREGUARD_FAMILY=("wg" "wireguard" "WireGuard")
OPENVPN_FAMILY=("ovpn" "openvpn" "OpenVPN")
VPN_MODE_FAMILY=""

for member in "${!OPENVPN_FAMILY[@]}"; do
  if [[ "${OPENVPN_FAMILY[$member]}" == "$VPN_MODE" ]]; then
    VPN_MODE_FAMILY="ovpn"
    break
  fi
done
if [[ -z "$VPN_MODE_FAMILY" ]]; then
  for member in "${!WIREGUARD_FAMILY[@]}"; do
    if [[ "${WIREGUARD_FAMILY[$member]}" == "$VPN_MODE" ]]; then
      VPN_MODE_FAMILY="wg"
      break
    fi
  done
fi

validate_version() {
    local version_pattern="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
    if [[ $1 =~ $version_pattern ]]; then
        echo "Valid version: $1"
    else
        echo "Invalid version: $1"
        exit 1
    fi
}

## Installation Process
if [[ "$RUNNER_OS" == "Linux" ]]; then
  if [[ "$CLIENT_VERSION" != 'package-manager' ]]; then
    validate_version "$CLIENT_VERSION"
    echo "Installing the Version Specific from GitHub Releases"
    curl -sL https://github.com/pritunl/pritunl-client-electron/releases/download/$CLIENT_VERSION/pritunl-client_$CLIENT_VERSION-0ubuntu1.$(lsb_release -cs)_amd64.deb \
      -o $RUNNER_TEMP/pritunl-client.deb
    sudo apt-get --assume-yes install -f $RUNNER_TEMP/pritunl-client.deb
  else
    echo "Installing latest from Prebuild Apt Repository"
    echo "deb https://repo.pritunl.com/stable/apt $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/pritunl.list
    sudo apt-get --assume-yes install gnupg
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
    gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A | sudo tee /etc/apt/trusted.gpg.d/pritunl.asc
    sudo apt-get --assume-yes update
    sudo apt-get --assume-yes install pritunl-client
  fi

  if [[ -n "$VPN_MODE_FAMILY" && "$VPN_MODE_FAMILY" == "wg" ]]; then
    sudo apt-get --assume-yes install wireguard-tools
  else
    sudo apt-get --assume-yes install openvpn-systemd-resolved
  fi

elif [[ "$RUNNER_OS" == "macOS" ]]; then
  if [[ "$CLIENT_VERSION" != 'package-manager' ]]; then
    validate_version "$CLIENT_VERSION"
    curl -sL https://github.com/pritunl/pritunl-client-electron/releases/download/$CLIENT_VERSION/Pritunl.pkg.zip \
      -o $RUNNER_TEMP/Pritunl.pkg.zip
    unzip -qq -o $RUNNER_TEMP/Pritunl.pkg.zip -d $RUNNER_TEMP
    sudo -E LOGNAME=$LOGNAME USER=$USER USERNAME=$USER -- installer -pkg $RUNNER_TEMP/Pritunl.pkg -target /
  else
    brew install --cask pritunl
  fi
  mkdir -p $HOME/bin && ln -s /Applications/Pritunl.app/Contents/Resources/pritunl-client $HOME/bin/pritunl-client

  if [[ -n "$VPN_MODE_FAMILY" && "$VPN_MODE_FAMILY" == "wg" ]]; then
    brew install wireguard-tools
  fi

elif [[ "$RUNNER_OS" == "Windows" ]]; then
  if [[ "$CLIENT_VERSION" != 'package-manager' ]]; then
    validate_version "$CLIENT_VERSION"
    echo "Downloading Pritunl installation file..."
    curl -sL https://github.com/pritunl/pritunl-client-electron/releases/download/$CLIENT_VERSION/Pritunl.exe \
      -o $RUNNER_TEMP/Pritunl.exe
    echo "Starting Pritunl installation..."
    pwsh -ExecutionPolicy Bypass -Command "Start-Process -FilePath '$RUNNER_TEMP\Pritunl.exe' -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' -Wait"
    echo "Pritunl installation completed."
  else
    choco install --confirm --no-progress pritunl-client
  fi
  mkdir -p $HOME/bin && ln -s "/c/Program Files (x86)/Pritunl/pritunl-client.exe" $HOME/bin/pritunl-client

  if [[ -n "$VPN_MODE_FAMILY" && "$VPN_MODE_FAMILY" == "wg" ]]; then
    choco install --confirm --no-progress wireguard
  fi
fi

## Show Pritunl Client Version
pritunl-client version

## Load the Pritunl Profile File to the Client
# Save the `base64` text file format and convert it back to `tar` archive file format.
echo "$PROFILE_FILE" > $RUNNER_TEMP/profile-file.base64
base64 --decode $RUNNER_TEMP/profile-file.base64 > $RUNNER_TEMP/profile-file.tar
# Add the Profile File to Pritunl Client
pritunl-client add $RUNNER_TEMP/profile-file.tar
# Set `client-id` as step output
client_id=$(
  pritunl-client list \
    | awk -F'|' 'NR==4{print $2}' \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
  )
echo "client-id=$client_id" >> $GITHUB_OUTPUT
# Disable autostart option
pritunl-client disable $client_id

if [[ -n "$START_CONNECTION" && "$START_CONNECTION" == "true" ]]; then
  # Start the Connection
  pritunl-client start $client_id \
    $(
      if [[ -n "$VPN_MODE_FAMILY" ]]; then
        echo "--mode $VPN_MODE_FAMILY"
      fi
    ) \
    $(
      if [[ -n "$PROFILE_PIN" ]]; then
        echo "--password $PROFILE_PIN"
      fi
    )

  # Check the Connection
  while [[ "${CONNECTION_TIMEOUT}" -gt 0 ]] ; do
    if pritunl-client list \
      | awk -F '|' 'NR==4{print $8}' \
      | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
      | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]{1,2})?$' --quiet --color=never ; then
        echo "Connection established..."
        break
    else
      CONNECTION_TIMEOUT=$((CONNECTION_TIMEOUT - 1))
      LOADING_INDICATOR+="."
      if (( CONNECTION_TIMEOUT % 2 == 0 )); then
          echo "Connecting: $LOADING_INDICATOR"
      fi
      if [[ "$CONNECTION_TIMEOUT" -le 0 ]]; then
          echo "Timeout reached! Exiting..."
          exit 1
      fi
      sleep 1
    fi
  done

  # Show VPN Connection Status
  pritunl-client list | sed -E 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/###.###.###.###/g'

fi
