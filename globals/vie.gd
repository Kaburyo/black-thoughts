# vie.gd
# Jauge de VIE d'Al' (ses points de vie) — script AUTOLOAD (global).
#
# Cette jauge mesure l'état PHYSIQUE d'Al' (voir la "bible", point L.17).
# Elle variera sous l'effet des COMBATS et des ÉVÉNEMENTS de l'histoire
# (et NON des choix de dialogue, qui touchent la santé mentale).
# Son rôle d'affichage : elle PILOTE LE PORTRAIT d'Al' dans le HUD —
# 5 sprites du plus sain au plus blessé, selon le palier.
#
# CE FICHIER EST TRÈS COURT, ET C'EST VOULU.
# Toute la mécanique d'une jauge (valeur 0-100, les 5 paliers, le
# signal `modifiee`, `valeur()`, `palier()`, `modifier()`) vit dans le
# MOULE partagé `jauge.gd` (`class_name Jauge`). Ici, on ne déclare que
# ce qui est PROPRE à la vie : sa valeur de départ.
#
# Autoload : nom de nœud `Vie`. Comme la jauge doit survivre aux
# changements de pièce, c'est une donnée globale (même logique que
# l'Inventaire et que SanteMentale).

extends Jauge


# --- Le seul réglage propre à cette jauge ---
# Al' commence la démo en pleine forme physique : la vie démarre à 100
# (palier Good — le portrait montrera le sprite le plus sain). Les
# blessures viendront du combat. Le jour du chantier Combat, si on veut
# qu'Al' débute déjà amoché, il suffira de changer ce seul nombre.
const VIE_DEPART: float = 100.0


# Le moule (jauge.gd) appelle cette fonction au démarrage pour
# connaître la valeur de départ de CETTE jauge.
func _valeur_depart() -> float:
    return VIE_DEPART
