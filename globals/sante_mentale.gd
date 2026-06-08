# sante_mentale.gd
# Jauge de SANTÉ MENTALE d'Al' — script AUTOLOAD (global).
#
# Cette jauge mesure le MORAL BRUT d'Al' (voir la "bible", point L.1).
# Elle pilotera le filtre mental (assombrissement des bords de l'écran)
# et le ton des réponses d'Al' en dialogue. Elle ne touche PAS au
# portrait d'Al' : ça, c'est le rôle de la jauge de Vie.
#
# CE FICHIER EST TRÈS COURT, ET C'EST VOULU.
# Toute la mécanique d'une jauge (valeur 0-100, les 5 paliers, le
# signal `modifiee`, `valeur()`, `palier()`, `modifier()`) vit dans le
# MOULE partagé `jauge.gd` (`class_name Jauge`). Ici, on ne déclare que
# ce qui est PROPRE à la santé mentale : sa valeur de départ.
#
# Autoload : nom de nœud `SanteMentale`. Comme la jauge doit survivre
# aux changements de pièce, c'est une donnée globale (même logique que
# l'Inventaire).
 
extends Jauge
 
 
# --- Le seul réglage propre à cette jauge ---
# Al' commence la démo déjà cabossé : la santé mentale démarre à 75
# (ce qui correspond au palier Ok). C'est son fil rouge.
const SANTE_DEPART: float = 75.0
 
 
# Le moule (jauge.gd) appelle cette fonction au démarrage pour
# connaître la valeur de départ de CETTE jauge.
func _valeur_depart() -> float:
    return SANTE_DEPART
 
