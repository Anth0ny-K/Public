function Extract-ContentBetweenMarkers {
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

        # Define the start and end markers
        $startMarker = '{"rawLines":["'
        $endMarker = '"],"'

        # Find the position of the first start marker
        $startPos = $fileContent.IndexOf($startMarker)
        if ($startPos -eq -1) {
            Write-Error "Start marker not found in the file."
            return
        }
        
        # Adjust start position to get content after the marker
        $startPos += $startMarker.Length
        
        # Find the position of the last end marker
        $endPos = $fileContent.LastIndexOf($endMarker)
        if ($endPos -eq -1) {
            Write-Error "End marker not found in the file."
            return
        }
        
        # Extract the content between markers
        $extractedContent = $fileContent.Substring($startPos, $endPos - $startPos)
        
        # Output results
        if ($OutputPath) {
            # Save to file if output path is provided
            $extractedContent | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Host "Content extracted and saved to $OutputPath"
        } else {
            # Return the extracted content
            return $extractedContent
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

# Example usage:
# Extract-ContentBetweenMarkers -FilePath "C:\path\to\your\file.txt" -OutputPath "C:\path\to\output.txt"
# 
# Or to just get the content without saving to file:
# $content = Extract-ContentBetweenMarkers -FilePath "C:\path\to\your\file.txt"
# $content
