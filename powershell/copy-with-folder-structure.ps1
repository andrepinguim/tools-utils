$SourceFolder = "D:\Downloads"
$DestinationFolder = "D:\test"
$IncludeFiles = ("*.jpeg","*.jpg")

Get-ChildItem $SourceFolder -Recurse -Include $IncludeFiles | Where-Object {$_.LastWriteTime -gt $ChangesStarted} | ForEach-Object {
    $PathArray = $_.FullName.Replace($SourceFolder,"").ToString().Split('\') 

    $Folder = $DestinationFolder

    for ($i=1; $i -lt $PathArray.length-1; $i++) {
        $Folder += "\" + $PathArray[$i]
        if (!(Test-Path $Folder)) {
            New-Item -ItemType directory -Path $Folder
        }
    }   
    $NewPath = Join-Path $DestinationFolder $_.FullName.Replace($SourceFolder,"")

    Copy-Item $_.FullName -Destination $NewPath  
}