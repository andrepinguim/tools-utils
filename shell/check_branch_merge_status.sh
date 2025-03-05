#!/bin/bash

# Parâmetros
REPO_PATH=$1
OUTPUT_FILE="branch_merge_report.txt"
VERBOSE=$2
MAIN_BRANCHES=("develop" "homolog" "staging" "main")

# Valida se o repositório foi passado como argumento
if [[ -z "$REPO_PATH" ]]; then
    echo "Uso: $0 <caminho-do-repositorio> [--verbose]"
    exit 1
fi

# Entra no repositório
cd "$REPO_PATH" || { echo "Repositório não encontrado!"; exit 1; }

# Atualiza as informações do repositório
git fetch --all --prune

# Lista todas as branches locais e remotas, exceto HEAD e branches principais
BRANCHES=$(git branch -r | grep -vE "HEAD|$(IFS="|"; echo "${MAIN_BRANCHES[*]}")" | sed 's/origin\///')

# Limpa o arquivo de saída
echo "Relatório de branches não mergeadas" > "$OUTPUT_FILE"
echo "Repositório: $REPO_PATH" >> "$OUTPUT_FILE"
echo "------------------------------------" >> "$OUTPUT_FILE"

# Verifica se as branches principais estão mergeadas entre si
echo "🔍 Verificando branches principais..." >> "$OUTPUT_FILE"
for ((i = 0; i < ${#MAIN_BRANCHES[@]}; i++)); do
    for ((j = i + 1; j < ${#MAIN_BRANCHES[@]}; j++)); do
        BRANCH_A=${MAIN_BRANCHES[i]}
        BRANCH_B=${MAIN_BRANCHES[j]}

        if git show-ref --quiet refs/heads/$BRANCH_A && git show-ref --quiet refs/heads/$BRANCH_B; then
            if git merge-base --is-ancestor $BRANCH_A $BRANCH_B; then
                echo "✅ $BRANCH_A está mergeado em $BRANCH_B" >> "$OUTPUT_FILE"
            else
                echo "❌ $BRANCH_A NÃO está mergeado em $BRANCH_B" >> "$OUTPUT_FILE"
                
                # Modo verbose: exibe commits não mergeados
                if [[ "$VERBOSE" == "--verbose" ]]; then
                    echo "Commits pendentes de merge de $BRANCH_A para $BRANCH_B:" >> "$OUTPUT_FILE"
                    git log --oneline $BRANCH_B..$BRANCH_A >> "$OUTPUT_FILE"
                    echo "------------------------------------" >> "$OUTPUT_FILE"
                fi
            fi
        fi
    done
done
echo "------------------------------------" >> "$OUTPUT_FILE"

# Verifica se as branches de feature estão mergeadas nas principais
echo "🔍 Verificando branches de feature..." >> "$OUTPUT_FILE"
for BRANCH in $BRANCHES; do
    echo "Verificando $BRANCH..."
    echo "Branch: $BRANCH" >> "$OUTPUT_FILE"
    
    for MAIN in "${MAIN_BRANCHES[@]}"; do
        if git show-ref --quiet refs/heads/$MAIN; then
            if git merge-base --is-ancestor $BRANCH $MAIN; then
                echo "✅ Mergeado em $MAIN" >> "$OUTPUT_FILE"
            else
                echo "❌ NÃO mergeado em $MAIN" >> "$OUTPUT_FILE"
                
                # Modo verbose: exibe commits não mergeados
                if [[ "$VERBOSE" == "--verbose" ]]; then
                    echo "Commits pendentes de merge em $MAIN:" >> "$OUTPUT_FILE"
                    git log --oneline $MAIN..$BRANCH >> "$OUTPUT_FILE"
                    echo "------------------------------------" >> "$OUTPUT_FILE"
                fi
            fi
        else
            echo "⚠️  Branch $MAIN não existe no repositório" >> "$OUTPUT_FILE"
        fi
    done
    echo "------------------------------------" >> "$OUTPUT_FILE"
done

echo "✅ Relatório gerado em: $OUTPUT_FILE"
