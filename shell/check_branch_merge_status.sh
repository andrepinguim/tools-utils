#!/bin/bash
# check_branch_merge_status.sh
# Script para verificar quais branches e commits não estão mergeados nas branches principais
# Uso: ./check_branch_merge_status.sh /caminho/para/repositorio [--verbose]

# Verifica se o diretório do repositório foi fornecido
if [ -z "$1" ]; then
    echo "Erro: Caminho do repositório não fornecido.  "
    echo "Uso: $0 /caminho/para/repositorio [--verbose]  "
    exit 1
fi

REPO_PATH="$1"
VERBOSE=false
[ "$2" = "--verbose" ] && VERBOSE=true

# Verifica se o diretório é um repositório git válido
if [ ! -d "$REPO_PATH/.git" ]; then
    echo "Erro: O diretório fornecido não é um repositório git válido.  "
    exit 1
fi

cd "$REPO_PATH" || exit 1

OUTPUT_FILE="branch_merge_report.md"

# Função auxiliar para imprimir com dois espaços no final da linha
print() {
    printf "%b  \n" "$1"
}

# Verifica se uma branch existe
branch_exists() {
    git show-ref --verify --quiet "refs/heads/$1"
}

# Verifica se há commits exclusivos da branch source em relação à target
has_unique_commits() {
    local source_branch="$1" target_branch="$2"
    if ! branch_exists "$source_branch" || ! branch_exists "$target_branch"; then
        return 1
    fi
    local commits
    commits=$(git log --oneline "$target_branch..$source_branch" 2>/dev/null)
    [ -n "$commits" ]
}

# Retorna os commits exclusivos da branch source em relação à target
get_unique_commits() {
    git log --oneline "$2..$1" 2>/dev/null
}

# Verifica se a branch source está mergeada na target
is_merged() {
    local source_branch="$1" target_branch="$2"
    if ! branch_exists "$source_branch" || ! branch_exists "$target_branch"; then
        return 1
    fi
    if ! has_unique_commits "$source_branch" "$target_branch"; then
        return 0
    fi
    local merge_base source_head
    merge_base=$(git merge-base "$source_branch" "$target_branch")
    source_head=$(git rev-parse "$source_branch")
    [ "$merge_base" = "$source_head" ]
}

# Checa e imprime o status de merge entre duas branches
check_merge() {
    local source="$1" target="$2"
    if branch_exists "$source" && branch_exists "$target"; then
        if has_unique_commits "$source" "$target" && ! is_merged "$source" "$target"; then
            print "❌ $source NÃO está mergeado em $target"
            if [ "$VERBOSE" = true ]; then
                print "*Commits pendentes de merge em \`$target\`:*"
                get_unique_commits "$source" "$target" | while IFS= read -r commit; do
                    print "$commit"
                done
            fi
        else
            print "✅ $source está mergeado em $target"
        fi
    else
        print "ℹ️ Não foi possível verificar $source -> $target (uma ou ambas branches não existem)"
    fi
}

{
    print "## Relatório de branches não mergeadas"
    print "### Repositório: $REPO_PATH"
    print "\n---"
    print "🔍 Verificando branches principais (\`develop\`, \`homolog\`, \`staging\`, \`main\`)..."
    
    check_merge "develop" "homolog"
    check_merge "homolog" "staging"
    check_merge "staging" "main"
    
    print "\n---"
    print "🔍 Verificando demais branches..."
    
    # Obtém todas as branches que não sejam as principais
    all_branches=$(git branch --format="%(refname:short)" | grep -vE '^(develop|homolog|staging|main)$')
    for branch in $all_branches; do
        print "**Branch: $branch**"
        for target in develop homolog staging main; do
            check_merge "$branch" "$target"
        done
        print "\n---"
    done
} > "$OUTPUT_FILE"

print "Relatório gerado com sucesso: $OUTPUT_FILE"
exit 0
