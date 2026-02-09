#!/bin/bash

RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
RESET="\e[0m"

# Permite ** para subpastas no Termux
shopt -s globstar
shopt -s nullglob

echo "=== SCANNER BY SOUZA ==="
echo

ZIP="$1"

if [ -z "$ZIP" ]; then
  echo "Uso: ./scanner.sh bugreport.zip"
  exit 1
fi

if [ ! -f "$ZIP" ]; then
  echo "Arquivo não encontrado: $ZIP"
  exit 1
fi

rm -rf scan_temp
mkdir scan_temp

unzip -qq "$ZIP" -d scan_temp

# Extrair ZIPs internos (bugreport dentro de bugreport)
for inner in scan_temp/**/*.zip; do
  [ -f "$inner" ] || continue
  unzip -qq "$inner" -d scan_temp/inner_logs
done

echo "Analisando arquivos de log..."
echo

score=0

# Palavras relacionadas a hack
keywords=(
  "painel"
  "cheat"
  "auxilio"
  "auxílio"
  "headtrick"
  "holograma"
  "wallhack"
  "aimbot"
  "menuhack"
)

# Possível desinstalação
uninstall_keywords=(
  "uninstall"
  "pm uninstall"
  "package removed"
  "removed package"
  "package deleted"
  "delete package"
)

# Whistelist para desinstalações
WHITELIST_UNINSTALL=(
  "^com\.android\."
  "^com\.google\."
  "^com\.oppo\."
  "^com\.realme\."
  "^com\.qualcomm\."
  "^com\.sprd\."
  "^com\.unisoc\."
  "^com\.mediatek\."
  "^com\.coloros\."
  "^com\.android\.launcher"
  "^com\.google\.android\.gms"
  "^com\.google\.android\.instantapps"
)

# Verificação da whitelist
is_whitelisted_uninstall() {
  local pkg="$1"
  for rule in "${WHITELIST_UNINSTALL[@]}"; do
    if [[ "$pkg" =~ $rule ]]; then
      return 0
    fi
  done
  return 1
}


# ===== SCAN PRINCIPAL =====
for file in $(find scan_temp -type f \( -name "*.txt" -o -name "*.log" \)); do
  for key in "${keywords[@]}"; do
    results=$(grep -ni --color=always "$key" "$file")
    if [ -n "$results" ]; then
      echo -e "${RED}[!] POSSÍVEL RASTRO DE CHEAT${RESET}"
echo -e "${RED}    Palavra:${RESET} \"$key\""
echo -e "${RED}    Arquivo:${RESET} $file"
      echo "$results" | while read -r line; do
        echo "    Linha: $line"
      done
      score=$((score+1))
    fi
  done
done

# ===== SCAN DE DESINSTALAÇÃO =====
echo
echo "=== ANALISANDO POSSÍVEL DESINSTALAÇÃO DE HACK ==="

grep -in "uninstall" scan_temp/*.txt scan_temp/**/*.txt 2>/dev/null | while read -r line; do

  pkg=$(echo "$line" | grep -oE "com\.[a-zA-Z0-9._]+" | head -n 1)

  [ -z "$pkg" ] && continue

  if is_whitelisted_uninstall "$pkg"; then
    continue
  fi

  echo -e "\e[31m[!] POSSÍVEL DESINSTALAÇÃO SUSPEITA\e[0m"
  echo -e "Pacote: \e[33m$pkg\e[0m"
  echo -e "Linha:  \e[90m$line\e[0m"
  score=$((score+2))

done


# ===== RESULTADO FINAL =====
echo
echo "=== RESULTADO ==="

if [ "$score" -eq 0 ]; then
  echo -e "STATUS: ${GREEN}LIMPO${RESET}"
elif [ "$score" -le 3 ]; then
  echo -e "STATUS: ${YELLOW}SUSPEITO${RESET}"
else
  echo -e "STATUS: ${RED}XITADO${RESET}"
fi

echo "Pontuação: $score"

