<!-- Provide a general summary of your changes in the Title above -->

### Issue Description
<!-- Provide a clear and concise description of the issue you encountered. -->


<!-- ### Steps to Reproduce -->
<!-- If applicable, provide the steps to reproduce the issue. -->

<!-- ### Expected Behavior -->
<!-- If applicable, describe what you expected to happen. -->

<!-- ### Actual Behavior -->
<!-- If applicable, describe what actually happened. -->

<!-- ### Additional Information -->
<!-- If applicable, any additional context or information that might be helpful in resolving the issue. -->

<!--
#### The Logs:
```log
  # Only the setup step, or any related to Pritunl Client steps.
  # SECURITY WARNING: If any sensitive information, you should redact it manually on your side!
```
-->

### It has been used with the following parameters:
<!-- Go over all the following points, and put an `x` in all the boxes that apply. -->
<!-- If you're unsure about any of these, don't hesitate to ask. We're here to help! -->

**Runner Virtual Environments:**
- Linux
  - [ ] Ubuntu 22.04
  - [ ] Ubuntu 20.04
- macOS
  - [ ] macOS 12
  - [ ] macOS 11
- Windows
  - [ ] Windows 2022
  - [ ] Windows 2019

**VPN Modes:**
- [x] OpenVPN (ovpn) <!-- default -->
- [ ] WireGuard (wg)

**Client Versions:**
- [x] Installed from the package manager <!-- default -->
- [ ] Version specific
  <!-- Please specify the versions of the Pritunl Client that you are currently using. -->
  - [ ] 1.3.3637.72

**Start Connection:** *If the connection is started on the setup step.*
- [x] True <!-- default -->
- [ ] False

**Runner Types:**
- [x] Tested on GitHub-hosted runner <!-- only tested working -->
- [ ] Tested on Self-Hosted runner

  *If it runs on a self-hosted runner:*
  - [ ] Manage Self-hosted
  - [ ] Action Runner Controller (ARC) (a Kubernetes Operator)

<!--
#### The GitHub Action Setup
```yml
  - name: Setup Pritunl Profile
      id: pritunl-connection
      uses: nathanielvarona/pritunl-client-github-action@v1
      with:
      profile-file: ${{ secrets.PRITUNL_PROFILE_FILE }}
      profile-pin: ${{ secrets.PRITUNL_PROFILE_PIN }}
      vpn-mode: ###
      client-version: ###
      start-connection: ###
```
-->
