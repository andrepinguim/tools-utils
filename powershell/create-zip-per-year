# O script utiliza o diretório atual (.) como origem dos arquivos. Caso deseje usar outro diretório, altere o parâmetro -Path.
# O parâmetro -Recurse garante que a busca seja feita em subdiretórios.
# O Compress-Archive está disponível a partir do PowerShell 5.0.


# Define o nome do arquivo zip
$zipFile = "_arquivos.zip"

# Define o ano desejado
$anoDesejado = 2025

# Obtém todos os arquivos (recursivamente) que foram criados no ano especificado
$arquivos = Get-ChildItem -Path . -Recurse -File | Where-Object { $_.CreationTime.Year -eq $anoDesejado }

if ($arquivos.Count -eq 0) {
    Write-Host "Nenhum arquivo encontrado criado em $anoDesejado."
    exit
}

# Cria o arquivo zip, sobrescrevendo-o se já existir
Compress-Archive -Path $arquivos.FullName -DestinationPath $zipFile -Force

Write-Host "Arquivo '$zipFile' criado com sucesso contendo $($arquivos.Count) arquivo(s)."
