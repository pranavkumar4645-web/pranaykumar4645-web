$videos = @(
    (Get-ChildItem "*mansion*.mp4").Name,
    (Get-ChildItem "*Camera_push*.mp4").Name,
    (Get-ChildItem "*Black_marble*.mp4").Name,
    (Get-ChildItem "*Luxury_master*.mp4").Name,
    (Get-ChildItem "*Infinity_pool*.mp4").Name
)

# Find the ffmpeg executable inside the extracted folder
$ffmpeg = Get-ChildItem -Path "ffmpeg_extracted" -Filter "ffmpeg.exe" -Recurse | Select-Object -First 1 | Select-Object -ExpandProperty FullName

if (-not $ffmpeg) {
    Write-Host "FFmpeg not found!"
    exit 1
}

$framesDir = "frames"
if (Test-Path $framesDir) { Remove-Item -Recurse -Force $framesDir }
New-Item -ItemType Directory -Path $framesDir | Out-Null

$globalFrameCounter = 0

foreach ($vid in $videos) {
    Write-Host "Processing $vid..."
    $tempDir = "temp_frames"
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # Extract at 12 fps as recommended in skill
    $cmd = "& `"$ffmpeg`" -i `"$vid`" -vf fps=12 -q:v 3 -v error `"$tempDir\frame_%04d.jpg`""
    Invoke-Expression $cmd
    
    $extracted = Get-ChildItem -Path $tempDir -Filter "*.jpg" | Sort-Object Name
    foreach ($file in $extracted) {
        $newName = "frame_{0:D4}.jpg" -f ($globalFrameCounter + 1)
        Move-Item -Path $file.FullName -Destination "$framesDir\$newName"
        $globalFrameCounter++
    }
    Remove-Item -Recurse -Force $tempDir
}

$manifest = @{
    count = $globalFrameCounter
    pattern = "frames/frame_%04d.jpg"
} | ConvertTo-Json

$manifest | Out-File "$framesDir\frames.json" -Encoding ASCII
Write-Host "Extraction complete. Total frames: $globalFrameCounter"
