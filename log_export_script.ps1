# Get API key from here: https://ipgeolocation.io/
$API_KEY = "0ba579e7b3d345268cae07125bf5bfac"
$LOGFILE_PATH = "C:\ProgramData\failed_rdp.log"

# XML filter for failed RDP events
$XMLFilter = @"
<QueryList> 
   <Query Id="0" Path="Security">
         <Select Path="Security">
              *[System[(EventID='4625')]]
          </Select>
    </Query>
</QueryList> 
"@

# Function to write sample logs
Function Write-SampleLog {
    $sampleLogs = @(
        "latitude:47.91542,longitude:-120.60306,destinationhost:samplehost,username:fakeuser,sourcehost:24.16.97.222,state:Washington,country:United States,label:United States - 24.16.97.222,timestamp:2021-10-26 03:28:29",
        "latitude:-22.90906,longitude:-47.06455,destinationhost:samplehost,username:lnwbaq,sourcehost:20.195.228.49,state:Sao Paulo,country:Brazil,label:Brazil - 20.195.228.49,timestamp:2021-10-26 05:46:20",
        "latitude:52.37022,longitude:4.89517,destinationhost:samplehost,username:CSNYDER,sourcehost:89.248.165.74,state:North Holland,country:Netherlands,label:Netherlands - 89.248.165.74,timestamp:2021-10-26 06:12:56",
        "latitude:40.71455,longitude:-74.00714,destinationhost:samplehost,username:ADMINISTRATOR,sourcehost:72.45.247.218,state:New York,country:United States,label:United States - 72.45.247.218,timestamp:2021-10-26 10:44:07"
        # Add more entries if needed
    )
    $sampleLogs | ForEach-Object { $_ | Out-File -Append -FilePath $LOGFILE_PATH -Encoding utf8 }
}

# Create the log file if it doesn't exist
if (-not (Test-Path $LOGFILE_PATH)) {
    New-Item -ItemType File -Path $LOGFILE_PATH
    Write-SampleLog
}

# Function to format timestamp
Function Format-Timestamp($event) {
    return "{0:yyyy-MM-dd HH:mm:ss}" -f $event.TimeCreated
}

# Infinite loop to monitor Event Viewer logs
while ($true) {
    Start-Sleep -Seconds 1
    $events = Get-WinEvent -FilterXml $XMLFilter -ErrorAction SilentlyContinue

    foreach ($event in $events) {
        $sourceIp = $event.properties[19].Value

        # Check for valid IP address
        if ($sourceIp -and $sourceIp.Length -ge 5) {
            $timestamp = Format-Timestamp $event
            $log_contents = Get-Content -Path $LOGFILE_PATH

            # Avoid duplicates in the log file
            if (-not ($log_contents -match $timestamp)) {
                $API_ENDPOINT = "https://api.ipgeolocation.io/ipgeo?apiKey=$API_KEY&ip=$sourceIp"
                $response = Invoke-WebRequest -UseBasicParsing -Uri $API_ENDPOINT
                $geoData = $response.Content | ConvertFrom-Json

                # Collect required data
                $logEntry = "latitude:$($geoData.latitude),longitude:$($geoData.longitude),destinationhost:$($event.MachineName),username:$($event.properties[5].Value),sourcehost:$sourceIp,state:$($geoData.state_prov),country:$($geoData.country_name),label:$($geoData.country_name) - $sourceIp,timestamp:$timestamp"
                
                # Write to log file
                $logEntry | Out-File -Append -FilePath $LOGFILE_PATH -Encoding utf8
                Write-Host $logEntry -ForegroundColor Magenta
            }
        }
    }
}
