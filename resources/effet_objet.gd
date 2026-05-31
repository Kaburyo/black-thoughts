# effet_objet.gd
# LE MODÈLE d'un EFFET porté par un objet d'inventaire.
#
# Quand on UTILISE un consommable sur Al' (les cigarettes sur le
# portrait), l'objet applique sa LISTE d'effets. Chaque effet de cette
# liste est décrit par une fiche de ce modèle : QUELLE jauge il touche,
# et de COMBIEN.
#
# Pour la démo, on ne construit que les effets INSTANTANÉS (un coup de
# jauge). Les effets TEMPORAIRES/VISUELS (flou, groggy) passeront plus
# tard par le service FiltreMental — on ajoutera alors une cible à
# l'enum sans rien casser (la "forme liste" est prévue pour ça).
#
# class_name -> EffetObjet apparaît dans Godot comme un type de
# ressource qu'on peut créer et ajouter dans l'inspecteur.

class_name EffetObjet
extends Resource


# Les jauges qu'un effet peut toucher. On en ajoutera au besoin.
enum Cible { SANTE_MENTALE, VIE }


# QUELLE jauge cet effet touche.
@export var cible: Cible = Cible.SANTE_MENTALE

# DE COMBIEN. Positif = fait MONTER la jauge ; négatif = la fait BAISSER.
@export var valeur: float = 0.0


# Applique cet effet à la bonne jauge. Les jauges sont des autoloads
# globaux : on les appelle directement par leur nom.
func appliquer() -> void:
    match cible:
        Cible.SANTE_MENTALE:
            SanteMentale.modifier(valeur)
        Cible.VIE:
            Vie.modifier(valeur)
