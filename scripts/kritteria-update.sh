#!/usr/bin/env bash
set -Eeuo pipefail

DIR="$HOME/.config/quickshell/end4-pC"
BASE_FILE="$DIR/.kritteria-upstream-base"
cd "$DIR"

echo
echo "=================================="
echo "       KRITTERIA UPDATER"
echo "=================================="

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    echo "Hay cambios locales pendientes. Guarda un commit primero."
    git status --short
    exit 1
fi

if [[ "$(git branch --show-current)" != "main" ]]; then
    echo "La rama activa no es main."
    exit 1
fi

if [[ ! -f "$BASE_FILE" ]]; then
    echo "Falta la base guardada de upstream."
    exit 1
fi

BASE="$(cat "$BASE_FILE")"
if [[ ! "$BASE" =~ ^[0-9a-f]{40,64}$ ]] || ! git cat-file -e "$BASE^{commit}" 2>/dev/null; then
    echo "La base guardada no es un commit valido."
    exit 1
fi

git fetch --quiet origin +refs/heads/main:refs/remotes/origin/main
if [[ "$(git rev-parse HEAD)" != "$(git rev-parse refs/remotes/origin/main)" ]]; then
    echo "Tu main no coincide con origin/main. Sincroniza primero."
    exit 1
fi

git fetch --quiet upstream +refs/heads/main:refs/remotes/upstream/main
NEW="$(git rev-parse refs/remotes/upstream/main)"

if ! git merge-base --is-ancestor "$BASE" "$NEW"; then
    echo "Upstream no desciende de la base guardada."
    echo "No aplicare la actualizacion automaticamente."
    exit 1
fi

if [[ "$BASE" == "$NEW" ]]; then
    echo "Kritteria ya esta al dia."
    exit 0
fi

echo
echo "=== Commits nuevos de end4-pC ==="
git log --oneline "$BASE..$NEW" --max-count=25

PATHS=(
    .
    ":(exclude).gitignore"
    ":(exclude).kritteria-upstream-base"
    ":(exclude)services/DotsUpdater.qml"
    ":(exclude)modules/ii/settings/pages/About.qml"
    ":(exclude)modules/ii/settings/DashboardHomePage.qml"
    ":(exclude)scripts/kritteria-update.sh"
    ":(exclude)services/gCloud/token-from-key-venv.sh"
    ":(exclude)services/gCloud/token_from_key.py"
)

echo
echo "=== Resumen de cambios upstream ==="
git diff --stat "$BASE" "$NEW" -- "${PATHS[@]}"

mkdir -p "$HOME/.cache"
PATCH="$(mktemp "$HOME/.cache/kritteria-patch.XXXXXX")"
FINAL_PATCH="$(mktemp "$HOME/.cache/kritteria-final.XXXXXX")"
TMP_WT=""

cleanup() {
    if [[ -n "$TMP_WT" && -d "$TMP_WT" ]]; then
        git -C "$DIR" worktree remove --force "$TMP_WT" >/dev/null 2>&1 || true
    fi
    rm -f "$PATCH" "$FINAL_PATCH"
}
trap cleanup EXIT

git diff --binary "$BASE" "$NEW" -- "${PATHS[@]}" > "$PATCH"

PATTERN="(^|/)([^/]*\.bak[^/]*|[^/]*\.disabled|false|\.env([^/]*)?|token-from-key-venv\.sh|token_from_key\.py|[^/]*credential[^/]*|[^/]*\.(pem|key))$"

if [[ -s "$PATCH" ]]; then
    echo
    echo "Probando en una copia temporal..."
    TMP_WT="$(mktemp -d "${TMPDIR:-/tmp}/kritteria-test.XXXXXX")"
    rmdir "$TMP_WT"
    git worktree add --quiet --detach "$TMP_WT" HEAD

    if ! git -C "$TMP_WT" apply --3way "$PATCH"; then
        echo "Conflictos detectados. La instalacion real no se ha tocado."
        git -C "$TMP_WT" diff --name-only --diff-filter=U || true
        exit 2
    fi

    BAD="$(git -C "$TMP_WT" diff --cached --name-only HEAD | grep -Ei "$PATTERN" || true)"
    if [[ -n "$BAD" ]]; then
        echo "Rutas que necesitan revision:"
        echo "$BAD"
        exit 3
    fi

    git -C "$TMP_WT" diff --cached --binary HEAD > "$FINAL_PATCH"
    git worktree remove --force "$TMP_WT"
    TMP_WT=""
    echo
    echo "=== Resultado de la combinacion ==="
    git apply --stat "$FINAL_PATCH"
else
    echo "No hay cambios aplicables fuera de los archivos protegidos."
fi

echo
read -r -p "Aplicar estos cambios a Kritteria? [y/N] " ANSWER
if [[ ! "$ANSWER" =~ ^([yY]|[sS])$ ]]; then
    echo "Cancelado. No se aplicaron cambios."
    exit 0
fi

BACKUP_BRANCH="backup/pre-upstream-$(date +%Y%m%d-%H%M%S)"
git branch "$BACKUP_BRANCH" HEAD
echo "Respaldo creado: $BACKUP_BRANCH"

if [[ -s "$FINAL_PATCH" ]] && ! git apply --index "$FINAL_PATCH"; then
    echo "Git no pudo aplicar el resultado. No limpiare ni borrare archivos."
    echo "Revisa git status. Respaldo: $BACKUP_BRANCH"
    exit 4
fi

printf "%s\n" "$NEW" > "$BASE_FILE"
git add -- "$BASE_FILE"

BAD="$(git diff --cached --name-only | grep -Ei "$PATTERN" || true)"
if [[ -n "$BAD" ]]; then
    echo "Archivos sospechosos en el indice:"
    echo "$BAD"
    exit 5
fi

git commit -m "Sync upstream to ${NEW:0:12}"

if ! git push origin main; then
    echo "El commit existe localmente, pero fallo el push."
    echo "Reintenta con git push origin main"
    exit 6
fi

git update-ref refs/kritteria/upstream-base "$NEW"
echo
echo "Actualizacion aplicada y publicada en Kritteria."
echo "Respaldo anterior: $BACKUP_BRANCH"

read -r -p "Reiniciar Quickshell ahora? [y/N] " RESTART
if [[ "$RESTART" =~ ^([yY]|[sS])$ ]]; then
    killall qs 2>/dev/null || true
    sleep 0.5
    setsid qs -c end4-pC >/tmp/kritteria-qs.log 2>&1 < /dev/null &
    disown || true
    echo "Log: /tmp/kritteria-qs.log"
else
    echo "Reinicia Quickshell manualmente cuando te convenga."
fi
