<#
.SYNOPSIS
This script connects to Microsoft Graph, fetches unique users from the Intune Managed Devices, and exports their device and app details to a CSV file.

.DESCRIPTION
This script first checks if the Microsoft.Graph.authentication module is installed, if not it will try to install it. It then establishes a connection to the Microsoft Graph using specific scopes.
It fetches a list of unique users from Intune Managed Devices and for each user, it fetches their managed device IDs. 
For each managed device ID, it fetches detailed information about the device and the apps installed on the device.
This information is then written to a CSV file at the path c:\temp\UserDeviceAppId.csv

.NOTES
Author: Costa Yannakis
Date: 17 June 2023
#>

$ErrorActionPreference = "Continue"

# Check if the Microsoft.Graph.authentication module is installed
if (Get-Module -ListAvailable -Name Microsoft.Graph.authentication) {
    Write-Host "Microsoft Graph Already Installed"
} 
else {
    # If not, attempt to install the module
    try {
        Install-Module -Name Microsoft.Graph.authentication -Scope CurrentUser -Repository PSGallery -Force 
    }
    catch [Exception] {
        $_.message 
        exit
    }
}

# Import the authentication module
Import-Module microsoft.graph.authentication

# Select the Beta profile for Microsoft Graph
Select-MgProfile -Name Beta

# Connect to Microsoft Graph with necessary scopes
Connect-MgGraph -Scopes DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, openid, profile, email, offline_access

# Connect to Microsoft Graph
Connect-MsGraph

# Fetch list of users to check from Intune Managed Devices
$userstocheck = Get-IntuneManagedDevice|Select userPrincipalName

# Create a unique list of user principal names
$userstocheckUnique = $userstocheck.userPrincipalName |Sort-Object -Unique

# Initialize the count variable
$count = 0

# Set up the CSV file with header
Set-Content -Path c:\temp\UserDeviceAppId.csv -Value "Username,DeviceID,AppID,AppName,AppVersion,Enrolled,LastSync,DeviceName"

# Iterate through each unique user
foreach ($user in $userstocheckUnique)
{
    $count
    $count+=1
    if(10 -lt $user.Length)
    {   
        "_____________________________________"
        $user
        "_____________________________________"

        # Fetch device IDs for the current user
        $devID = Get-MgDeviceManagementManagedDevice -Filter "userPrincipalName eq '$user'"| Select-Object Id

        $newDevIDs= $devID.Id

        $newDevIDs

        # Iterate through each device ID
        foreach($id in $newDevIDs)
        {
            # Get device details for the current device ID
            $deviceDetails = Get-IntuneManagedDevice -managedDeviceId $id

            # Construct the request URI
            $uri = "https://graph.microsoft.com/beta/deviceManagement/manageddevices('$id')?`$expand=detectedApps"

            # Fetch the list of apps on the current device
            $appsfound = (Invoke-MgGraphRequest -uri $uri -Method GET -OutputType PSObject).detectedApps

            # Iterate through each app
            foreach ($app in $appsfound)
            {
                # Prepare the row data for the CSV
                $row = $user + "," + $id + "," + $app

            add-Content -Path c:\temp\UserDeviceAppId.csv -Value $row
 
                            $app.DisplayName

   }}


}

}
