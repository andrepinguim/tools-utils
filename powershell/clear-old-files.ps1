# Defina o diretório e a data/hora
$diretorio = Read-Host "Digite o caminho do diretório"
$dataHora = Read-Host "Digite a data/hora (formato: dd/MM/yyyy HH:mm:ss)"

# Converta a string de data/hora em um objeto DateTime
$dataHoraLimite = [datetime]::ParseExact($dataHora, 'dd/MM/yyyy HH:mm:ss', $null)

# Obtenha todos os arquivos no diretório e seus subdiretórios
$arquivos = Get-ChildItem -Path $diretorio -Recurse -ErrorAction SilentlyContinue

# Filtre e exclua arquivos que são anteriores à data/hora especificada
foreach ($arquivo in $arquivos) {
    try {
        if ($arquivo.LastWriteTime -lt $dataHoraLimite) {
            Remove-Item -Path $arquivo.FullName -Force
            Write-Host "Arquivo excluído: $($arquivo.FullName)"
        }
    } catch {
        Write-Host "Erro ao excluir o arquivo: $($arquivo.FullName) - $($_.Exception.Message)"
    }
}

Write-Host "Processo de exclusão concluído."
