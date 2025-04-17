

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Uri')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Uri')]
    [ValidateNotNullOrEmpty()]
    [string[]]$Uri = "website-uri"
)

# Get the content ... 
if ($PSCmdlet.ParameterSetName -eq 'Uri') {
    # Get addresses from $Uri parameter
    $Uri | ForEach-Object {
        $address = $_.Trim()
        try {
            $websiteUri = New-Object System.UriBuilder($address)
        } catch {
            Write-Host "Error processing address: $address"
            continue
        }

        # Paths for logs
        $basePath = Join-Path -Path (Get-Location) -ChildPath "case"
        $logFolder = Join-Path -Path $basePath -ChildPath $websiteUri.Host
        $webFolder = Join-Path -Path $logFolder -ChildPath $websiteUri.Path
        $logFile = Join-Path -Path $webFolder -ChildPath "test-website.txt"

        # Create case folder if it doesn't exist
        if (-not (Test-Path -Path $basePath)) {
            New-Item -ItemType Directory -Path $basePath | Out-Null
        }
        # Create website folder if it doesn't exist
        if (-not (Test-Path -Path $logFolder)) {
            New-Item -ItemType Directory -Path $logFolder | Out-Null
        }
        if (-not (Test-Path -Path $webFolder)) {
            New-Item -ItemType Directory -Path $webFolder | Out-Null
        }
        # Create log file if it doesn't exist
        if (-not (Test-Path -Path $logFile)) {
            New-Item -ItemType File -Path $logFile | Out-Null
        } else {
            Clear-Content -Path $logFile
        }

        # Array for results
        $dataWebsite = @()
        $dataWebsite += "URI: $($websiteUri.Uri)"

        # Let's check if the website is accessible
        try {
            $response = Invoke-WebRequest -Uri $websiteUri.Uri
            $dataWebsite += "`tStatusCode: $($response.StatusCode)"
            $dataWebsite += "`tStatusDescription: $($response.StatusDescription)"
        } catch {
            Write-Host "Failed to access the website. StatusCode: $($_.Exception.Response.StatusCode.value__)"
            $dataWebsite += "`tStatusCode: $($_.Exception.Response.StatusCode.value__)"
            $dataWebsite | ForEach-Object { Add-Content -Path $logFile -Value $_ }
            continue
        }

        # Let's evaluate the response if StatusCode is 200
        if ($response.StatusCode -eq 200) {

            # Check headers and try to find if response is from a blob storage
            $dataWebsite += "`tHeaders:"
            $response.Headers.Keys | ForEach-Object {
                $key = $_
                $dataWebsite += "`t`t$($key): $($response.Headers[$key] -Join ', ')"
                switch ($key) {
                    'Server' {
                        if ($response.Headers[$key] -match 'Windows-Azure-Blob/.*') {
                            $dataWebsite += "`t`t`tIt's possibly a blob storage."
                        }
                    }
                    'x-ms-blob-type' {
                        if ($response.Headers[$key] -match 'BlockBlob') {
                            $dataWebsite += "`t`t`tIt's possibly a blob storage."
                        }
                    }
                    Default {}
                }
            }
            # Check if the website contains any link to a blob storage
            # Pattern for all services under StorageAccount 'https://([0-9a-z]{3,24})\.(blob|web|dfs|file|queue|table)\.core\.windows\.net/([0-9a-z-_$]{3,63})/'
            $dataWebsite += "`tChecking for regular expression against context:"    
            $dataWebsite += "`t`tPattern: (?<endpoint>https://(?<storageacc>[0-9a-z]{3,24})\.blob\.core\.windows\.net)/(?<container>[0-9a-z-_$]{3,63})/"    
            $results = $response.Content | Select-String -Pattern '(?<endpoint>https://(?<storageacc>[0-9a-z]{3,24})\.blob\.core\.windows\.net)/(?<container>[0-9a-z-_$]{3,63})/' -AllMatches
            # We want to get unique matches
            $uniqueMatches = $results.Matches | Select-Object -Unique
            $dataWebsite += "`t`tUnique Matches:"
            $uniqueMatches | ForEach-Object {
                # Let's check each match
                $dataWebsite += "`t`t`tValue: $($_.Value)"
                $dataWebsite += "`t`t`tEndpoint: $($_.Groups['endpoint'].Value)"
                $dataWebsite += "`t`t`tStorageAccount: $($_.Groups['storageacc'].Value)"
                $dataWebsite += "`t`t`tContainer: $($_.Groups['container'].Value)"
                # Create URI for request to same path
                $uriBuilder = New-Object System.UriBuilder($_.Value)
                $uriBuilder.Path = $websiteUri.Path # Let's check if we can find same path
                $dataWebsite += "`t`t`tURI: $($uriBuilder.Uri)"
                try {
                    $check = Invoke-WebRequest -Uri $uriBuilder.Uri -Method Head
                    $dataWebsite += "`t`t`t`tStatusCode: $($check.StatusCode)"
                    $dataWebsite += "`t`t`t`tStatusDescription: $($check.StatusDescription)"
                    $dataWebsite += "`t`t`t`tHeaders:"
                    $check.Headers.Keys | ForEach-Object {
                        $key = $_
                        $dataWebsite += "`t`t`t`t`t$($key): $($check.Headers[$key] -Join ', ')"
                        switch ($key) {
                            'Server' {
                                if ($check.Headers[$key] -match 'Windows-Azure-Blob/.*') {
                                    $dataWebsite += "`t`t`t`t`t`tIt's possibly a blob storage."
                                }
                            }
                            'x-ms-blob-type' {
                                if ($check.Headers[$key] -match 'BlockBlob') {
                                    $dataWebsite += "`t`t`t`t`t`tIt's possibly a blob storage."
                                }
                            }
                            Default {}
                        }
                    }
            
                } catch {
                    $dataWebsite += "`t`t`t`tStatusCode: $($_.Exception.Response.StatusCode.value__)"
                }
                # Let's check another API calls to the blob storage
                $storageAccount = $_.Groups['storageacc'].Value
                $storageFolder = Join-Path -Path $logFolder -ChildPath $storageAccount
                # Create storage account folder if it doesn't exist
                if (-not (Test-Path -Path $storageFolder)) {
                    New-Item -ItemType Directory -Path $storageFolder | Out-Null
                }
                $container = $_.Groups['container'].Value
                $containerFolder = Join-Path -Path $storageFolder -ChildPath $container
                # Create container folder if it doesn't exist
                if (-not (Test-Path -Path $containerFolder)) {
                    New-Item -ItemType Directory -Path $containerFolder | Out-Null
                }
                # URI builder for the blob storage
                $uriBuilderEndpoint = New-Object System.UriBuilder($_.Groups['endpoint'].Value)
                $requestHeaders = @{
                    "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
                    "Accept-Language" = "en-US,en;q=0.5";
                }
                $requestHeadersVersion = @{
                    "x-ms-version" = "2019-12-12";
                    "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
                    "Accept-Language" = "en-US,en;q=0.5";
                }

                # Get Account Information
                # /wo x-ms-version
                $uriBuilderEndpoint.Path = "/" 
                $uriBuilderEndpoint.Query = "restype=account&comp=properties"
                $fileOutputPath = Join-Path -Path $containerFolder -ChildPath "account-information.xml"
                $dataWebsite += "`t`t`tURI: $($uriBuilderEndpoint.Uri)"
                try {
                    $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
                    $dataWebsite += "`t`t`t`tStatusCode: $($response.StatusCode)"
                    $dataWebsite += "`t`t`t`tStatusDescription: $($response.StatusDescription)"

                    if ($response.StatusCode -eq 200) {
                        $response.Content | Out-File -FilePath $fileOutputPath
                    }

                } catch {
                    $dataWebsite += "`t`t`t`tStatusCode: $($_.Exception.Response.StatusCode.value__)"
                }

                # Get Blob Service Properties
                # /wo x-ms-version
                $uriBuilderEndpoint.Path = "/" 
                $uriBuilderEndpoint.Query = "restype=service&comp=properties"
                $fileOutputPath = Join-Path -Path $containerFolder -ChildPath "service-properties.xml"
                $dataWebsite += "`t`t`tURI: $($uriBuilderEndpoint.Uri)"
                try {
                    $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
                    $dataWebsite += "`t`t`t`tStatusCode: $($response.StatusCode)"
                    $dataWebsite += "`t`t`t`tStatusDescription: $($response.StatusDescription)"

                    if ($response.StatusCode -eq 200) {
                        $response.Content | Out-File -FilePath $fileOutputPath
                    }

                } catch {
                    $dataWebsite += "`t`t`t`tStatusCode: $($_.Exception.Response.StatusCode.value__)"
                }

                # List Containers
                # /wo x-ms-version
                $uriBuilderEndpoint.Path = "/" 
                $uriBuilderEndpoint.Query = "comp=list"
                $fileOutputPath = Join-Path -Path $containerFolder -ChildPath "containers.xml"
                $dataWebsite += "`t`t`tURI: $($uriBuilderEndpoint.Uri)"
                try {
                    $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
                    $dataWebsite += "`t`t`t`tStatusCode: $($response.StatusCode)"
                    $dataWebsite += "`t`t`t`tStatusDescription: $($response.StatusDescription)"

                    if ($response.StatusCode -eq 200) {
                        $response.Content | Out-File -FilePath $fileOutputPath
                    }

                } catch {
                    $dataWebsite += "`t`t`t`tStatusCode: $($_.Exception.Response.StatusCode.value__)"
                }

                # List Blobs
                # /w x-ms-version
                $uriBuilderEndpoint.Path = "/$($container)"
                $uriBuilderEndpoint.Query = "restype=container&comp=list&include=versions"
                $fileOutputPath = Join-Path -Path $containerFolder -ChildPath "blobs.xml"
                $dataWebsite += "`t`t`tURI: $($uriBuilderEndpoint.Uri)"
                try {
                    $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeadersVersion
                    $dataWebsite += "`t`t`t`tStatusCode: $($response.StatusCode)"
                    $dataWebsite += "`t`t`t`tStatusDescription: $($response.StatusDescription)"

                    if ($response.StatusCode -eq 200) {
                        $response.Content | Out-File -FilePath $fileOutputPath

                        $dataWebsite += "`t`t`t`tCheck Blobs:"
                        $XmlDocument = New-Object System.XML.XMLDocument
                        $XmlDocument.Load($fileOutputPath)
                        $XmlDocument.EnumerationResults.Blobs.Blob | ForEach-Object {
                            $dataWebsite += "`t`t`t`t`tName: $($_.Name); VersionId: $($_.VersionId); Content-Type: $($_.Properties.'Content-Type')"
                        }
                    }

                } catch {
                    $dataWebsite += "`t`t`t`tStatusCode: $($_.Exception.Response.StatusCode.value__)"
                }

            }

        } else {
            Write-Host "Failed to access the website. StatusCode: $($response.StatusCode)"
        }

        $dataWebsite | ForEach-Object { Add-Content -Path $logFile -Value $_ }
    }

} else {
    Write-Host "Invalid parameter set."
    exit
}
