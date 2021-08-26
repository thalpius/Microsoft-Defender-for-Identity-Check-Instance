# Microsoft-Defender-for-Identity-Check-Instance

This script gets all accepted domains in Microsoft 365 using autodiscover, gets the tenant name and checks if there is a Microsoft Defender for Identity instance. This way you can figure out if a company runs Microsoft Defender for Identity.

# Example

Import-Module Invoke-MicrosoftDefenderForIdentityCheckInstance.psm1

Invoke-MicrosoftDefenderForIdentityCheckInstance -domain thalpius.com

# Screenshots

When an MDI instance is found:

![Alt text](/Screenshots/Microsoft-Defender-for-Identity-Check-Instance-01.jpg?raw=true "Instance running")

When an MDI instance is not found:

![Alt text](/Screenshots/Microsoft-Defender-for-Identity-Check-Instance-02.jpg?raw=true "Instance not running")
