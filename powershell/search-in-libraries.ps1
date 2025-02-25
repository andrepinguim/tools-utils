# Configurações
$organization = ""
$pat = ""
$searchTerm = ""

# Cria o header de autenticação em Base64
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))

# Obtém todos os projetos da organização
$projectsUri = "https://dev.azure.com/$organization/_apis/projects?api-version=6.0"
$projectsResponse = Invoke-RestMethod -Uri $projectsUri -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

foreach ($project in $projectsResponse.value) {
    $projectName = $project.name
    # Write-Output "Verificando projeto: $projectName"
    
    # Endpoint para listar os grupos de variáveis no projeto atual
    $variableGroupsUri = "https://dev.azure.com/$organization/$projectName/_apis/distributedtask/variablegroups?api-version=7.1-preview.2"
    
    try {
        $variableGroupsResponse = Invoke-RestMethod -Uri $variableGroupsUri -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
    }
    catch {
        # Write-Output "Não foi possível obter grupos de variáveis para o projeto $projectName. Pulando este projeto..."
        continue
    }

    if ($variableGroupsResponse.value) {
        foreach ($group in $variableGroupsResponse.value) {
            # Percorre as propriedades (variáveis) do grupo
            foreach ($property in $group.variables.PSObject.Properties) {
                $variableName = $property.Name
                $variableData = $property.Value  # Ex.: { isSecret = False; value = "algumValor" }
                $variableValue = $variableData.value

                if ($variableValue -and $variableValue -like "*$searchTerm*") {
                    Write-Host "Encontrado no projeto '$($project.name)' - Grupo '$($group.name)': Variável '$variableName' com valor '$variableValue'"
                }
            }
        }
    }
}
