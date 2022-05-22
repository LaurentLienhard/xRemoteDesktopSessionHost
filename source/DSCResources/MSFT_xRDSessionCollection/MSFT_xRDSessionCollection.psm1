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
        [ValidateLength(1, 256)]
        [string] $CollectionName,
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [ValidateSet("YES", "NOUNTILREBOOT", "NO", ignorecase = $true)]
        [String]$NewConnectionAllowed,
        [Parameter()]
        [string] $CollectionDescription,
        [Parameter()]
        [string] $ConnectionBroker
    )

    $script:CollectionExist = $false
    $script:SessionHostExist = $false
    $script:ConnectionAllow = $false
    Write-Verbose "Getting information about RDSH collection"
    Write-Verbose "Test if Collection $($CollectionName) exist"
    if ($Collection = Get-RDSessionCollection -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue | Where-Object CollectionName -eq $CollectionName)
    {
        Write-Verbose "Collection $($CollectionName) exist"
        $script:CollectionExist = $true
        Write-Verbose "Test if server $($SessionHost) is in collection $($CollectionName)"
        if ($Server = Get-RDSessionHost -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue | Where-Object SessionHost -eq $SessionHost)
        {
            Write-verbose "Server $($SessionHost) is in collection $($CollectionName)"
            $script:SessionHostExist = $true
            Write-Verbose "Test New Connection allowed Status "
            if ($Server.NewConnectionAllowed -eq $NewConnectionAllowed)
            {
                Write-verbose "New Connection allowed Status is OK"
                $script:ConnectionAllow = $true
            }
            else
            {
                Write-verbose "New Connection allowed Status is NOK"
            }
        }
        else
        {
            Write-Verbose "Server $($SessionHost) is not in collection $($CollectionName)"
        }
    }
    else
    {
        Write-Verbose "Collection $($CollectionName) does not exist"
    }
    @{
        "CollectionName"        = $Collection.CollectionName
        "CollectionDescription" = $Collection.CollectionDescription
        "SessionHost"           = $Server.SessionHost
        "ConnectionBroker"      = $ConnectionBroker
        "NewConnectionAllowed"  = $Server.NewConnectionAllowed
    }
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
        [ValidateLength(1, 256)]
        [string] $CollectionName,
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [ValidateSet("YES", "NOUNTILREBOOT", "NO", ignorecase = $true)]
        [String]$NewConnectionAllowed,
        [Parameter()]
        [string] $CollectionDescription,
        [Parameter()]
        [string] $ConnectionBroker
    )

    if (!($script:CollectionExist))
    {
        Write-Verbose "Creating a new RDSH collection."
        $PSBoundParameters.Remove('NewConnectionAllowed')
        New-RDSessionCollection @PSBoundParameters
        $script:CollectionExist = $true
    }

    if ($script:CollectionExist -and !($script:SessionHostExist))
    {
        Write-Verbose "Adding server to an existing collection."
        Add-RDSessionHost -CollectionName $CollectionName -SessionHost $SessionHost -ConnectionBroker $ConnectionBroker
        $script:SessionHostExist = $true
    }

    if ($script:CollectionExist -and $script:SessionHostExist -and !($script:ConnectionAllow))
    {
        Write-Verbose "Update connection allow status"
        Set-RDSessionHost -SessionHost $SessionHost -ConnectionBroker $ConnectionBroker -NewConnectionAllowed $NewConnectionAllowed
        $script:ConnectionAllow = $true

    }
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
        [ValidateLength(1, 256)]
        [string] $CollectionName,
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [ValidateSet("YES", "NOUNTILREBOOT", "NO", ignorecase = $true)]
        [String]$NewConnectionAllowed,
        [Parameter()]
        [string] $CollectionDescription,
        [Parameter()]
        [string] $ConnectionBroker
    )
    Write-Verbose "Checking for existence of RDSH collection."
    $currentConfiguration = Get-TargetResource @PSBoundParameters
    $script:CollectionExist -and $script:SessionHostExist -and $script:ConnectionAllow
}


Export-ModuleMember -Function *-TargetResource
