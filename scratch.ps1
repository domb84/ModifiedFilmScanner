
$bootloaderOffset = "0x8f8"

# Read everything before offset
$offset = [Convert]::ToInt32($bootloaderOffset, 16)
# Read the bytes before the offset
$prefix = [System.IO.File]::ReadAllBytes($source)[0..($offset - 1)]
# Read the content of the nmodified partition
$main = [System.IO.File]::ReadAllBytes($compressedFile)
# Combine the two
$combined = $prefix + $main
# Write to the output file
[System.IO.File]::WriteAllBytes($outputFile, $combined)
# Check that output file exists
if (-Not (Test-Path $outputFile)) {
    Write-Host "Output file not found: $outputFile" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Output file created successfully: $outputFile" -ForegroundColor Green
}

# Combine firmware and suffix
# read the content of the compressed partition
$main = [System.IO.File]::ReadAllBytes($compressedFile)
# Combine the two
$combined = $main + $suffix
[System.IO.File]::WriteAllBytes($outputFile, $combined)
# Check that output file exists
if (-Not (Test-Path $outputFile)) {
    Write-Host "Output file not found: $outputFile" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Output file created successfully: $outputFile" -ForegroundColor Green
}
