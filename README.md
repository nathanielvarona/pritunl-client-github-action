# Pritunl Client GitHub Action

[![Test Connection](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/test.yml/badge.svg?branch=main&event=workflow_dispatch)](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/test.yml)

Establish a [Pritunl VPN](https://pritunl.com/) connection using the [Pritunl Client](https://client.pritunl.com/) that supports [OpenVPN](https://openvpn.net/) and [WireGuard](https://www.wireguard.com/) modes on [GitHub Actions](https://github.com/features/actions).

This utility helps you with tasks like automated internal endpoint testing, periodic backups, and anything that requires private access inside the corporate infrastructure using Pritunl VPN Enterprise Servers.

## Usage

The configuration is declarative and relatively simple to use.

```yaml
- uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    # Pritunl Profile File (Required)
    # Type: Wrapping String (Base64 format)
    profile-file: ''

    # Profile Pin (Optional)
    # Type: String (Numerical value)
    # If not supplied, which defaults no Pin.
    profile-pin: ''

    # VPN Connection Mode (Optional)
    # Type: String (Choices ['ovpn' or 'wg'])
    # If not supplied, which defaults to 'ovpn'.
    vpn-mode: ''

    # Pritunl Client Version (Optional)
    # Type: String (Numerical dot separated identifiers)
    # For example, using the later version `1.3.3477.58`.
    # If not supplied, which defaults to the latest version from Prebuilt Apt Repository.
    client-version: ''

    # Start the Connection (Optional)
    # Type: Boolean
    # If not supplied, which defaults to `true`. 
    # If `true` the VPN connection starts within the setup step.
    start-connection: ''
```

> Kindly check the section [Working with Pritunl Profile File](#working-with-pritunl-profile-file) on converting `tar` binary to `base64` file format for the `profile-file` input.

## Examples

We have different example scenarios; any combination is possible as long the required `profile-file` input is supplied.

### Minimum Working Configuration

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}

###
# Then your other steps down below.
###

- name: Your CI/CD Core Logic
  run: |
    ##
    # EXAMPLES:
    #   * Integration Test,
    #   * End-to-End Test,
    #   * Endpoint Reachability Test,
    #   * Backup Tasks,
    #   * And more.
    ##

- name: Example Cypress E2E Test
  uses: cypress-io/github-action@v5
    working-directory: e2e
```

### The connection requires Pin or Password

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-pin: ${{ secrets.PRITUNL_PROFILE_PIN }}
```


### Specific Version of Pritunl Client and use WireGuard for the VPN Mode

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-pin: ${{ secrets.PRITUNL_PROFILE_PIN }}
    client-version: '1.3.3477.58'
    vpn-mode: 'wg'
```

### Advanced Controllable Connection

```yml
- name: Setup Pritunl Profile
  id: pritunl-connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    start-connection: false

- name: Start VPN Connection
  run: |
    pritunl-client start ${{ steps.pritunl-connection.outputs.client-id }} \
      --password ${{ secrets.PRITUNL_PROFILE_PIN }}

- name: Show VPN Connection Status
  run: |
    sleep 10
    pritunl-client list

- name: Your CI/CD Core Logic
  run: |
    ##
    # Below is our simple example for VPN connectivity test.
    ##

    # Install Tooling
    sudo apt-get install -y ipcalc

    # VPN Gateway Reachability Test
    ping -c 10 \
      $(pritunl-client list | \
      awk -F '|' 'NR==4{print $8}' | \
      xargs ipcalc | \
      awk 'NR==6{print $2}')

- name: Stop VPN Connection
  if: ${{ always() }}
  run: |
    pritunl-client stop ${{ steps.pritunl-connection.outputs.client-id }}
```

## Working with Pritunl Profile File

Pritunl Client CLI won't allow loading profiles from the `.ovpn` file, and GitHub doesn't have a feature to upload binary files such as `.tar` for the GitHub Actions Secrets.

To store Pritunl Profile to GitHub Secrets, maintaining the state of the `tar` binary file, we need to convert it to `base64` file format.

### Here are the steps

#### 1. Download the Pritunl Profile File obtained from the Pritunl User Profile Page

```bash
curl -s -L -o ./pritunl.profile.tar https://vpn.domain.tld/key/xxxxxxxxxxxxxx.tar
```

#### 2. Convert your Pritunl Profile File from `tar` binary to `base64` data format.

```bash
base64 -w 0 ./pritunl.profile.tar > ./pritunl.profile.base64
```

#### 3. Copy the `base64` data.

_For macOS:_
```bash
cat ./pritunl.profile.base64 | pbcopy
```

_For Linux:_
```bash
# Using `xclip`
cat ./pritunl.profile.base64 | xclip -selection clipboard

# Using `xsel`
cat ./pritunl.profile.base64 | xsel --clipboard --input
```

_Or open it with your favorite code editor:_

```bash
code ./pritunl.profile.base64 # or,
vim ./pritunl.profile.base64
```

Then select the entire data and copy it to the clipboard.

#### 4. Create a Secret and Paste the value from our clipboard.
Such as Secrets Key `PRITUNL_PROFILE_FILE` from the [Examples](#examples).
