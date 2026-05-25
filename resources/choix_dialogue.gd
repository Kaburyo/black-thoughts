# choix_dialogue.gd
# LE MODÈLE d'un POINT DE CHOIX dans un dialogue.
#
# Quand la conversation arrive à un point de choix, le jeu s'arrête et
# propose au joueur 3 options (voir la "bible", section E :
# « 3 choix de réponse à chaque moment de choix »).
#
# Une option, c'est deux choses :
#   - un TEXTE (ce qui est écrit sur le bouton) ;
#   - une VALEUR CACHÉE (un nombre qui touchera la santé mentale d'Al'
#     quand cette option est choisie — voir la bible, L.1 et L.5).
#
# Les 3 options sont sur un PIED D'ÉGALITÉ : aucune position n'est
# « la bonne » ni « la mauvaise » (bible, section E). Le choix C est
# par convention le RETRANCHEMENT (« ... »), mais le modèle ne lui
# réserve AUCUN traitement spécial : c'est une option comme les autres.
#
# Ce point de choix n'est PAS un élément autonome de la liste : il
# vient s'ACCROCHER à la fin d'une réplique (voir replique_dialogue.gd).
#
# Une fois une option choisie, sa réponse est PRONONCÉE dans la boîte
# de dialogue comme une vraie réplique. C'est pourquoi le choix sait
# QUI parle (champ `locuteur` ci-dessous).

class_name ChoixDialogue
extends Resource


# --- QUI PRONONCE CES RÉPONSES ---
# Les trois options A/B/C sont toujours dites par le MÊME personnage
# (la réponse du joueur — en général Al'). Comme pour une réplique,
# ce personnage est désigné par son NUMÉRO dans la liste
# `personnages` de la conversation : 0 = premier personnage de la
# liste, 1 = second. Par défaut 0 — pour l'entretien du bureau, le
# premier personnage est justement Al', donc rien à régler là-bas.
@export var locuteur: int = 0


# --- OPTION A ---
@export_group("Option A")
@export_multiline var texte_a: String = ""
# Valeur cachée ajoutée à la santé mentale si A est choisi.
# Négative = fait baisser ; positive = fait remonter ; 0 = sans effet.
# Tout reste à 0 pour l'instant : le chiffrage viendra plus tard (L.5).
@export var valeur_a: float = 0.0

# --- OPTION B ---
@export_group("Option B")
@export_multiline var texte_b: String = ""
@export var valeur_b: float = 0.0

# --- OPTION C (le retranchement) ---
@export_group("Option C")
@export_multiline var texte_c: String = ""
@export var valeur_c: float = 0.0
