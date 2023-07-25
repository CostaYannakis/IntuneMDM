############
## Reports 1 and 2,3,4  need firstly to have the reports generated in Intune directly, This might be a limitation of the beta version
##############################
# Set Variables

$date = Get-Date

$dateMonth = $date.Month
$dateDay = $date.Day
$dateYear = $date.Year

$deviceUnencryptedString
##############################

#Creates a csv file and headers
function Initialize-CSVHeaders  {
	param (
	  $fileName,
	  $day,
	  $month,
	  $year,
	  $headers
	  )
	
	  $fullFileName = $fileName + "-" + $day + "-"  + $month + "-" + $year + ".csv"
	  Add-Content -Path C:\temp\$fullFileName  -Value $headers
	  return $fullFileName
  }
  
  #Adds content to csv
  function Add-CSVContent {
	param (
	  $fileName,
	  $values
	  )
	
	  Add-Content -Path C:\temp\$fileName  -Value $values
  
  }
  

# Functions adds Date Columns for Time Series Analysis
  function Add-DateDataCsv {
	param (
			$file,$day,$month,$year
		  )
  
	#open the csv
	$csv = Import-Csv c:\temp\$file
	$csv | Select-Object *, @{n=”Year”;e={$year}} | Export-CSV C:\temp\$file -NoTypeInformation
	$csv = Import-Csv c:\temp\$file
	$csv | Select-Object *, @{n=”Month”;e={$month}} | Export-CSV C:\temp\$file -NoTypeInformation
	$csv = Import-Csv c:\temp\$file
	$csv | Select-Object *, @{n=”day”;e={$day}} | Export-CSV C:\temp\$file -NoTypeInformation
  
  }
  

#Converts json to object
function Convert-JsonToObject ($theJson) {
    $powershellObject = ConvertFrom-Json $theJson
  	return $powershellObject
  }


#Connects to MgGraph and assigns the relevant scope
Connect-MgGraph -Scopes "DeviceManagementApps.Read.All,DeviceManagementConfiguration.Read.All,DeviceManagementManagedDevices.Read.All"


<########################### REPORT 1 Windows Feature updates #####################################################################


$params = @{
  Id = "FeatureUpdatePolicyStatusSummary_00000000-0000-0000-0000-000000000002"
  Skip = 0
  Top = 50
  Search = ""
  OrderBy = @()
  Select =  @(
      "PolicyId"
      "PolicyName"
      "CountDevicesInProgressStatus"
      "CountDevicesCancelledStatus"
      "CountDevicesErrorStatus"
      "CountDevicesSuccessStatus"
      "FeatureUpdateVersion"
      "CountDevicesOnHoldStatus"
      "CountDevicesRollbackStatus"
  )
}

$winFeatureUpdates = Get-MgBetaDeviceManagementReportCachedReport -BodyParameter $params -OutFile C:\temp\WFU.txt
$winFeatureUpdatesString = Get-Content C:\temp\WFU.txt
$winFeatureUpdatesObject = Convert-JsonToObject $winFeatureUpdatesString
$winFeatureUpdatesObjectCancelled = $winFeatureUpdatesObject.Values[0][0] + $winFeatureUpdatesObject.Values[1][0]
$winFeatureUpdatesObjectErrors = $winFeatureUpdatesObject.Values[0][1] + $winFeatureUpdatesObject.Values[1][1]
$winFeatureUpdatesObjectInProgress = $winFeatureUpdatesObject.Values[0][2] + $winFeatureUpdatesObject.Values[1][2]
$winFeatureUpdatesObjectSuccess = $winFeatureUpdatesObject.Values[0][5] + $winFeatureUpdatesObject.Values[1][5]

$file = Initialize-CSVHeaders -fileName WFU -day $dateDay -month $dateMonth -year $dateYear -headers "Cancelled,Errors,In Progress,Success"
Add-CSVContent -file $file -values "$winFeatureUpdatesObjectCancelled,$winFeatureUpdatesObjectErrors,$winFeatureUpdatesObjectInProgress,$winFeatureUpdatesObjectSuccess"
Add-DateDataCsv -file $file -day $dateDay -month $dateMonth -year $dateYear



<########################### REPORT 2 DEVICE COMPIANCE #####################################################################
# https://endpoint.microsoft.com/#view/Microsoft_Intune_Enrollment/ReportingMenu/~/deviceCompliance
# Although this is an SDK it still takes its attributes like sending to an API endpoint

$params = @{
	Id = "DeviceCompliance_00000000-0000-0000-0000-000000000002"
	filter = ""
	GroupBy = @(
		"ComplianceState"
	)
	Select = @(
		"ComplianceState"
	)
}

Get-MgBetaDeviceManagementReportCachedReport -BodyParameter $params -OutFile C:\temp\Compliance.txt

$reportString =Get-Content C:\temp\Compliance.txt
$reportObject =Convert-JsonToObject $reportString
$compliantDevices = $reportObject.Values[0][2]
$notCompliant = $reportObject.Values[1][2]
$totalDevicesCompliance =$compliantDevice + $nonCompliantDevice

<########################### REPORT 3 DEFENDER AGENTS #####################################################################

$params = @{
	Id = "DefenderAgents_00000000-0000-0000-0000-000000000002"
	filter = ""
	GroupBy = @(
		"DeviceState"
	)
	Select = @(
		"DeviceState"
	)
}

Get-MgBetaDeviceManagementReportCachedReport -BodyParameter $params -OutFile C:\temp\Defender.txt

$reportString =Get-Content C:\temp\Defender.txt
$reportObject =Convert-JsonToObject $reportString

#Clean Header
$reportObject.Values[0][1]

#Clean Devices and Total Devices
$reportObject.Values[0][2]

$file = Initialize-CSVHeaders -fileName Defender -day $dateDay -month $dateMonth -year $dateYear -headers $reportObject.Values[0][1]
Add-CSVContent -file $file -values $reportObject.Values[0][2]
Add-DateDataCsv -file $file -day $dateDay -month $dateMonth -year $dateYear

<########################### REPORT 4 EXPEDITED UPDATES #####################################################################

$params = @{
	Id = "QualityUpdatePolicyStatusSummary_00000000-0000-0000-0000-000000000002"
	Skip = 0
	Top = 50
	Search = ""
	OrderBy = @()
	Select =  @(
		"PolicyId"
		"PolicyName"
		"CountDevicesInProgressStatus"
		"CountDevicesCancelledStatus"
		"CountDevicesErrorStatus"
		"CountDevicesSuccessStatus"
		"ExpediteQUReleaseDate"
		"CountDevicesOnHoldStatus"
		"CountDevicesRollbackStatus"
	)
  }
  
  $winExpeditedFeatures = Get-MgBetaDeviceManagementReportCachedReport -BodyParameter $params -OutFile C:\temp\Expedited.txt
  
  $winExpeditedFeaturesString = Get-Content C:\temp\Expedited.txt
  
  $winExpeditedFeaturesObject = Convert-JsonToObject $winExpeditedFeaturesString

  $winExpeditedFeaturesObjectCancelled =   $winExpeditedFeaturesObject.Values[0][0]
  $winExpeditedFeaturesObjectErrors = $winExpeditedFeaturesObject.Values[0][1] 
  $winExpeditedFeaturesObjectInProgress = $winExpeditedFeaturesObject.Values[0][2]
  $winExpeditedFeaturesObjectSuccess = $winExpeditedFeaturesObject.Values[0][5]
  
  $file = Initialize-CSVHeaders -fileName Expedited -day $dateDay -month $dateMonth -year $dateYear -headers "Cancelled,Errors,In Progress,Success"
  Add-CSVContent -file $file -values "$winExpeditedFeaturesObjectCancelled,$winExpeditedFeaturesObjectErrors,$winExpeditedFeaturesObjectInProgress,$winExpeditedFeaturesObjectSuccess"
  Add-DateDataCsv -file $file -day $dateDay -month $dateMonth -year $dateYear

<########################### REPORT 4 ENCRYPTED DEVICES #####################################################################

$itemsPerApiCall = 50
$skips = 0 
$DeviceArray = @()

$params = @{
	select = @(
		"DeviceId"
		"DeviceName"
		"DeviceType"
		"OSVersion"
		"TpmSpecificationVersion"
		"EncryptionReadinessState"
		"EncryptionStatus"
		"UPN"
	)
	filter = ""
	search = ""
	skip = 0
	top = $itemsPerApiCall
}

Get-MgBetaDeviceManagementReportEncryptionReportForDevice -BodyParameter $params -Outfile C:\temp\Encryption.txt |Out-Null

$reportEncryptionString =Get-Content C:\temp\Encryption.txt
$reportEncryption =Convert-JsonToObject $reportEncryptionString


$numberOfDevices = $reportEncryption.TotalRowCount
$numberOfDevices



# We need the page value as an Integer
$pagesRequired = [Math]::Floor($numberOfDevices/$itemsPerApiCall) 

for($i = 0; $i -le $pagesRequired; $i ++)

  { $skips = $itemsPerApiCall * $i

    if ($i -eq 0 )
    {$Skips
		$params = @{
			select = @(
				"DeviceId"
				"DeviceName"
				"DeviceType"
				"OSVersion"
				"TpmSpecificationVersion"
				"EncryptionReadinessState"
				"EncryptionStatus"
				"UPN"
			)
			filter = ""
			search = ""
			skip = $skips
			top = $itemsPerApiCall
		}
      
		Get-MgBetaDeviceManagementReportEncryptionReportForDevice -BodyParameter $params -Outfile C:\temp\Encryption.txt |Out-Null
		$reportEncryptionString =Get-Content C:\temp\Encryption.txt
		$reportEncryption =Convert-JsonToObject $reportEncryptionString
		
		$reportEncryptionString =Get-Content C:\temp\Encryption.txt
		$reportEncryption =Convert-JsonToObject $reportEncryptionString

   		
      
        $DeviceArray += $reportEncryption.Values

        

    }
    else
    {$skips
		$params = @{
			select = @(
				"DeviceId"
				"DeviceName"
				"DeviceType"
				"OSVersion"
				"TpmSpecificationVersion"
				"EncryptionReadinessState"
				"EncryptionStatus"
				"UPN"
			)
			filter = ""
			search = ""
			skip = $skips
			top = $itemsPerApiCall
		}
		Get-MgBetaDeviceManagementReportEncryptionReportForDevice -BodyParameter $params -Outfile C:\temp\Encryption.txt |Out-Null
		$reportEncryptionString =Get-Content C:\temp\Encryption.txt
		$reportEncryption =Convert-JsonToObject $reportEncryptionString
		
		$reportEncryptionString =Get-Content C:\temp\Encryption.txt
		$reportEncryption =Convert-JsonToObject $reportEncryptionString

   		
      
        $DeviceArray += $reportEncryption.Values
 

    }

  }


  $deviceUnencrypted = @()
Clear-Host
  $unencyptedDeviceCounter = 0
  foreach($item in $DeviceArray)
  
  {
    if(($item[7] -eq "Not encrypted") -and (($item[1].Substring(0,3) -eq ("LFL")) -or  ($item[1].Substring(0,3) -eq ("NMB"))))
    { 
		$deviceUnencrypted += $item[1]
      Write-Host "Check $devName as it not encrypted"
      $unencyptedDeviceCounter += 1
    }


  }
  Write-Host "Check the below devices as they are not encrypted"
  Write-Host $deviceUnencrypted
  Write-Host "$unencyptedDeviceCounter devices are unencrypted"
  
  Write-Host "Number of Devices: $numberOfDevices"

  Write-Host "Potential unencrypted: $unencyptedDeviceCounter"

  $percentEncrypted = (($numberOfDevices - $unencyptedDeviceCounter)/$numberOfDevices)

  Write-Host "Encrypted devices: $percentEncrypted %"

 foreach($device in $deviceUnencrypted)
 	{
		$deviceUnencryptedString += " " + $device


	}
	$file = Initialize-CSVHeaders -fileName Bitlocker -day $dateDay -month $dateMonth -year $dateYear -headers "Total Devices,Encrypted,Unencrypted"
	Add-CSVContent -file $file -values "$numberOfDevices,$percentEncrypted,$deviceUnencryptedString"
	Add-DateDataCsv -file $file -day $dateDay -month $dateMonth -year $dateYear



########################### REPORT 6 Device Analytics #####################################################################
Get-MgBetaDeviceManagementUserExperienceAnalyticDevicePerformance -all|Export-Csv C:\temp\DeviceAnalytics.csv

$data = Import-Csv C:\temp\DeviceAnalytics.csv
$data | Select-Object *, @{n=”Year”;e={$dateYear}} | Export-CSV C:\temp\DeviceAnalytics.csv -NoTypeInformation

$data = Import-Csv C:\temp\DeviceAnalytics.csv
$data | Select-Object *, @{n=”Month”;e={$dateMonth}} | Export-CSV C:\temp\DeviceAnalytics.csv -NoTypeInformation

$data = Import-Csv C:\temp\DeviceAnalytics.csv
$data | Select-Object *, @{n=”Day”;e={$dateDay}} | Export-CSV C:\temp\DeviceAnalytics.csv -NoTypeInformation #


########################### REPORT 7 App Health #####################################################################
Get-MgBetaDeviceManagementUserExperienceAnalyticAppHealthApplicationPerformance -all |Export-Csv c:\Temp\Apps.csv

#####################################END############################################################################>
