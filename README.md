# Pritunl Client GitHub Action

Establish a [Pritunl VPN](https://pritunl.com/) connection using [Pritunl Client](https://client.pritunl.com/) supporting [OpenVPN](https://openvpn.net/) (ovpn) and [WireGuard](https://www.wireguard.com/) (wg) modes on [GitHub Actions](https://github.com/features/actions).

This utility helps you with tasks like automated internal endpoint testing, periodic backups, builds distribution for cross-platform multi-architecture platforms, and anything that requires private access inside the corporate infrastructure using Pritunl VPN Enterprise Servers.

## Action Diagram

![Diagram](action.dio.svg)

> [!NOTE]
> _The [diagram](./action.dio.svg) above is an editable vector image using [drawio](https://www.drawio.com/) app._

## Connection Tests


[![Connection Tests - Basic](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-basic.yml/badge.svg?branch=main)](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-basic.yml?query=branch:main)
[![Connection Tests - Complete](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-complete.yml/badge.svg?branch=main)](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-complete.yml?query=branch:main)
[![Connection Tests - Multi Server Profile](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-multi-server-profile.yml/badge.svg?branch=main)](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-multi-server-profile.yml?query=branch:main)
[![Connection Tests - Manual (README Example)](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-manual-readme-example.yml/badge.svg?branch=main)](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-manual-readme-example.yml?query=branch:main)
[![Connection Tests - Arm64](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-arm64.yml/badge.svg?branch=main)](https://github.com/nathanielvarona/pritunl-client-github-action/actions/workflows/connection-tests-arm64.yml?query=branch:main)

Compatibility and Common [Issues](https://github.com/nathanielvarona/pritunl-client-github-action/issues?q=is:issue) between the Runners and VPN Mode.

Runner                              | OpenVPN                | WireGuard
------------------------------------|------------------------|-----------------------
`ubuntu-22.04`                      | :white_check_mark: yes | :white_check_mark: yes
`ubuntu-20.04`                      | :white_check_mark: yes | :white_check_mark: yes
`macos-13`                          | :white_check_mark: yes | :white_check_mark: yes
`macos-13-xlarge` <sup>arm64*</sup> | :white_check_mark: yes | :white_check_mark: yes
`macos-12`                          | :white_check_mark: yes | :white_check_mark: yes
`windows-2022`                      | :white_check_mark: yes | :white_check_mark: yes
`windows-2019`                      | :white_check_mark: yes | :white_check_mark: yes

> [!TIP]
> Kindly check out the comprehensive connection tests matrix available on our [GitHub Actions](https://github.com/nathanielvarona/pritunl-client-github-action/actions) page.

_As of the most recent updates and releases, we have confirmed compatibility with [Pritunl v1.32.3805.95](https://github.com/pritunl/pritunl/releases/tag/1.32.3805.95) Server through rigorous testing. Server clusters are deployed on both [AWS](https://aws.amazon.com/), [Azure](https://azure.microsoft.com/) and [Linode (Akamai)](https://www.linode.com/) cloud platforms._

## Usage

The configuration is declarative and relatively simple to use.

### Inputs

```yaml
- name: Pritunl Client GitHub Action
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: '' # REQUIRED: Pritunl Profile File (Base64 text format)
    profile-pin: '' # OPTIONAL: Profile Pin (Numerical values, default: no pin)
    profile-server: '' # OPTIONAL: Profile Server (Single string or comma-separated for multiple names, default: first or only server in the profile)
    vpn-mode: '' # OPTIONAL: VPN Connection Mode ( choices: 'ovpn', 'openvpn', 'OpenVPN', 'wg', 'wireguard', 'WireGuard', default: 'ovpn')
    client-version: '' # OPTIONAL: Pritunl Client Version (Numerical dot-separated identifiers, default: latest version from Package Manager)
    start-connection: '' # OPTIONAL: Start the Connection (Boolean, default: true)
    ready-profile-timeout: '' # OPTIONAL: Ready Profile Timeout (Natural Numbers, unit of time in seconds, default: 3)
    established-connection-timeout: '' # OPTIONAL: Established Connection Timeout (Natural Numbers, unit of time in seconds, default: 30)
```

> [!IMPORTANT]
> Kindly check the subsection [Working with Pritunl Profile File](#working-with-pritunl-profile-file) on converting `tar` archive file format to `base64` text file format for the `profile-file` input.

### Outputs

* `client-id` — a string representing the primary client ID, which is a single identifier generated during the profile setup process.
* `client-ids` — a JSON array containing all client IDs and names in the profile, with each entry represented as a key-value pair (e.g., `{ "name": "profile_name", "id": "client_id" }`).

The step output retrieving examples are:
* `${{ steps.pritunl-connection.outputs.client-id }}`, for the primary client ID.
* `${{ steps.pritunl-connection.outputs.client-ids }}`, for the list of client IDs.

_Note: `pritunl-connection` refers to the `Setup Step ID`._

> [!TIP]
> Please see the subsection [Manually Controlling the Connection](#and-even-manually-controlling-the-connection) for an example of using `client-id`.

> [!IMPORTANT]
> See also the workflow file [connection-tests-complete.yml](./.github/workflows/connection-tests-complete.yml) for a complete tests matrix example, including the usage of `client-ids` output.


## Examples

Provided that `profile-file` is available, we have the flexibility to generate multiple scenarios.

### Minimum Working Configuration

For a basic working configuration, you need to set the profile file and the action automatically starts a connection. Here's an example:

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
```

<details>
  <summary>
    Then your other steps are below.
  </summary>

```yml
- name: Your CI/CD Core Logic
  shell: bash
  run: |
    cat <<EOF
      ##
      # EXAMPLES:
      #   * Integration Test,
      #   * End-to-End Test,
      #   * Endpoint Reachability Test,
      #   * Backup Tasks,
      #   * And more.
      ##
    EOF

- name: Example Cypress E2E Test
  uses: cypress-io/github-action@v5
    working-directory: e2e
```
</details>


> [!TIP]
> Kindly check the GitHub Action workflow file [connection-tests-basic.yml](./.github/workflows/connection-tests-basic.yml) for the basic running example.

### If the connection requires a PIN or a Password

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-pin: ${{ secrets.PRITUNL_PROFILE_PIN }}
```

### If the profile has multiple servers and want to specify one or more

You can connect to a specific server by specifying its name.

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-server: qa-team
```

The feature allows us to connect to multiple servers by their names, separated by commas.

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-server: qa-team, dev-team
```

You can use the full profile name as well, it is also acceptable.

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-server: cicd.automation (qa-team), cicd.automation (dev-team)
```

> [!TIP]
> Kindly check the GitHub Action workflow file [connection-tests-multi-server-profile.yml](./.github/workflows/connection-tests-multi-server-profile.yml) for the multi-server profile connections example.

### Or using a Specific Version of the Client and a WireGuard for the VPN Mode

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    client-version: 1.3.3814.40
    vpn-mode: wg
```

### And even Manually Controlling the Connection

```yml
- name: Setup Pritunl Profile
  id: pritunl-connection # A `Setup Step ID` has been added as a reference identifier for the output `client-id`.
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    start-connection: false # Do not establish a connection in this step.

- name: Starting a VPN Connection Manually
  shell: bash
  run: |
    # Starting a VPN Connection Manually

    pritunl-client start ${{ steps.pritunl-connection.outputs.client-id }} \
      --password ${{ secrets.PRITUNL_PROFILE_PIN || '' }}

- name: Show VPN Connection Status Manually
  shell: bash
  run: |
    # Show VPN Connection Status Manually

    sleep 10
    pritunl-client list -j | jq 'sort_by(.name) | .[0] | { "Profile Name": .name, "Client Address": .client_address }'

- name: Your CI/CD Core Logic
  shell: bash
  run: |
    # Your CI/CD Core Logic

    ##
    # Below is our simple example for VPN connectivity test.
    ##

    # Install IP Calculator
    if [ "$RUNNER_OS" == "Linux" ]; then
      sudo apt-get install -qq -o=Dpkg::Use-Pty=0 -y ipcalc
    elif [ "$RUNNER_OS" == "macOS" ]; then
      brew install -q ipcalc
    elif [ "$RUNNER_OS" == "Windows" ]; then
      # Retry up to 3 times in case of failure
      for attempt in $(seq 3); do
        if curl -sSL "https://raw.githubusercontent.com/kjokjo/ipcalc/0.51/ipcalc" \
          -o $HOME/bin/ipcalc && chmod +x $HOME/bin/ipcalc; then
          break
        else
          echo "Attempt $attempt failed. Retrying..." && sleep 1
          # If all retries fail, exit with an error
          if [ $attempt -eq 3 ]; then
            echo "Failed to install ipcalc after 3 attempts." && exit 1
          fi
        fi
      done
    fi

    # Validate the IP Calculator Installation
    echo "ipcalc version $(ipcalc --version)"

    # VPN Gateway Reachability Test
    ping_count_number=5
    profile_ip=$(pritunl-client list -j | jq -r 'sort_by(.name) | .[0].client_address')

    vpn_gateway="$(ipcalc $profile_ip | awk 'NR==6{print $2}')"
    ping_flags="$([[ "$RUNNER_OS" == "Windows" ]] && echo "-n $ping_count_number" || echo "-c $ping_count_number")"

    # Ping VPN Gateway
    ping $vpn_gateway $ping_flags

- name: Stop VPN Connection Manually
  if: ${{ always() }}
  shell: bash
  run: |
    # Stop VPN Connection Manually

    pritunl-client stop ${{ steps.pritunl-connection.outputs.client-id }}
```

> [!TIP]
> Kindly check the GitHub Action workflow file [connection-tests-manual-readme-example.yml](./.github/workflows/connection-tests-manual-readme-example.yml) for the readme example manual test.

## Working with Pritunl Profile File

The Pritunl Client CLI won't allow us to load profiles from the plain `ovpn` file, and GitHub doesn't have a feature to upload binary files such as the `tar` archive file for the GitHub Actions Secrets.

To store Pritunl Profile to GitHub Secrets, maintaining the raw state of the `tar` archive file format, we need to convert it to `base64` text file format.

### Here are the four steps

#### 1. Download the `Profile File` from the `User Profile Page` or obtain it from your `Infrastructure Team`.

_If the `Infrastructure Team` provided you with a `tar` file, proceed to `Step 2`._

```bash
curl -sSL https://vpn.domain.tld/key/a1b2c3d4e5.tar -o ./pritunl.profile.tar
```

#### 2. Convert your Pritunl Profile File from `tar` archive file format to `base64` text file format.

```bash
base64 --wrap 0 ./pritunl.profile.tar > ./pritunl.profile.base64
```

#### 3. Copy the data from `base64` text file format.

```bash
# For macOS:
# Using `pbcopy`
cat ./pritunl.profile.base64 | pbcopy

# For Linux:
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

### One-liner shorthand script

<details>
  <summary>
    Show the one-liner shorthand script for the first three steps.
  </summary>

```bash
# For macOS
encode_profile_and_copy() { curl -sSL $1 | base64 -w 0 | pbcopy }
# For Linux
encode_profile_and_copy() { curl -sSL $1 | base64 -w 0 | xclip -selection clipboard } # Or,
encode_profile_and_copy() { curl -sSL $1 | base64 -w 0 | xsel --clipboard --input }

# Usage
encode_profile_and_copy https://vpn.domain.tld/key/a1b2c3d4e5.tar
```
</details>

## Supported Arm64 Architecture Runners

> [!TIP]
> Kindly check the GitHub Action workflow file [connection-tests-arm64.yml](./.github/workflows/connection-tests-arm64.yml) for the Arm64 running example.

> [!WARNING]
> <sup>arm64*</sup> — _"These runner will always be charged for, including in public repositories."_
>
> For a comprehensive overview of your billing details, we recommend starting with the "[About billing for GitHub Actions](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions)" page for thorough insights.

## Development and Contribution

If you have any suggestions for improvement, please don't hesitate to fork the project and submit a Pull Request.

### An example of using your fork
```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: <YOUR GITHUB USERNAME>/pritunl-client-github-action@<YOUR FEATURE BRANCH>
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    ...
    <YOUR FEATURE INPUTS>
    ...
```

## Star History

<a href="https://star-history.com/#nathanielvarona/pritunl-client-github-action&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=nathanielvarona/pritunl-client-github-action&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=nathanielvarona/pritunl-client-github-action&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=nathanielvarona/pritunl-client-github-action&type=Date" />
 </picture>
</a>
