# PowerShell code
 
########################################################
# Parameters
########################################################
[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,Position=0)]
    [ValidateSet('Start','Stop')]
    [string]$AasAction,
     
    [Parameter(Mandatory=$True,Position=1)]
    [ValidateLength(1,100)]
    [string]$ResourceGroupName,
 
    [Parameter(Mandatory=$True,Position=2)]
    [ValidateLength(1,100)]
    [string]$AnalysisServerName
)
 
# Keep track of time
$StartDate=(GET-DATE) 
 
 
########################################################
# Log in to Azure with AZ (standard code)
########################################################
Write-Verbose -Message 'Connecting to Azure'
  
# Name of the Azure Run As connection
$ConnectionName = 'AzureRunAsConnection'
try
{
    # Get the connection properties
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName      
   
    'Log in to Azure...'
    $null = Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $ServicePrincipalConnection.TenantId `
        -ApplicationId $ServicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$ServicePrincipalConnection)
    {
        # You forgot to turn on 'Create Azure Run As account' 
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else
    {
        # Something else went wrong
        Write-Error -Message $_.Exception.Message
        throw $_.Exception
    }
}
########################################################
  
 
 
########################################################
# Getting the AAS for testing and logging purposes
########################################################
$myAzureAnalysisServer = Get-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $AnalysisServerName
if (!$myAzureAnalysisServer)
{
    Write-Error "$($AnalysisServerName) not found in $($ResourceGroupName)"
    return
}
else
{
    Write-Output "Current status of $($AnalysisServerName): $($myAzureAnalysisServer.State)"
}
 
 
 
########################################################
# Pause or Resume AAS
########################################################
# Check for incompatible actions
if (($AasAction -eq "Start" -And $myAzureAnalysisServer.State -eq "Succeeded") -Or ($AasAction -eq "Stop" -And $myAzureAnalysisServer.State -eq "Paused"))
{
    Write-Error "Cannot $($AasAction) $($AnalysisServerName) while the status is $($myAzureAnalysisServer.State)"
    return
}
# Resume Azure Analysis Services
elseif ($AasAction -eq "Start")
{
    Write-Output "Now starting $($AnalysisServerName)"
    $null = Resume-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $AnalysisServerName
}
# Pause Azure Analysis Services
else
{
    Write-Output "Now stopping $($AnalysisServerName)"
    $null = Suspend-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $AnalysisServerName
}
 
 
 
########################################################
# Show when finished
########################################################
$Duration = NEW-TIMESPAN –Start $StartDate –End (GET-DATE)
Write-Output "Done in $([int]$Duration.TotalMinutes) minute(s) and $([int]$Duration.Seconds) second(s)"