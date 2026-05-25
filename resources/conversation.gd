# conversation.gd
# LE MODÈLE d'une CONVERSATION : un dialogue complet, d'un bout à
# l'autre.
#
# Une conversation, c'est deux choses :
#   - la LISTE DES PERSONNAGES qui y participent (pour la démo : deux
#     au maximum, un à gauche, un à droite) ;
#   - la LISTE ORDONNÉE des répliques, jouées du début à la fin.
#
# Chaque dialogue du jeu (l'entretien du bureau, les échanges de la
# chambre de Luna, le dialogue d'avant-combat...) sera un fichier
# .tres séparé, créé à partir de ce modèle, rangé dans resources/.
#
# POURQUOI "Conversation" ET PAS "Dialogue" ? Le SERVICE qui joue les
# dialogues s'appelle `Dialogue` (autoload) ; un autoload et un
# class_name ne peuvent pas porter le même nom. La DONNÉE s'appelle
# donc `Conversation`. On écrit : Dialogue.jouer(une_conversation).

class_name Conversation
extends Resource


# --- Titre ---
# Un nom lisible pour cette conversation. Sert à s'y retrouver, et
# servira plus tard d'en-tête au récapitulatif de dialogue (L.7).
@export var titre: String = ""


# --- Les personnages participants ---
# La liste des personnages présents dans cette conversation.
# IMPORTANT : l'ORDRE de cette liste compte. Chaque réplique désigne
# son locuteur par un NUMÉRO (voir replique_dialogue.gd) : 0 = le
# premier personnage de cette liste, 1 = le second.
@export var personnages: Array[PersonnageDialogue] = []


# --- La suite des répliques ---
# La liste, dans l'ordre où le dialogue se déroule.
@export var repliques: Array[RepliqueDialogue] = []
