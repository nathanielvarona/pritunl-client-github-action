# Pritunl Client GitHub Action

Establish an Enterprise VPN Connection using the Pritunl Client that supports OpenVPN and Wireguard modes.

## Usage

```yaml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    # Pritunl `tar` Profile File in `base64` format.
    # Input in a multiline string type.
    profile-file-tar-base64: >
        ''

    # The Profile Pin (Optional)
    # If not supplied, which defaults no PIN
    profile-pin: ''

    # VPN Connection Mode (Optional)
    # The choices are `ovpn` or `wg`. If not supplied, which defaults to `ovpn`.
    vpn-mode: ''

    # Pritunl Client Version (Optional)
    # For example, using the later version `1.3.3477.58`.
    # If not supplied, which defaults to the latest version from Prebuilt Apt Repository.
    client-version: ''

    # Start the connection (Optional)
    # Boolean Type. If not supplied, which defaults to `true`
    # If `true,` the VPN connection starts within the setup step.
    start-connection: ''
```

## Working with a Pritunl File.

Pritunl Client CLI won't allow loading profiles from `.ovpn,` and GitHub Actions don't have a feature to upload binary files such as `.tar` for the Secrets.

To store Pritunl Profile to GitHub Secrets, maintaining the state of the `tar` file, we need to convert it to `base64`. Here are the steps.

### 1. Convert your Pritunl Profile File from `tar` binary to `base64` data format.

```bash
base64 ./pritunl.profile.tar > ./pritunl.profile.base64
```

#### 2. Copy the Base64 data.

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
vi ./pritunl.profile.base64 # or,
nano ./pritunl.profile.base64
```

Then select the entire data and copy it to the clipboard.

#### 3. Create a Secret and Paste the value from our clipboard.
Such as Secret Key `PRITUNL_PROFILE_FILE` from the [Examples](#examples).

## Examples

### Minimum Working Configuration

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file-tar-base64: >
        ${{ secrets.PRITUNL_PROFILE_FILE }}
```

### With PIN Supplied

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file-tar-base64: >
        ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-pin: ${{ secrets.PRITUNL_PROFILE_PIN }}
```


### Use WireGuard VPN Mode and Specific Client Version

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file-tar-base64: >
        ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-pin: ${{ secrets.PRITUNL_PROFILE_PIN }}
    vpn-mode: 'wg'
    client-version: '1.3.3477.58'
```


### Controllable Connection

```yml
- name: Setup Pritunl Profile
  id: pritunl-connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file-tar-base64: >
        ${{ secrets.PRITUNL_PROFILE_FILE }}
    start-connection: false

- name: Start VPN Connection
  run: |
    pritunl-client start ${{ steps.pritunl-connection.outputs.client-id }} \
      --mode wg \
      --pin ${{ secrets.PRITUNL_PROFILE_PIN }}

- name: Show VPN Connection Status
  run: |
    sleep 10
    pritunl-client list

- name: Your CI/CD Logic Here
  run: |
    ##
    # Example: 
    #   * Integration Test
    #   * End-to-End Test
    #   * And More
    ##

    ##
    # Below is our simple connectivity test script.
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
