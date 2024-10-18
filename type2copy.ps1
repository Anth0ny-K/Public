# Load System.Windows.Forms for SendKeys
Add-Type -AssemblyName 'System.Windows.Forms'

# Function to simulate typing
function Simulate-Typing {
    param (
        [string]$text
    )

    # Wait for 5 seconds
    Start-Sleep -Seconds 5

    # Simulate typing each character
    foreach ($char in $text.ToCharArray()) {
        [System.Windows.Forms.SendKeys]::SendWait($char)
        Start-Sleep -Milliseconds 100 # Small delay between keystrokes for typing effect
    }
}

# Check if a text argument is provided
if ($args.Count -eq 0) {
    Write-Host "No text provided. Please provide a block of text as an argument."
    exit
}

# Call the typing function with the input text
Simulate-Typing -text $args[0]
