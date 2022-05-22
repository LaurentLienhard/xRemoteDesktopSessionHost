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
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure = 'Present',
        [Parameter()]
        [ValidateSet("YES", "NOUNTILREBOOT", "NO", ignorecase = $true)]
        [String]$NewConnectionAllowed,
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 256)]
        [string] $CollectionName,
        [Parameter()]
        [string] $ConnectionBroker
    )


    Write-Verbose "Get current configuration for SessionHost $($SessionHost)"
    $MyHost = Get-RDSessionHost -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker | where { $_.SessionHost -eq $SessionHost }

    $return = @{
        CollectionName       = $MyHost.CollectionName
        ConnectionBroker     = $ConnectionBroker
        SessionHost          = $MyHost.SessionHost
        NewConnectionAllowed = $MyHost.NewConnectionAllowed
    }

    if ($MyHost)
    {
        $return['Ensure'] = 'Present'
    }
    else
    {
        $return['Ensure'] = 'Absent'
    }

    $return
}

#######################################################################
# The Test-TargetResource cmdlet.
#######################################################################
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure = 'Present',
        [Parameter()]
        [ValidateSet("YES", "NOUNTILREBOOT", "NO", ignorecase = $true)]
        [String]$NewConnectionAllowed = 'YES',
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 256)]
        [string] $CollectionName,
        [Parameter()]
        [string] $ConnectionBroker
    )
    Write-Verbose "test if SessionHost $($SessionHost) is in the expected state"
    $currentConfiguration = Get-TargetResource @PSBoundParameters

    ($currentConfiguration.SessionHost -eq $SessionHost) -and ($currentConfiguration.CollectionName -eq $CollectionName) -and ($currentConfiguration.Ensure -eq $Ensure) -and ($currentConfiguration.NewConnectionAllowed -eq $NewConnectionAllowed) -and ($currentConfiguration.ConnectionBroker -eq $ConnectionBroker)
}

########################################################################
# The Set-TargetResource cmdlet.
########################################################################
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
       [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [ValidateSet('Present','Absent')]
        [string]$Ensure = 'Present',
        [Parameter()]
        [ValidateSet("YES","NOUNTILREBOOT","NO",ignorecase=$true)]
        [String]$NewConnectionAllowed = 'YES',
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,256)]
        [string] $CollectionName,
        [Parameter()]
        [string] $ConnectionBroker
    )

    $currentConfiguration = Get-TargetResource @PSBoundParameters

    #CASE 1 : SessionHost doesn't exist but must be present
    if (!($currentConfiguration.SessionHost) -and ($Ensure -eq "present") )
    {
        Write-Verbose "Add SessionHost $($SessionHost) to collection $($CollectionName)"
        Add-RDSessionHost -CollectionName $CollectionName -SessionHost $SessionHost -ConnectionBroker $ConnectionBroker
        $currentConfiguration['SessionHost'] = $SessionHost
    }

    #CASE 2 : SessionHost exist but must be Absent
    if ($currentConfiguration.SessionHost -and $ensure -eq "Absent")
    {
        Write-Verbose "remove SessionHost $($SessionHost) from collection $($CollectionName)"
        Remove-RDSessionHost -SessionHost $SessionHost -ConnectionBroker $ConnectionBroker -Confirm:$false -Force
        $currentConfiguration['SessionHost'] = ""
    }

    #CASE 3 : SessionHost exist but not in the expected state
    if ($currentConfiguration.SessionHost -and ($currentConfiguration.NewConnectionAllowed -ne $NewConnectionAllowed))
    {
        Write-Verbose "Update SessionHost $($SessionHost) in collection $($CollectionName)"
        Set-RDSessionHost -SessionHost $currentConfiguration.SessionHost -ConnectionBroker $ConnectionBroker -NewConnectionAllowed $NewConnectionAllowed
    }
}
