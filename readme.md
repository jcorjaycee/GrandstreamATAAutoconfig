# Grandstream ATA Autoconfig
This is a quick and easy AutoHotkey script for configuring an HT7XX or HT8XX ATA over SSH.

The parameters are accurate as of version 1.0.25.5 for HT8XX

The script will attempt to use plink from PuTTY, if it is placed in the same directory.

Otherwise, it will attempt to install OpenSSH through PowerShell, which requires UAC elevation.