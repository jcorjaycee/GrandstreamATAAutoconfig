# This project is for demonstration and education purposes only. For an actually useful tool, please see here:
https://github.com/seannleckie/GrandstreamATAConfigurator

## Grandstream ATA Autoconfig
This is a quick and easy AutoHotkey script for configuring an HT7XX or HT8XX ATA over SSH. Why AutoHotkey? Two reasons:

1. Portability
2. More importantly, I wanted to learn AHK scripting, and this was a great opportunity.

AHK isn't the optimal scripting language for this, but it was fun to develop and does what I need it to!

The parameters are accurate as of version 1.0.25.5 for HT8XX

The script will attempt to use plink from PuTTY, if it is placed in the same directory.

Otherwise, it will attempt to install OpenSSH through PowerShell, which requires UAC elevation.
