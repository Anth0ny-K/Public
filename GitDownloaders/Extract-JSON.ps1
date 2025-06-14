function Extract-JsonContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Check if file exists
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }

    try {
        # Read the entire file content
        $fileContent = Get-Content -Path $FilePath -Raw

        # Define the start marker
        $startMarker = '{"rawLines":["'
        
        # Find the position of the start marker
        $startPos = $fileContent.IndexOf($startMarker)
        if ($startPos -eq -1) {
            Write-Error "Start marker not found in the file."
            return
        }
        
        # Find the position of the closing JSON structure
        $endMarker = '"],'
        $endPos = $fileContent.IndexOf($endMarker, $startPos)
        if ($endPos -eq -1) {
            Write-Error "End marker not found in the file."
            return
        }
        
        # Extract the JSON content including the markers
        $jsonContent = $fileContent.Substring($startPos, $endPos - $startPos + $endMarker.Length)
        $jsonContent += '"' # Add the closing quote to make it valid JSON
        
        # Attempt to parse the JSON
        try {
            $parsedJson = $jsonContent | ConvertFrom-Json
            
            # Extract the array of lines
            $lines = $parsedJson.rawLines
            
            # Join the lines with newlines to create proper script content
            $sanitizedContent = $lines -join "`r`n"
            
            # Output results
            if ($OutputPath) {
                # Save to file if output path is provided
                $sanitizedContent | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "Content extracted and saved to $OutputPath"
            } else {
                # Return the extracted content
                return $sanitizedContent
            }
        }
        catch {
            Write-Error "Failed to parse JSON content: $_"
            
            # Alternative approach: manual extraction if JSON parsing fails
            Write-Host "Attempting manual extraction..."
            
            # Extract content between markers directly
            $content = $fileContent.Substring($startPos + $startMarker.Length, $endPos - $startPos - $startMarker.Length)
            
            # Split by the line separator pattern in the JSON
            $lines = $content -split '","'
            
            # Clean up escape sequences
            $sanitizedLines = $lines | ForEach-Object { $_ -replace '\\\"', '"' -replace '\\\\', '\' }
            $sanitizedContent = $sanitizedLines -join "`r`n"
            
            if ($OutputPath) {
                $sanitizedContent | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "Content manually extracted and saved to $OutputPath"
            } else {
                return $sanitizedContent
            }
        }
    }
    catch {
        Write-Error "An error occurred during extraction: $_"
    }
}

# Example usage:
# Extract-JsonContent -FilePath "C:\path\to\your\file.txt" -OutputPath "C:\path\to\output.ps1"
# 
# Or to just get the content without saving to file:
# $content = Extract-JsonContent -FilePath "C:\path\to\your\file.txt"
