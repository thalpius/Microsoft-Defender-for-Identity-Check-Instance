<#
 
.SYNOPSIS
  This script checks if there is a Microsoft Defender for Identity instance created.
 
.DESCRIPTION
 
  This script gets all accepted domains in Microsoft 365 using autodiscover, gets the tenant name
  and checks if there is a Microsoft Defender for Identity instance. This way you can figure out
  if the comapny runs Microsoft Defender for Identity.

  Note: https://docs.microsoft.com/en-us/openspecs/exchange_server_protocols/ms-oxwsadisc/18fe58cd-3761-49da-9e47-84e7b4db36c2

.EXAMPLE

  Invoke-MicrosoftDefenderForIdentityCheckInstance -Domain thalpius.com

.INPUTS
 
  Domain name of the company needs to be provided.
 
.OUTPUTS
 
  Output will be shown in the terminal/console.
 
.NOTES
 
  Version:        0.1
  Author:         R. Roethof
  Creation Date:  08/18/2021
  Website:        https://thalpius.com
  Purpose/Change: Initial script development

#>
 
#-------------------------------------------[Declarations]-----------------------------------------



#--------------------------------------------[Functions]-------------------------------------------

function Get-AcceptedDomains {
    Param(
        [parameter(Mandatory = $true, HelpMessage = "Specify a domain")]
        [ValidateNotNullOrEmpty()]
        [string]$domain
    )
    begin {
        Write-Host "Start getting all accepted domains..." -ForegroundColor Yellow
    }
    process {
        $body = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:exm="http://schemas.microsoft.com/exchange/services/2006/messages" 
        xmlns:ext="http://schemas.microsoft.com/exchange/services/2006/types" 
        xmlns:a="http://www.w3.org/2005/08/addressing" 
        xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <soap:Header>
        <a:RequestedServerVersion>Exchange2010</a:RequestedServerVersion>
        <a:MessageID>urn:uuid:6389558d-9e05-465e-ade9-aae14c4bcd10</a:MessageID>
        <a:Action soap:mustUnderstand="1">http://schemas.microsoft.com/exchange/2010/Autodiscover/Autodiscover/GetFederationInformation</a:Action>
        <a:To soap:mustUnderstand="1">https://autodiscover-s.outlook.com/autodiscover/autodiscover.svc</a:To>
        <a:ReplyTo>
            <a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address>
        </a:ReplyTo>
    </soap:Header>
    <soap:Body>
        <GetFederationInformationRequestMessage xmlns="http://schemas.microsoft.com/exchange/2010/Autodiscover">
            <Request>
                <Domain>$domain</Domain>
            </Request>
        </GetFederationInformationRequestMessage>
    </soap:Body>
</soap:Envelope>
"@
        $headers = @{
            "Content-Type" = "text/xml; charset=utf-8"
            "User-Agent"   = "AutodiscoverClient"
        }

        try {
            $response = Invoke-RestMethod -Method Post -uri "https://autodiscover-s.outlook.com/autodiscover/autodiscover.svc" -Body $body -Headers $headers
        }
        catch {
            Write-Host "  Error: Can not get all accepted domains. Are you sure the domain name is correct?" -ForegroundColor Red
            Read-Host -Prompt "Press Enter to exit"
            exit
        }
        $global:domains = $response.Envelope.body.GetFederationInformationResponseMessage.Response.Domains.Domain
        foreach ($domain in $domains) {
            Write-Host "  $domain"
        }
    }
    end {
        if ($?) {
            Write-host "Start getting all accepted domains completed successfully..." -ForegroundColor Yellow
        }
    }
}

function Get-TenantName {
    Param(
    )
    begin {
        Write-Host "Start getting instance name..." -ForegroundColor Yellow
    }
    process {
        try {
            foreach ($domain in $domains) {
                if ($domain.ToLower() -match "^[^.]*\.onmicrosoft.com$") {
                    $global:tenantName = $domain.Substring(0, $domain.IndexOf("."))
                    Write-Host "  $tenantName"
                }
            }
        }
        catch {
            Write-Host $_.Exception
            exit
        }
    }
    end {
        if ($?) {
            Write-host "Start getting instance name completed successfully..." -ForegroundColor Yellow
        }
    }
}
function Invoke-MicrosoftDefenderForIdentityCheckInstance {
    Param(
        [parameter(Mandatory = $true, HelpMessage = "Specify a domain")]
        [ValidateNotNullOrEmpty()]
        [string]$domain
    )
    begin {
        Write-Host "Check if instance exists..." -ForegroundColor Yellow
        Get-AcceptedDomains -domain $domain
        Get-TenantName
    }
    process {
        try {
            $CheckMicrosoftDefenderForIdentity = Invoke-WebRequest -URI https://$tenantName.atp.azure.com -UseBasicParsing
            if ($CheckMicrosoftDefenderForIdentity.StatusCode -eq 200) {
                Write-Host "  Looks like $tenantName is running an MDI instance on https://$tenantName.atp.azure.com" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  No MDI instance is running on https://$tenantName.atp.azure.com" -ForegroundColor Red
        }
        try {
            $CheckMicrosoftDefenderForIdentity = Invoke-WebRequest -URI https://$tenantName-onmicrosoft-com.atp.azure.com -UseBasicParsing
            if ($CheckMicrosoftDefenderForIdentity.StatusCode -eq 200) {
                Write-Host "  Looks like $tenantName is running an MDI instance on https://$tenantName-onmicrosoft-com.atp.azure.com" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  No MDI instance is running on https://$tenantName-onmicrosoft-com.atp.azure.com" -ForegroundColor Red
        }
    }
    end {
        if ($?) {
            Write-host "Check if instance exists completed successfully..." -ForegroundColor Yellow
        }
    }
}
