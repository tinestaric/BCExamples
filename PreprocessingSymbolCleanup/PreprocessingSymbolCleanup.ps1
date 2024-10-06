# Define the feature flag symbol you want to remove
$featureFlag = "YOUR_FEATURE_FLAG"

# Define the file extension to search within (e.g., ".al" for AL files)
$fileExtension = "*.al"

# Define the folder to search in
$folderPath = "YOUR_FOLDER_PATH"

# Recursively get all files with the specified extension
$files = Get-ChildItem -Path $folderPath -Recurse -Filter $fileExtension

foreach ($file in $files) {
    # Read the file content
    $content = Get-Content -Path $file.FullName

    # Create a new array for storing modified content
    $newContent = @()
    $insideFlagBlock = $false
    $processingElseBlock = $false
    $flagRemoved = $false

    # Stack to handle nesting of #if and #endif blocks
    $stack = [System.Collections.Stack]::new()

    foreach ($line in $content) {
        # Check if we're entering an #if or #if not block
        if ($line -match "#if\s+(not\s+)?(\w+)") {            
            $symbolName = $matches[2]  # Capture the symbol name (second capturing group)
            $stack.Push($symbolName)   # Track symbol on the stack to handle nested #if
            
            if ($symbolName -eq $featureFlag) 
            {
                # Determine whether we're in a "not" block or a regular block for the symbol
                if ($matches[1]) 
                { $insideFlagBlock = "not_flag" } 
                else 
                { $insideFlagBlock = "true_flag" }

                # Indicate that we're processing the target flag and setting the removal state
                $flagRemoved = $true
                $processingElseBlock = $false
                continue
            }
        }

        # Check if we're entering an #else block inside the target feature flag block
        if ($line -match "#else" -and $stack.Peek() -eq $featureFlag) {
            $processingElseBlock = $true
            continue
        }

        # Check if we're exiting the #endif block
        if ($line -match "#endif") {
            # Pop the condition from the stack
            if ($stack.Pop() -eq $featureFlag)  # End of the target flag block
            {
                $insideFlagBlock = $false  # Reset block state
                continue
            }
        }

        # Skip lines inside the feature flag block if necessary
        if ($insideFlagBlock -eq "true_flag" -and $processingElseBlock) {
            # We're in a true flag block, but after an else, should remove this code
            continue
        }
        elseif ($insideFlagBlock -eq "not_flag" -and !$processingElseBlock) {
            # We're in a not flag block and should remove this code
            continue
        }

        # Add the remaining lines to the new content (i.e., the non-flagged code)
        $newContent += $line
    }

    # Write the modified content back to the file if changes were made
    if ($flagRemoved) {
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "Feature flag block for '$featureFlag' (including nested #if and #endif) removed in file: $($file.FullName)"
    }
}
