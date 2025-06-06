# Define paths

# application paths
$bfc4ntk = "C:\Users\DominicBird\Mega\ch341\M127 ROM\bfc4ntk.exe"
$ntkcalc = "C:\Users\DominicBird\Mega\ch341\M127 ROM\ntkcalc.exe"
$ntkmpe = "C:\Users\DominicBird\Mega\ch341\Tools\NtkMPE.jar"
$java = "C:\Program Files\OpenJDK\jdk-22.0.2\bin\java.exe"

# source paths
$source = "C:\Users\DominicBird\Mega\ch341\M127 ROM\verified_dump_2025.6.6.2.bin"
$sourceFilename = [io.path]::GetFileNameWithoutExtension($source)
$sourcePath = [io.path]::GetDirectoryName($source)
$part1Offset = "000af000"
$bootloaderOffset = "000008f8"
$endOffset = "0024AE38"

# variable paths
$extractedFile = "$sourcePath\$sourceFilename.decomp"
$compressedFile = "$sourcePath\$sourceFilename.compressed"
$outputFile = "$sourcePath\$sourceFilename.modified.bin"

# Put them in an array
$paths = @($bfc4ntk, $ntkcalc, $ntkmpe, $source)

# Check existence
foreach ($path in $paths) {
    if (-Not (Test-Path $path)) {
        Write-Host "Missing: $path" -ForegroundColor Red
        exit 1
    }
}

# extract the partition
$arguments = "-x `"$source`" `"$extractedFile`" `"$part1Offset`""
Write-Host "Running: $bfc4ntk $arguments"
Start-Process -NoNewWindow -FilePath $bfc4ntk -ArgumentList "$arguments" -Wait

# Check if the extraction was successful
if (-Not (Test-Path $extractedFile)) {
    Write-Host "Extraction failed. Please check the source file and offset." -ForegroundColor Red
    exit 1
}

# open ntkmpe to modify the partition
Start-Process -FilePath $java -ArgumentList "-jar", $ntkmpe, $extractedFile -Wait

# wait for it to be modified
# Read-Host "Press Enter after you have modifed the partition $extractedFile"

# compress the modified partition
$arguments = "-p `"$extractedFile`" `"$compressedFile`" `"$part1Offset`""
Write-Host "Running: $bfc4ntk $arguments"
Start-Process -NoNewWindow -FilePath $bfc4ntk -ArgumentList "$arguments" -Wait

# Check if the extraction was successful
if (-Not (Test-Path $compressedFile)) {
    Write-Host "Compression failed." -ForegroundColor Red
    exit 1
}

# # Read everything before offset
# $offset = [Convert]::ToInt32($bootloaderOffset, 16)
# # Read the bytes before the offset
# $prefix = [System.IO.File]::ReadAllBytes($source)[0..($offset - 1)]
# # Read the content of the nmodified partition
# $main = [System.IO.File]::ReadAllBytes($compressedFile)
# # Combine the two
# $combined = $prefix + $main
# # Write to the output file
# [System.IO.File]::WriteAllBytes($outputFile, $combined)
# # Check that output file exists
# if (-Not (Test-Path $outputFile)) {
#     Write-Host "Output file not found: $outputFile" -ForegroundColor Red
#     exit 1
# } else {
#     Write-Host "Output file created successfully: $outputFile" -ForegroundColor Green
# }

# Read after before offset
$offset = [Convert]::ToInt32($endOffset, 16)
# Read the bytes after the offset
$suffix = $allBytes[$offset..($allBytes.Length - 1)]
# read the content of the compressed partition
$main = [System.IO.File]::ReadAllBytes($compressedFile)
# Combine the two
$combined = $main + $suffix
# Write to the output file
[System.IO.File]::WriteAllBytes($outputFile, $combined)
# Check that output file exists
if (-Not (Test-Path $outputFile)) {
    Write-Host "Output file not found: $outputFile" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Output file created successfully: $outputFile" -ForegroundColor Green
}


# $arguments = "-cw `"$outputFile`""
# Write-Host "Running: $ntkcalc $arguments"
# Start-Process -NoNewWindow -FilePath $ntkcalc -ArgumentList "$arguments" -Wait

# # Check if the checksum calculation was successful
# if ($LASTEXITCODE -ne 0) {
#     Write-Host "Checksum recalculated successfully." -ForegroundColor Green
# } else {
#     Write-Host "Checksum recalculation failed." -ForegroundColor Red
#     exit 1
# }