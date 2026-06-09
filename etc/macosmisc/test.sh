#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PF_FILE="$SCRIPT_DIR/../pf.conf.test"

TEMP_FILE=$(mktemp)

# Boucle sur les interfaces
for interface in "en0" "en1"; do
    # On repart du fichier actuel à chaque interface
    cp "$PF_FILE" "$TEMP_FILE"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # On vérifie directement si la ligne originale contient $extif (même commentée)
        if [[ "$line" == *'$extif'* ]]; then
            
            # Nettoie la ligne pour créer la nouvelle règle (enlève commentaires et espaces)
            clean_line="${line%%#*}"
            clean_line="${clean_line% }"
            
            # Crée la nouvelle ligne avec l'interface et le tag
            new_line="${clean_line//\$extif/$interface} # @IF_$interface"
            
            # Vérifie si la nouvelle ligne (ou sa version sans tag) existe DÉJÀ dans le fichier
            # Cela évite les doublons, que la ligne originale soit commentée ou non
            if ! grep -qF "$new_line" "$TEMP_FILE" && ! grep -qF "${new_line%% #*}" "$TEMP_FILE"; then
                
                # On utilise la ligne originale EXACTE (avec ou sans #) comme motif de recherche
                # pour insérer juste en dessous.
                # On échappe les caractères spéciaux pour awk (bien que awk soit plus souple que sed)
                awk -v orig="$line" -v insert="$new_line" '
                {
                    print $0
                    if ($0 == orig) print insert
                }' "$TEMP_FILE" > "${TEMP_FILE}.new" && mv "${TEMP_FILE}.new" "$TEMP_FILE"
                
                echo "Inséré : $new_line (depuis : $line)"
            fi
        fi
    done < "$PF_FILE"
    
    # Mise à jour du fichier principal
    mv "$TEMP_FILE" "$PF_FILE"
done

exit 0

## if ! grep -qF "$new_line" "$TEMP_FILE" && ! grep -qF "${new_line%% #*}" "$TEMP_FILE"; then
# Cette ligne est une condition de sécurité qui empêche l'ajout de doublons. Elle ne déclenche le bloc then (l'insertion) que si aucune des deux vérifications suivantes n'est trouvée dans le fichier temporaire :

# ! grep -qF "$new_line" "$TEMP_FILE"
# Vérifie si la ligne complète (avec le tag # @IF_en0 par exemple) existe déjà.
# But : Évite de dupliquer une règle qui aurait déjà été générée précédemment.
# && ! grep -qF "${new_line%% #*}" "$TEMP_FILE"
# ${new_line%% #*} : Cette partie coupe la ligne à partir du premier #. Elle extrait donc la règle brute, sans le tag de commentaire.
# Vérifie si cette règle brute existe déjà (qu'elle soit taguée ou non).
# But : Évite d'ajouter pass in on en0 # @IF_en0 si pass in on en0 existe déjà sous une autre forme.
# En résumé : La commande dit : « Si la ligne complète n'existe pas ET que la règle de base n'existe pas non plus, alors on a le droit d'insérer. »

# -q : Mode silencieux (ne renvoie que le code de succès/échec).
# -F : Recherche de texte fixe (traite $, *, . comme des caractères normaux, pas des regex).
# ! : Négation (inverse le résultat : vrai si non trouvé).
# && : Et logique (les deux conditions doivent être vraies).



NET_IFACES=($(ifconfig -v | awk '
/^[a-z0-9]+:/ { 
    gsub(/:$/, "", $1); iface=$1; next 
}
/type:/ && ($2 == "Wi-Fi" || $2 == "Ethernet") && iface !~ /^(awdl|llw)/ { 
    print iface 
}'))

echo "${NET_IFACES[@]}"