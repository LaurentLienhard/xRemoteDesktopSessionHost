Import-Module -Name "$PSScriptRoot\..\..\Modules\xRemoteDesktopSessionHostCommon.psm1"
if (!(Test-xRemoteDesktopSessionHostOsRequirement))
{
    throw "The minimum OS requirement was not met."
}
Import-Module RemoteDesktop
$localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName

#######################################################################
# The Get-TargetResource cmdlet.
#######################################################################
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]$Ensure = 'Present',
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,256)]
        [string] $CollectionName,
        [Parameter()]
        [string] $ConnectionBroker
    )

    $script:CollectionExist = $false
    $script:SessionHostExist = $false
    $script:ConnectionAllow = $false
    Write-Verbose "Getting information about RDSH collection"
    Write-Verbose "Test if Collection $($CollectionName) exist"
    if ($Collection = Get-RDSessionCollection -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue | Where-Object CollectionName -eq $CollectionName) {
        Write-Verbose "Collection $($CollectionName) exist"
        $script:CollectionExist = $true
        if ($ensure -eq "Present") {
            Write-Verbose "Test if sessionhost $($SessionHost) is present"
        } else {
            Write-Verbose "Test if sessionhost $($SessionHost) is absent"
        }
    }
    @{
        "CollectionName" = $Collection.CollectionName
    }
}
