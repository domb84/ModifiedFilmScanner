# Define paths

# application paths
$java = "C:\Program Files\OpenJDK\jdk-22.0.2\bin\java.exe"
$bfc4ntk = ".\Tools\bfc4ntk.exe"
$ntkcalc = ".\Tools\ntkcalc.exe"
$ntkmpe = ".\GUITools\NtkMPE.jar"

# source paths
$source = ".\Source\verified_dump_2025.6.6.2.bin"

# extract filename and path
$sourceFilename = [io.path]::GetFileNameWithoutExtension($source)
$sourcePath = [io.path]::GetDirectoryName($source)

# partition offsets
$suffixOffset = "0x4000"
$part1Offset = "000ab000"

# temp and output paths
$tempPath = ".\Temp"
$outputPath = ".\Output"
if (-Not (Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath | Out-Null
}
if (-Not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

$extractedFile = Join-Path -Path (Resolve-Path $tempPath).Path -ChildPath "$sourceFilename.decomp"
$compressedFile = Join-Path -Path (Resolve-Path $tempPath).Path -ChildPath "$sourceFilename.compressed"
$suffixFile = Join-Path -Path (Resolve-Path $tempPath).Path -ChildPath "$sourceFilename.suffix"
$outputFile = Join-Path -Path (Resolve-Path $outputPath).Path -ChildPath "FWDV180N.BIN"

# Put them in an array
$paths = @($bfc4ntk, $ntkcalc, $ntkmpe, $source, $java)

# Check existence
foreach ($path in $paths) {
    if (-Not (Test-Path $path)) {
        Write-Host "Missing: $path" -ForegroundColor Red
        exit 1
    }
}

# Read the bytes after the offset
$suffixOffset = [Convert]::ToInt32($suffixOffset, 16)
$allBytes = [System.IO.File]::ReadAllBytes($source)
$suffix = $allBytes[$suffixOffset..($allBytes.Length - 1)]
# Write to the output file
[System.IO.File]::WriteAllBytes($suffixFile, $suffix)

# extract the partition from the valid suffix file
$arguments = "-x `"$suffixFile`" `"$extractedFile`" `"$part1Offset`""
Write-Host "Running: $bfc4ntk $arguments"
Start-Process -NoNewWindow -FilePath $bfc4ntk -ArgumentList "$arguments" -Wait

# Check if the extraction was successful
if (-Not (Test-Path $extractedFile)) {
    Write-Host "Extraction failed. Please check the source file and offset." -ForegroundColor Red
    exit 1
}

Write-Host "Open $extractedFile in NtkMPE to modify the bitrate. DO NOT SET IT ABOVE 14800 (30Mbit)." -ForegroundColor Green

# # open ntkmpe to modify the partition
Start-Process -FilePath $java -ArgumentList "-jar", (Resolve-Path $ntkmpe).Path -Wait -NoNewWindow

# wait for it to be modified
Read-Host "Press Enter after you have modifed the partition $extractedFile"

# compress the modified partition
$arguments = "-p `"$extractedFile`" `"$compressedFile`" `"$part1Offset`""
# $arguments = "-c `"$extractedFile`" `"$compressedFile`""
Write-Host "Running: $bfc4ntk $arguments"
Start-Process -NoNewWindow -FilePath $bfc4ntk -ArgumentList "$arguments" -Wait

# Check if the extraction was successful
if (-Not (Test-Path $compressedFile)) {
    Write-Host "Compression failed." -ForegroundColor Red
    exit 1
}

# Create the final file
Copy-Item -Path $compressedFile -Destination $outputFile -Force

# checksum entire file and write to output file
$arguments = "-cw `"$outputFile`""
Write-Host "Running: $ntkcalc $arguments"
Start-Process -NoNewWindow -FilePath $ntkcalc -ArgumentList "$arguments" -Wait

# Check if the checksum calculation was successful
if ($LASTEXITCODE -ne 0) {
    Write-Host "Checksum recalculated successfully." -ForegroundColor Green
} else {
    Write-Host "Checksum recalculation failed." -ForegroundColor Red
    exit 1
}

Write-Host "Firmware modifed. Copy FWDV180N.BIN to your SDCARD and boot the M127 machine." -ForegroundColor Green
