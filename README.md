# Pritunl Client GitHub Action

Establish automated secure [Pritunl VPN](https://pritunl.com/) connections with [Pritunl Client](https://client.pritunl.com/) in [GitHub Actions](https://github.com/features/actions), supporting [OpenVPN](https://openvpn.net/) and [WireGuard](https://www.wireguard.com/).

Simplify your workflow, strengthen security, and safeguard access to corporate resources and infrastructure. This utility ensures secure connections, protecting your organization's valuable assets and data.

Streamline tasks such as:

* Securely distribute cross-platform, multi-architecture builds across teams, including corporate internal custom desktop and mobile applications, custom embedded software, firmware, server applications, and single-board computer operating system images.
* Ensure secure access to corporate infrastructure private resources, including internal file storage solutions such as SharePoint, Samba, and NFS shares.
* Automate end-to-end testing of internal and private systems, including applications and data interfaces.
* Ensure data safety and resource availability with regular, periodic schedule operations for internal resources, including backups.

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

### Compatibility Matrix

Check the compatibility of various runners and VPN modes:

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
> * See  the workflow file [connection-tests-complete.yml](./.github/workflows/connection-tests-complete.yml) for a complete tests matrix example.
> * View the comprehensive connection tests matrix on our [GitHub Actions](https://github.com/nathanielvarona/pritunl-client-github-action/actions) page for more details.

### Confirmed Compatibility
We have confirmed compatibility with [Pritunl v1.32.3805.95](https://github.com/pritunl/pritunl/releases/tag/1.32.3805.95) and later versions through rigorous testing. Our server clusters are deployed across multiple cloud platforms, including [AWS](https://aws.amazon.com/), [Azure](https://azure.microsoft.com/) and [Linode (Akamai)](https://www.linode.com/).


## Usage

Configure the **Pritunl Client GitHub Action** using a declarative syntax, making it easy to integrate and manage your VPN connections.

### Inputs

Provides input parameters for the **Pritunl Client GitHub Action**, allowing users to customize the setup process and connection settings.

```yaml
- name: Pritunl Client GitHub Action
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ''  # REQUIRED: Pritunl Profile File (Base64 text format)
      # Description: Provide the Base64-encoded Pritunl profile file contents.

    profile-pin: ''  # OPTIONAL: Profile Pin (Numerical values, default: no pin)
      # Description: Specify a numerical pin for the profile (if required).

    profile-server: ''  # OPTIONAL: Profile Server (Single string or comma-separated for multiple names, default: first or only server in the profile)
      # Description: Specify the profile server(s) to connect to.

    vpn-mode: ''  # OPTIONAL: VPN Connection Mode (choices: 'ovpn', 'openvpn', 'OpenVPN', 'wg', 'wireguard', 'WireGuard', default: 'ovpn')
      # Description: Select the VPN connection mode.

    client-version: ''  # OPTIONAL: Pritunl Client Version (Numerical dot-separated identifiers, default: latest version from Package Manager)
      # Description: Specify the Pritunl client version to use.

    start-connection: ''  # OPTIONAL: Start the Connection (Boolean, default: true)
      # Description: Set to 'false' to prevent the connection from starting automatically.

    ready-profile-timeout: ''  # OPTIONAL: Ready Profile Timeout (Natural Numbers, unit of time in seconds, default: 3)
      # Description: Set the timeout for the profile to become ready.

    established-connection-timeout: ''  # OPTIONAL: Established Connection Timeout (Natural Numbers, unit of time in seconds, default: 30)
      # Description: Set the timeout for the connection to become established.

    concealed-outputs: ''  # OPTIONAL: Concealed Outputs (Boolean, default: true)
      # Description: Set to 'false' to reveal sensitive output information.
```

> [!IMPORTANT]
> For the `profile-file` input, ensure you convert the `tar` archive file format to `base64` text file format. Refer to the [Working with Pritunl Profile File](#working-with-pritunl-profile-file) subsection for guidance.

### Outputs

Outputs essential variables from **Pritunl Client** setup, supporting and extending automation, integration, and audit processes.

* `client-id` — a unique string identifier generated during the profile setup process.
  + Example:
    ```text
    6p5yiqbkjbktkrz5
    ```

* `client-ids` — a JSON array containing all client IDs and names in the profile, with each entry represented as a key-value pair.
  + Format _(elements)_:
    ```json
    {"id":"client-id","name":"profile-name (server-name)"}
    ```
  + Example _(single entry)_:
    ```json
    [{"id":"6p5yiqbkjbktkrz5","name":"gha-automator-dev (dev-team)"}]
    ```
  + Example _(multiple entries)_:
    ```json
    [{"id":"kp4kx4zbcqpsqkbk","name":"gha-automator-qa2 (dev-team)"},{"id":"rsy6npzw5mwryge2","name":"gha-automator-qa2 (qa-team)"}]
    ```

#### Retrieving Step Outputs

* To retrieve the `client-id`:
  ```
  ${{ steps.pritunl-connection.outputs.client-id }}
  ```

* To retrieve the `client-ids`:
  ```
  ${{ steps.pritunl-connection.outputs.client-ids }}
  ```

> [!NOTE]
> The `pritunl-connection` refers to the **Setup Step ID**. Make sure to replace it with the actual step ID in your workflow._

> [!TIP]
> * See "[Manual Connection Control](#manual-connection-control)" for an example of using `client_id`.
> * See "[Specifying Server or Servers in a Multi-Server Profile](#specifying-server-or-servers-in-a-multi-server-profile)" for examples of using `client_ids`.
> * See "[Controlling Step Outputs Visibility in GitHub Actions Log](#controlling-step-outputs-visibility-in-github-actions-log)" by setting `concealed-outputs`.



## Examples

Provided that `profile-file` is available, we have the flexibility to generate multiple scenarios.

### Minimum Working Configuration

Establish a VPN connection with just a few lines of code! Simply set the required `profile-file` input, and let the action handle the rest.

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
```

> [!TIP]
> See a working example of this action in our [connection-tests-basic.yml](./.github/workflows/connection-tests-basic.yml). This example demonstrates a basic setup and connection test.

### Authenticate with PIN or Password

If your VPN connection requires authentication, use the `profile-pin` input to provide a PIN or password.

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-pin: ${{ secrets.PRITUNL_PROFILE_PIN }}
```

### Specifying Server or Servers in a Multi-Server Profile

Select one or more servers by specifying their names. You can use:

* Short name: A concise name (e.g., `dev-team`)
* Short name with multiple servers: Separate multiple short names with commas (e.g., `dev-team, qa-team`)
* Full profile name: A complete name with the profile and server (e.g., `gha-automator-qa1 (dev-team)`)
* Full profile name with multiple servers: Separate multiple full profile names with commas (e.g., `gha-automator-qa1 (dev-team), gha-automator-qa1 (qa-team)`)

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    profile-server: dev-team # Specify a single server using its short name
    # profile-server: dev-team, qa-team # Connect to multiple servers using short names
    # profile-server: gha-automator-qa1 (dev-team) # Use a full profile name to specify a single server
    # profile-server: gha-automator-qa1 (dev-team), gha-automator-qa1 (qa-team) # Use full profile names to specify multiple servers
```

> [!TIP]
> See an example of connecting to multiple servers in our [connection-tests-multi-server-profile.yml](./.github/workflows/connection-tests-multi-server-profile.yml) file. This workflow demonstrates how to configure and test connections to multiple servers using a single profile.

### Specify Client Version

Use a specific version of the Pritunl client.

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    client-version: 1.3.3814.40
```

### Specify VPN Mode

Use a specific VPN mode (e.g., WireGuard).

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    vpn-mode: wg
```

### Manual Connection Control

Demonstrates manual control over the VPN connection, including starting, stopping, and checking the connection status.

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
> See a working example of manual connection control in our [connection-tests-manual-readme-example.yml](./.github/workflows/connection-tests-manual-readme-example.yml) for the readme example manual test.

### Controlling Step Outputs Visibility in GitHub Actions Log

By default, step outputs are hidden in the GitHub Actions log to keep it clean and clutter-free. To reveal step outputs, set `concealed-outputs` to `false`.

```yml
- name: Setup Pritunl Profile and Start VPN Connection
  uses: nathanielvarona/pritunl-client-github-action@v1
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    concealed-outputs: false # Set to false to reveal step outputs in the GitHub Actions log
```

## Working with Pritunl Profile File

The Pritunl Client CLI requires a specific file format, and GitHub has limitations on uploading binary files. To store the Pritunl Profile in GitHub Secrets, we need to convert the `tar` archive file to a `base64` text file format.

### Four Easy Steps

#### 1. Obtain the Profile File

Download the `Profile File` from the User `Profile Page` or obtain it from your `Infrastructure Team`. If you receive a `tar` file, proceed to `Step 2`.

```bash
curl -sSL https://vpn.domain.tld/key/a1b2c3d4e5.tar -o ./pritunl.profile.tar
```

#### 2. Convert to Base64

Convert the Pritunl Profile File from `tar` archive file format to `base64` text file format.

```bash
base64 --wrap 0 ./pritunl.profile.tar > ./pritunl.profile.base64
```

#### 3. Copy the Base64 Data

Copy the contents of the base64 text file format.

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

Alternatively, open the file in a code editor and copy the contents

```bash
code ./pritunl.profile.base64 # or,
vim ./pritunl.profile.base64
```

Then, copy the entire `base64` text data.

#### 4. Create a GitHub Action Secret

Create a GitHub Action Secret (e.g., `PRITUNL_PROFILE_FILE`) and paste the entire `base64` text data as the secret value.

<details>
  <summary>Pro Tip: One-liner Shorthand Script</summary>

  Use this handy one-liner script to simplify the first three steps:

  ```bash
  # For macOS
  encode_profile_and_copy() { curl -sSL $1 | base64 -w 0 | pbcopy }

  # For Linux
  encode_profile_and_copy() { curl -sSL $1 | base64 -w 0 | xclip -selection clipboard } # Or,
  encode_profile_and_copy() { curl -sSL $1 | base64 -w 0 | xsel --clipboard --input }

  # Usage
  encode_profile_and_copy https://vpn.domain.tld/key/a1b2c3d4e5.tar
  ```

  This script combines the steps of downloading the profile, converting to base64, and copying to the clipboard into a single command. Just replace the URL with your profile link!

</details>

## Supported Arm64 Architecture Runners

Supports GitHub Actions runners with Arm64 architecture, enabling users to run workflows on Arm64-based systems.

> [!WARNING]
> <sup>arm64*</sup> — Arm64 runners incur usage charges, even in public repositories. Please note that these charges apply to your account.

> [!TIP]
> See an example of Arm64 support in our [connection-tests-arm64.yml](./.github/workflows/connection-tests-arm64.yml) file.

For a detailed understanding of your billing, we recommend reviewing the "[About billing for GitHub Actions](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions)" page.

## Contributing

Thank you for your interest in contributing to our project! We appreciate your help in making our project better.

### Fork and Pull Requests

1. Fork our repository to your own GitHub account.
2. Make changes, additions, or fixes on your forked repository.
3. Send a pull request to our original repository.

### Rebasing and Squashing Commits

1. Rebase your branch on top of the latest main branch before submitting a pull request.
2. Squash your commits into a single, meaningful commit.

### Modify and Test Your Fork

**Modify the main files:**

* [action.yml](./action.yml) — GitHub Action Metadata File and Inline Entrypoint Script for `pritunl-client.sh`.
* [pritunl-client.sh](./pritunl-client.sh) — Pritunl Client Script File, the GitHub Action Logic.


**Test your changes thoroughly:**

Ensure your contributions are reliable by testing your fork using the same GitHub Actions workflows we use for our project. Please update or add new test workflows in the [.github/workflows/](./.github/workflows)`connection-tests-*.yml` files as needed to cover your changes.

#### Use Your Fork

Once you've modified and tested your fork, you can use it in your own projects. Here's an example usage:

```yml
- name: Pritunl Client GitHub Action (Development Fork)
  uses: <YOUR GITHUB USERNAME>/pritunl-client-github-action@<YOUR FEATURE BRANCH>
  with:
    profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
    ...
    <YOUR FEATURE INPUTS>
    ...
```

### Documentation

When contributing to our project, please make sure to document your features or changes in the following ways:

* Update the [README.md](./README.md) file to include information about your feature or change.
* Add comments to your code to explain what it does and how it works.
* If necessary, create a new documentation file or update an existing one to provide more detailed information about your feature or change.

### Additional Guidelines

* Be respectful and considerate of others in our community.
* Follow the GitHub Community Guidelines and Anti-Harassment Policy.
* Keep your contributions aligned with our project's goals and scope.

### What to Expect

* Our maintainers will review your pull request and provide feedback.
* We may request changes or improvements before merging your pull request.
* Once approved, your contribution will be merged and credited to you.

Thank you again for your contribution! If you have any questions or concerns, feel free to reach out to us.

## Star History

<a href="https://star-history.com/#nathanielvarona/pritunl-client-github-action&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=nathanielvarona/pritunl-client-github-action&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=nathanielvarona/pritunl-client-github-action&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=nathanielvarona/pritunl-client-github-action&type=Date" />
 </picture>
</a>
