#!/usr/bin/env bash

TOKEN_DIR="$HOME/.1password-env"

function default_vault {
  echo -n "Vault" >&2
  [ ! -z "$OP_DEFAULT_VAULT" ] && echo -n " ($OP_DEFAULT_VAULT)" >&2
  echo -n ": " >&2
  read -r __vault

  echo "${__vault:-$OP_DEFAULT_VAULT}"
}

function default_email {
  echo -n "Email" >&2
  [ ! -z "$OP_DEFAULT_EMAIL" ] && echo -n " ($OP_DEFAULT_EMAIL)" >&2
  echo -n ": " >&2
  read -r __email

  echo "${__email:-$OP_DEFAULT_EMAIL}"
}

function default_secretkey {
  if [ -z "$OP_DEFAULT_SECRET_KEY" ]; then
    echo -n 'Secret Key: ' >&2
    read -s -r __secretkey
    echo "$__secretkey"
  else
    echo "$OP_DEFAULT_SECRET_KEY"
  fi
}

function load_saved_session {
  if [ -f "$TOKEN_DIR/defaults" ]; then
    source "$TOKEN_DIR/defaults"
  fi
  if [ -f "$TOKEN_DIR/session" ]; then
    source "$TOKEN_DIR/session"
  fi
}

function ensure_signed_in {
  load_saved_session

  echo -n '1Password vault unlocked... ' >&2
  op get account >/dev/null 2>&1 && { echo -e '\x1B[0;32m✔\x1B[0m' >&2; return 0; }
  echo -e '\x1B[0;31mⅹ\x1B[0m' >&2
  echo '' >&2

  local vault
  vault=$(default_vault)

  local email
  email=$(default_email)

  local secretkey
  secretkey=$(default_secretkey)

  echo

  session=$(op signin "$vault" "$email" "$secretkey" --output=raw)
  
  mkdir -p "$TOKEN_DIR" >/dev/null 2>&1
  chmod 700 "$TOKEN_DIR" >/dev/null 2>&1
  cat > "$TOKEN_DIR/defaults" << EOF
export OP_DEFAULT_VAULT='$vault'
export OP_DEFAULT_EMAIL='$email'
EOF
  cat > "$TOKEN_DIR/session" << EOF
export OP_SESSION_$vault='$session'
EOF
  chmod -R 600 "$TOKEN_DIR/"*

  load_saved_session
}
