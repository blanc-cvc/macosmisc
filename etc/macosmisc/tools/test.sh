#!/bin/bash

213.44.20.13


#sudo fs_usage -f filesys | grep "/chemin/vers/le/fichier_ou_dossier"   
while IFS= read -r line || [[ -n "$line" ]]; do
    read -r col1 path <<< "$line"
    if [ "$col1" == "*" ]; then
        echo "$path"
        if [[ -e "$path" ]]; then # -not -user root
            find "$path" -type f -perm -o=w 2>/dev/null | while IFS= read -r file; do
                # Afficher les détails avec ls -l pour voir qui est le propriétaire
                ls -ld "$file"
            done
        else
            echo "$path doesnt exist"
        fi
    fi
done < "/System/Library/Sandbox/rootless.conf"
