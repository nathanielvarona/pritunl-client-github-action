# Pritunl Client GitHub Action

Establish a [Pritunl VPN](https://pritunl.com/) connection using [Pritunl Client](https://client.pritunl.com/) supporting [OpenVPN](https://openvpn.net/) (ovpn) and [WireGuard](https://www.wireguard.com/) (wg) modes on [GitHub Actions](https://github.com/features/actions).

This utility helps you with tasks like automated internal endpoint testing, periodic backups, and anything that requires private access inside the corporate infrastructure using Pritunl VPN Enterprise Servers.

## Action Diagram

![Diagram](./action.dio.svg)

> _The [diagram](./action.dio.svg) is an editable vector image using [drawio](https://www.drawio.com/) app._

## Connection Tests

[![Connection Tests](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests.yml/badge.svg?branch=main)](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests.yml?query=branch:main)

Compatibility and Common [Issues](https://github.com/nathanielvarona/pritunl-client-github-action/issues?q=is:issue) between the Runners and VPN Mode.

Runner         | OpenVPN                | WireGuard
---------------|------------------------|-----------------------
`ubuntu-22.04` | :white_check_mark: yes | :white_check_mark: yes
`ubuntu-20.04` | :white_check_mark: yes | :white_check_mark: yes
`macos-12`     | :white_check_mark: yes | :white_check_mark: yes
`macos-11`     | :white_check_mark: yes | :white_check_mark: yes
`windows-2022` | :white_check_mark: yes | :white_check_mark: yes
`windows-2019` | :white_check_mark: yes | :white_check_mark: yes

<details>
  <summary>Check out the comprehensive test connection matrix available on our GitHub Actions.</summary>

  Using the `gh` command:
  ```sh
  gh api --paginate repos/nathanielvarona/pritunl-client-github-action/actions/runs/${JOB_ID}/jobs |
    jq -r '.jobs[] | [.name, .status] | @csv' |
    sed 's/"//g' |
    awk 'BEGIN{print "runner, vpn-mode, client-version, start-connection, status"} {gsub(/, /, ", ", $0); gsub(/,completed/, ", completed", $0); print}'
  ```

  Expected results:
  ```
  runner, vpn-mode, client-version, start-connection, status
  run:ubuntu-22.04, vpn:ovpn, cv:from-package-manager, sc:true, completed
  run:ubuntu-22.04, vpn:ovpn, cv:from-package-manager, sc:false, completed
  run:ubuntu-22.04, vpn:ovpn, cv:1.3.3637.72, sc:true, completed
  run:ubuntu-22.04, vpn:ovpn, cv:1.3.3637.72, sc:false, completed
  run:ubuntu-22.04, vpn:wg, cv:from-package-manager, sc:true, completed
  run:ubuntu-22.04, vpn:wg, cv:from-package-manager, sc:false, completed
  run:ubuntu-22.04, vpn:wg, cv:1.3.3637.72, sc:true, completed
  run:ubuntu-22.04, vpn:wg, cv:1.3.3637.72, sc:false, completed
  run:ubuntu-20.04, vpn:ovpn, cv:from-package-manager, sc:true, completed
  run:ubuntu-20.04, vpn:ovpn, cv:from-package-manager, sc:false, completed
  run:ubuntu-20.04, vpn:ovpn, cv:1.3.3637.72, sc:true, completed
  run:ubuntu-20.04, vpn:ovpn, cv:1.3.3637.72, sc:false, completed
  run:ubuntu-20.04, vpn:wg, cv:from-package-manager, sc:true, completed
  run:ubuntu-20.04, vpn:wg, cv:from-package-manager, sc:false, completed
  run:ubuntu-20.04, vpn:wg, cv:1.3.3637.72, sc:true, completed
  run:ubuntu-20.04, vpn:wg, cv:1.3.3637.72, sc:false, completed
  run:macos-12, vpn:ovpn, cv:from-package-manager, sc:true, completed
  run:macos-12, vpn:ovpn, cv:from-package-manager, sc:false, completed
  run:macos-12, vpn:ovpn, cv:1.3.3637.72, sc:true, completed
  run:macos-12, vpn:ovpn, cv:1.3.3637.72, sc:false, completed
  run:macos-12, vpn:wg, cv:from-package-manager, sc:true, completed
  run:macos-12, vpn:wg, cv:from-package-manager, sc:false, completed
  run:macos-12, vpn:wg, cv:1.3.3637.72, sc:true, completed
  run:macos-12, vpn:wg, cv:1.3.3637.72, sc:false, completed
  run:macos-11, vpn:ovpn, cv:from-package-manager, sc:true, completed
  run:macos-11, vpn:ovpn, cv:from-package-manager, sc:false, completed
  run:macos-11, vpn:ovpn, cv:1.3.3637.72, sc:true, completed
  run:macos-11, vpn:ovpn, cv:1.3.3637.72, sc:false, completed
  run:macos-11, vpn:wg, cv:from-package-manager, sc:true, completed
  run:macos-11, vpn:wg, cv:from-package-manager, sc:false, completed
  run:macos-11, vpn:wg, cv:1.3.3637.72, sc:true, completed
  run:macos-11, vpn:wg, cv:1.3.3637.72, sc:false, completed
  run:windows-2022, vpn:ovpn, cv:from-package-manager, sc:true, completed
  run:windows-2022, vpn:ovpn, cv:from-package-manager, sc:false, completed
  run:windows-2022, vpn:ovpn, cv:1.3.3637.72, sc:true, completed
  run:windows-2022, vpn:ovpn, cv:1.3.3637.72, sc:false, completed
  run:windows-2022, vpn:wg, cv:from-package-manager, sc:true, completed
  run:windows-2022, vpn:wg, cv:from-package-manager, sc:false, completed
  run:windows-2022, vpn:wg, cv:1.3.3637.72, sc:true, completed
  run:windows-2022, vpn:wg, cv:1.3.3637.72, sc:false, completed
  run:windows-2019, vpn:ovpn, cv:from-package-manager, sc:true, completed
  run:windows-2019, vpn:ovpn, cv:from-package-manager, sc:false, completed
  run:windows-2019, vpn:ovpn, cv:1.3.3637.72, sc:true, completed
  run:windows-2019, vpn:ovpn, cv:1.3.3637.72, sc:false, completed
  run:windows-2019, vpn:wg, cv:from-package-manager, sc:true, completed
  run:windows-2019, vpn:wg, cv:from-package-manager, sc:false, completed
  run:windows-2019, vpn:wg, cv:1.3.3637.72, sc:true, completed
  run:windows-2019, vpn:wg, cv:1.3.3637.72, sc:false, completed
  ```
</details>

_Tested working on **`Pritunl v1.32.3602.80`** Server._

## Usage

The configuration is declarative and relatively simple to use.

### Inputs

```yaml
- uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    # REQUIRED: Pritunl Profile File
    # TYPE: Wrapping String (Base64 text format)
    profile-file: ''

    # OPTIONAL: Profile Pin
    # TYPE: String (Numerical values)
    # If not supplied, which defaults No Pin.
    profile-pin: ''

    # OPTIONAL: VPN Connection Mode
    # TYPE: String
    # CHOICES: ['ovpn', 'openvpn', 'OpenVPN'] or ['wg', 'wireguard', 'WireGuard']
    # If not supplied, which defaults to 'ovpn'.
    vpn-mode: ''

    # OPTIONAL: Pritunl Client Version
    # TYPE: String (Numerical dot separated identifiers)
    # For example, using the later version `1.3.3637.72`.
    # If not supplied, which defaults to the latest version from the Package Manager.
    client-version: ''

    # OPTIONAL: Start the Connection
    # TYPE: Boolean
    # If not supplied, which defaults to `true`.
    # If `true` the VPN connection starts within the setup step.
    start-connection: ''
```

> Kindly check the subsection [Working with Pritunl Profile File](#working-with-pritunl-profile-file) on converting `tar` archive file format to `base64` text file format for the `profile-file` input.

### Outputs

`client-id` - This is the randomly generated ID that appears on the Pritunl client after setting up a profile.

_Output Parameter Retrieving Example:_

```sh
${{ steps.pritunl-connection.outputs.client-id }}
```

Where the `pritunl-connection` is the Step Setup ID.

> Kindly check the subsection [Manually Controlling the Connection](#and-even-manually-controlling-the-connection) for example.


## Examples

We have different example scenarios; any combination is possible as long the required `profile-file` input is supplied.

### Minimum Working Configuration

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
```

_Then your other steps down below._

```yml
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

### If the connection requires a Pin/Password

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-pin: ${{ secrets.PRITUNL_PROFILE_PIN }}
```


### Or using a Specific Version of the Client and a WireGuard for the VPN Mode

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-pin: ${{ secrets.PRITUNL_PROFILE_PIN }}
    client-version: '1.3.3637.72'
    vpn-mode: 'wg'
```

### And even Manually Controlling the Connection

```yml
- name: Setup Pritunl Profile
  id: pritunl-connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    start-connection: false # Do not establish a connection in this step.

- name: Starting a VPN Connection Manually
  run: |
    pritunl-client start ${{ steps.pritunl-connection.outputs.client-id }} \
      --password ${{ secrets.PRITUNL_PROFILE_PIN }}

- name: Show VPN Connection Status Manually
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
      $(
        pritunl-client list |
          awk -F '|' 'NR==4{print $8}' |
          xargs ipcalc |
          awk 'NR==6{print $2}'
      )

- name: Stop VPN Connection Manually
  if: ${{ always() }}
  run: |
    pritunl-client stop ${{ steps.pritunl-connection.outputs.client-id }}
```

### Overriding default wait established connection timeout

```yml
- name: Setup Pritunl Profile
  id: pritunl-connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
  env:
    CONNECTION_TIMEOUT: 60 # Example of wait established connection timeout for 60 seconds.
```

## Working with Pritunl Profile File

The Pritunl Client CLI won't allow us to load profiles from the plain `ovpn` file, and GitHub doesn't have a feature to upload binary files such as the `tar` archive file for the GitHub Actions Secrets.

To store Pritunl Profile to GitHub Secrets, maintaining the raw state of the `tar` archive file format, we need to convert it to `base64` text file format.

### Here are the steps

#### 1. Download the Pritunl Profile File obtained from the Pritunl User Profile Page

```bash
curl -sL https://vpn.domain.tld/key/xxxxxxxxxxxxxx.tar \
  -o ./pritunl.profile.tar
```

#### 2. Convert your Pritunl Profile File from `tar` archive file format to `base64` text file format.

```bash
base64 -w 0 ./pritunl.profile.tar > ./pritunl.profile.base64
```

#### 3. Copy the data from `base64` text file format.

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

_Or you can easily access the file data by opening it with your preferred code editor:_

```bash
code ./pritunl.profile.base64 # or,
vim ./pritunl.profile.base64
```

Then, copy the entire `base64` text data.

#### 4. Create a GitHub Action Secret and put the value from entire `base64` text data.
Such as Secrets Key `PRITUNL_PROFILE_FILE` from the [Examples](#examples).
