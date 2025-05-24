# linux-ad-integration-diagnose

> Diagnose and troubleshoot Active Directory (AD) integration issues on Linux systems.  
> LinuxシステムのActive Directory (AD) 連携の問題を診断するスクリプトです。

## Features

- Check realm join status
- Inspect Kerberos ticket and keytab file
- Validate SSSD service and configuration
- Verify DNS SRV records for AD domain
- Show nsswitch.conf and PAM hints
- Hostname and DNS consistency checks

## Usage

```bash
chmod +x ad_diagcheck.sh
sudo ./ad_diagcheck.sh
```

## Requirements
bash

realm, klist, dig, systemctl, getent

AD integration components (sssd, oddjob, etc.) should already be installed

## Purpose
This script is intended for:

- Troubleshooting failed AD logins
- Verifying if Kerberos/SSSD/DNS/keytab are functioning properly
- Supporting system administrators diagnosing AD integration issues

## Author
momogitater

## License
MIT
