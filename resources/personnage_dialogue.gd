# personnage_dialogue.gd
# LE MODÈLE d'une fiche de PERSONNAGE DE DIALOGUE.
#
# Ce script ne décrit AUCUN personnage précis. Il dit seulement quelles
# informations une fiche de personnage contient : un nom, un sprite de
# portrait par défaut, sa galerie d'expressions, et le côté de l'écran
# où ce portrait s'affiche.
#
# Chaque personnage qui peut apparaître dans un dialogue (Al', Jenny,
# plus tard le videur du bar...) sera un fichier .tres séparé, créé à
# partir de ce modèle. Ces .tres vivent dans resources/.
#
# C'est ce qui rend le système de dialogue GÉNÉRIQUE : ajouter un
# personnage = créer une fiche .tres, sans toucher au code (voir la
# "bible", règles A.8 et A.9).
#
# "class_name" donne un nom à ce modèle : il apparaît dans le menu
# "Create Resource" de Godot, comme un type à part entière.

class_name PersonnageDialogue
extends Resource


# --- Les deux côtés possibles de l'écran ---
# Un "enum" est une liste de noms : ici, les deux places où un
# portrait peut se tenir. Pour la démo, un dialogue affiche au plus
# deux personnages : un à gauche, un à droite.
enum Cote { GAUCHE, DROITE }


# --- Les cases de la fiche ---
# @export = cette donnée sera REMPLIE dans l'éditeur Godot,
# directement dans le fichier .tres, sans toucher au code.

# Le nom du personnage (ex. "Al'", "Jenny"). Sert à s'y retrouver
# dans l'éditeur, et pourra servir plus tard d'étiquette "qui parle".
@export var nom: String = ""

# L'image du portrait par DÉFAUT (le visage neutre), montrée pendant
# le dialogue quand une réplique ne demande aucune expression précise.
@export var sprite: Texture2D = null

# La GALERIE d'expressions de ce personnage.
# C'est un dictionnaire : à chaque MOT-CLÉ (ex. "angry", "smile") on
# associe une image de portrait. Une réplique (voir replique_dialogue.gd)
# n'a qu'à citer un de ces mots-clés pour afficher le bon visage.
# Laissé vide -> le personnage n'a que son visage par défaut (cas de
# Jenny pour la démo). Ajouter une expression = ajouter une ligne ici,
# sans toucher au code (règles A.8 / A.9 de la bible).
@export var expressions: Dictionary[String, Texture2D] = {}

# Le côté de l'écran où ce portrait se place. Dans l'éditeur, ce
# champ devient un menu déroulant (Gauche / Droite).
@export var cote: Cote = Cote.GAUCHE
