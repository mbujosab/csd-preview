#!/bin/bash
# deploy.sh - construye el sitio y lo despliega por SFTP en la web oficial
#
# Uso:
#   ./deploy.sh --check   solo comprueba las credenciales y lista la carpeta
#                         remota; no sube ni borra nada
#   ./deploy.sh           make build (URLs sin prefijo) y subida con
#                         borrado de lo que ya no exista en local
#
# Las credenciales se leen desde ~/.authinfo.gpg (cifrado con GPG)
# o desde ~/.authinfo (en texto plano, menos seguro).
#
# Formato de la entrada en ~/.authinfo o ~/.authinfo.gpg:
#   machine ciudadsantodomingo.org login csd@csdomingo.com port 22 password TU_PASSWORD
#
# Para cifrar ~/.authinfo con GPG:
#   gpg --symmetric --cipher-algo AES256 ~/.authinfo
#   rm ~/.authinfo   # borrar el original tras cifrar

set -euo pipefail

HOST="ciudadsantodomingo.org"
REMOTE_PATH="/html/"
MODE="${1:-deploy}"

# Leer credenciales desde ~/.authinfo.gpg o ~/.authinfo
if [ -f "$HOME/.authinfo.gpg" ]; then
    AUTHINFO=$(gpg --quiet --decrypt "$HOME/.authinfo.gpg")
elif [ -f "$HOME/.authinfo" ]; then
    AUTHINFO=$(cat "$HOME/.authinfo")
else
    echo "Error: no se encontró ~/.authinfo.gpg ni ~/.authinfo" >&2
    exit 1
fi

USER=$(echo "$AUTHINFO" | awk "/machine $HOST/"'{for(i=1;i<=NF;i++) if($i=="login") print $(i+1); exit}')
PASS=$(echo "$AUTHINFO" | awk "/machine $HOST/"'{for(i=1;i<=NF;i++) if($i=="password") print $(i+1); exit}')

if [ -z "$USER" ] || [ -z "$PASS" ]; then
    echo "Error: no se encontraron credenciales para $HOST en el fichero authinfo" >&2
    exit 1
fi

if [ "$MODE" = "--check" ] || [ "$MODE" = "check" ]; then
    echo "==> Comprobando acceso SFTP a $HOST:$REMOTE_PATH (solo lectura)..."
    lftp -u "$USER","$PASS" sftp://"$HOST" <<LFTP
  set sftp:connect-program "ssh -a -x -o StrictHostKeyChecking=accept-new"
  set net:max-retries 2
  set net:timeout 20
  cls -l $REMOTE_PATH
LFTP
    echo "==> Acceso correcto. No se ha subido nada."
    exit 0
fi

echo "==> Construyendo el sitio..."
make build

echo "==> Desplegando en $HOST:$REMOTE_PATH ..."
lftp -u "$USER","$PASS" sftp://"$HOST" <<LFTP
  set sftp:connect-program "ssh -a -x -o StrictHostKeyChecking=accept-new"
  set net:max-retries 3
  mirror --reverse --delete --verbose ./public/ $REMOTE_PATH
LFTP

echo "==> Despliegue completado."
