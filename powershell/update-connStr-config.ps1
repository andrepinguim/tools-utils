# alterar a connection string de vários arquivos .config com base num CSV
$csv = Import-Csv -Path "caminho\para\o\arquivo.csv"

foreach ($row in $csv) {
    #read line information
    $system = $row.System
    $server = $row.Server
    $database = $row.Database # needed??
    $userId = $row.UserId
    $password = $row.Password

    Get-ChildItem -Path . -Filter "*.config" -Recurse | Where-Object { $_.FullName -like "*$system*" } | ForEach-Object {
        # bkp
        $backupFileName = (Get-Date).ToString("yyyyMMdd-HHmm") + "_" + $_.Name
        $backupFilePath = Join-Path $_.DirectoryName $backupFileName
        Copy-Item $_.FullName $backupFilePath -Force

        #update .config line
        (Get-Content $_.FullName) |
        ForEach-Object {
            $_ -replace "server=.*", "server=$server" `
               -replace "user id=.*", "user id=$userId" `
               -replace "password=.*", "password=$password"
        } |
        Set-Content $_.FullName
    }
}
