# replique_dialogue.gd
# LE MODÈLE d'une RÉPLIQUE de dialogue : UNE phrase, dite par UN
# personnage.
#
# Une conversation (voir conversation.gd) est une LISTE de ces
# répliques, jouées les unes après les autres.
#
# DEUX SUBTILITÉS, voulues par le design :
#
# 1. LE LOCUTEUR EST UN NUMÉRO. La réplique ne nomme pas son
#    personnage en dur : elle le désigne par sa PLACE dans la liste
#    `personnages` de la conversation. locuteur = 0 -> le premier
#    personnage de cette liste ; locuteur = 1 -> le second.
#    C'est ce qui rend le système générique : la même structure de
#    réplique sert pour Al'/Jenny, Al'/videur, ou n'importe qui.
#
# 2. LES VARIANTES D'AL'. Quand c'est Al' qui parle, sa réplique peut
#    CHANGER selon sa santé mentale (bible L.1, effet b). On prévoit
#    donc, en plus du texte de base, 4 textes de rechange (un par
#    palier). La démo démarre au palier Ok : le texte de base EST la
#    version Ok. Les 4 autres ne servent que si on VEUT faire varier
#    la réplique — sinon on les laisse vides.
#
# 3. LE CHOIX ACCROCHÉ. Une réplique peut, en option, porter un point
#    de choix « accroché à sa fin ». Si `choix` est vide, la réplique
#    est suivie simplement de la réplique suivante.

class_name RepliqueDialogue
extends Resource


# --- Qui parle ---
# Le NUMÉRO du personnage qui parle, dans la liste `personnages` de
# la conversation. 0 = premier personnage de la liste, 1 = second.
@export var locuteur: int = 0


# --- Le texte de base ---
# La phrase dite. Pour un PNJ, c'est le SEUL texte à remplir.
# Pour Al', c'est sa réplique au palier Ok (le palier de départ).
@export_multiline var texte: String = ""


# --- Variantes d'Al' selon la santé mentale (optionnel) ---
# À ne remplir QUE pour les répliques d'Al' qu'on veut faire varier.
# Laissé vide -> le texte de base ci-dessus est utilisé à la place.
@export_group("Variantes d'Al' (selon la santé mentale)")
@export_multiline var texte_good: String = ""
@export_multiline var texte_mid: String = ""
@export_multiline var texte_bof: String = ""
@export_multiline var texte_bad: String = ""


# --- Choix accroché (optionnel) ---
# Si rempli : une fois cette réplique affichée, le jeu présente ce
# point de choix. Si laissé vide : on passe directement à la réplique
# suivante de la liste.
@export_group("Choix accroché à la fin (optionnel)")
@export var choix: ChoixDialogue = null
