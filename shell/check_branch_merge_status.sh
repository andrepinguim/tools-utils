#!/bin/bash

# check_branch_merge_status.sh
# Script para verificar quais branches e commits não estão mergeados nas branches principais
# Uso: ./check_branch_merge_status.sh /caminho/para/repositorio [--verbose]

# Verificar se o diretório do repositório foi fornecido
if [ -z "$1" ]; then
    echo "Erro: Caminho do repositório não fornecido.  "
    echo "Uso: $0 /caminho/para/repositorio [--verbose]  "
    exit 1
fi

REPO_PATH="$1"
VERBOSE=false

# Verificar se o modo verbose está ativado
if [ "$2" = "--verbose" ]; then
    VERBOSE=true
fi

# Verificar se o caminho fornecido é um repositório git válido
if [ ! -d "$REPO_PATH/.git" ]; then
    echo "Erro: O diretório fornecido não é um repositório git válido.  "
    exit 1
fi

# Entrar no diretório do repositório
cd "$REPO_PATH" || exit 1

# Branches principais para verificar
MAIN_BRANCHES=("develop" "homolog" "staging" "main")

# Caminho para o arquivo de saída (arquivo Markdown)
OUTPUT_FILE="branch_merge_report.md"

# Função para verificar se uma branch existe
branch_exists() {
    git show-ref --verify --quiet refs/heads/"$1"
    return $?
}

# Função para verificar se a branch tem commits exclusivos em relação a outra branch
has_unique_commits() {
    local source_branch="$1"
    local target_branch="$2"
    
    # Verificar se ambas as branches existem
    if ! branch_exists "$source_branch" || ! branch_exists "$target_branch"; then
        return 1
    fi
    
    # Verificar se há commits exclusivos
    local commits
    commits=$(git log --oneline "$target_branch..$source_branch" 2>/dev/null)
    
    if [ -z "$commits" ]; then
        return 1  # Não tem commits exclusivos
    else
        return 0  # Tem commits exclusivos
    fi
}

# Função para obter os commits exclusivos de uma branch em relação a outra
get_unique_commits() {
    local source_branch="$1"
    local target_branch="$2"
    
    git log --oneline "$target_branch..$source_branch" 2>/dev/null
}

# Função para verificar se uma branch foi mergeada em outra
is_merged() {
    local source_branch="$1"
    local target_branch="$2"
    
    # Verificar se ambas as branches existem
    if ! branch_exists "$source_branch" || ! branch_exists "$target_branch"; then
        return 1
    fi
    
    # Verificar se há commits exclusivos
    if ! has_unique_commits "$source_branch" "$target_branch"; then
        return 0  # Não tem commits exclusivos, consideramos como mergeada
    fi
    
    # Verificar se o último commit da branch de origem está no histórico da branch de destino
    local merge_base
    merge_base=$(git merge-base "$source_branch" "$target_branch")
    local source_head
    source_head=$(git rev-parse "$source_branch")
    
    if [ "$merge_base" = "$source_head" ]; then
        return 0  # A branch foi mergeada
    else
        return 1  # A branch não foi mergeada
    fi
}

# Iniciar o arquivo de saída
{
    echo "# Relatório de branches não mergeadas  "
    echo "## Repositório: $REPO_PATH  "
    echo "### 🔍 Verificando branches principais (\`develop\`, \`homolog\`, \`staging\`, \`main\`)...  "
    
    # Verificar as relações de merge entre as branches principais
    if branch_exists "develop" && branch_exists "homolog"; then
        if has_unique_commits "develop" "homolog" && ! is_merged "develop" "homolog"; then
            echo "❌ develop NÃO está mergeado em homolog  "
            if [ "$VERBOSE" = true ]; then
                get_unique_commits "develop" "homolog" | while read -r commit; do
                    echo "$commit  "
                done
            fi
        else
            echo "✅ develop está mergeado em homolog  "
        fi
    else
        echo "ℹ️ Não foi possível verificar develop -> homolog (uma ou ambas branches não existem)  "
    fi
    
    if branch_exists "homolog" && branch_exists "staging"; then
        if has_unique_commits "homolog" "staging" && ! is_merged "homolog" "staging"; then
            echo "❌ homolog NÃO está mergeado em staging  "
            if [ "$VERBOSE" = true ]; then
                get_unique_commits "homolog" "staging" | while read -r commit; do
                    echo "$commit  "
                done
            fi
        else
            echo "✅ homolog está mergeado em staging  "
        fi
    else
        echo "ℹ️ Não foi possível verificar homolog -> staging (uma ou ambas branches não existem)  "
    fi
    
    if branch_exists "staging" && branch_exists "main"; then
        if has_unique_commits "staging" "main" && ! is_merged "staging" "main"; then
            echo "❌ staging NÃO está mergeado em main  "
            if [ "$VERBOSE" = true ]; then
                get_unique_commits "staging" "main" | while read -r commit; do
                    echo "$commit  "
                done
            fi
        else
            echo "✅ staging está mergeado em main  "
        fi
    else
        echo "ℹ️ Não foi possível verificar staging -> main (uma ou ambas branches não existem)  "
    fi
    
    echo "### 🔍 Verificando demais branches...  "
    
    # Obter todas as branches, excluindo as principais
    all_branches=$(git branch | grep -v -E "develop|homolog|staging|main" | tr -d " *")
    
    # Para cada branch, verificar se está mergeada nas branches principais
    for branch in $all_branches; do
        echo "**Branch: $branch**  "
        
        # Verificar se a branch está mergeada em develop
        if branch_exists "develop"; then
            if has_unique_commits "$branch" "develop" && ! is_merged "$branch" "develop"; then
                echo "❌ NÃO mergeado em \`develop\`  "
                if [ "$VERBOSE" = true ]; then
                    get_unique_commits "$branch" "develop" | while read -r commit; do
                        echo "$commit  "
                    done
                fi
            else
                echo "✅ Mergeado em develop (ou sem commits exclusivos)  "
            fi
        fi
        
        # Verificar se a branch está mergeada em homolog
        if branch_exists "homolog"; then
            if has_unique_commits "$branch" "homolog" && ! is_merged "$branch" "homolog"; then
                echo "❌ NÃO mergeado em \`homolog\`  "
                if [ "$VERBOSE" = true ]; then
                    get_unique_commits "$branch" "homolog" | while read -r commit; do
                        echo "$commit  "
                    done
                fi
            else
                echo "✅ Mergeado em homolog (ou sem commits exclusivos)  "
            fi
        fi
        
        # Verificar se a branch está mergeada em staging
        if branch_exists "staging"; then
            if has_unique_commits "$branch" "staging" && ! is_merged "$branch" "staging"; then
                echo "❌ NÃO mergeado em \`staging\`  "
                if [ "$VERBOSE" = true ]; then
                    get_unique_commits "$branch" "staging" | while read -r commit; do
                        echo "$commit  "
                    done
                fi
            else
                echo "✅ Mergeado em staging (ou sem commits exclusivos)  "
            fi
        fi
        
        # Verificar se a branch está mergeada em main
        if branch_exists "main"; then
            if has_unique_commits "$branch" "main" && ! is_merged "$branch" "main"; then
                echo "❌ NÃO mergeado em \`main\`  "
                if [ "$VERBOSE" = true ]; then
                    # echo "*Commits pendentes de merge em \`main\`:*  "
                    get_unique_commits "$branch" "main" | while read -r commit; do
                        echo "$commit  "
                    done
                fi
            else
                echo "✅ Mergeado em main (ou sem commits exclusivos)  "
            fi
        fi
        
        echo -e "\n---\n"
    done
    
} > "$OUTPUT_FILE"

echo "Relatório gerado com sucesso: $OUTPUT_FILE  "
exit 0
