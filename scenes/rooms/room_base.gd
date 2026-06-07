# room_base.gd
# LE MOULE des pièces point-and-click.
# Contient toute la mécanique COMMUNE à chaque pièce :
#   - EXAMINER (un clic = une pensée)
#   - RAMASSER (un clic = pensée + sprite + rangement en inventaire)
#   - UTILISER un objet en main sur une zone du décor (verbe du curseur-objet)
#   - MONTRER un objet à un PNJ, ou lui PARLER (un clic sur un PNJ)
#   - QUITTER une pièce -> OUVRE LA CARTE de navigation (choix de destination)
#   - le verrou des interactions
#   - le gel du décor pendant un dialogue
#
# La voix intérieure d'Al' (la boîte de texte) NE vit plus ici :
# c'est le service autonome "Voix" (autoload).
# Le fondu au noir de l'écran NON plus : c'est le service "Fondu".
# L'objet "en main" appartient au service "ObjetEnMain" (autoload).
# La CARTE de navigation est le service "EcranCarte" (autoload).
#
# Une pièce concrète (office_room.gd, chambre_luna_room.gd...) fait
# "extends RoomBase" et hérite GRATUITEMENT de tout ça.
# Elle n'a plus qu'à remplir _definir_contenu() avec SES propres données.

class_name RoomBase
extends Node2D


# --- Références aux nœuds ---
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var pickup_sprite: Sprite2D = $PickupSprite


# --- Réglages ---
const DUREE_LECTURE: float = 4.0
const ECHELLE_PICKUP: float = 0.3

# Pensée d'Al' quand il essaie d'utiliser un objet sur une cible qui
# ne l'accepte pas (le repli générique de la bible, décision L.26-2).
const PENSEE_OBJET_INUTILE: String = "Inutile ici."

# Pensée d'Al' quand il MONTRE un objet à un PNJ que ça ne concerne pas.
const PENSEE_RIEN_A_MONTRER: String = "Inutile de lui montrer ça."


# --- Verrou des interactions ---
# Quand true, tous les clics du décor sont ignorés. Posé pendant une
# transition (sortie de pièce) ET pendant un dialogue.
var _interactions_bloquees: bool = false


# --- Les données de la pièce ---
var pensees: Dictionary = {}
var objets_ramassables: Dictionary = {}

# Les zones du décor sur lesquelles on peut UTILISER un objet en main.
# Forme attendue, pour chaque zone (clé = nom du nœud Area2D) :
#   {
#     "examiner": <pensée quand on clique SANS objet en main>,
#                 -> peut être un texte fixe, OU une fonction (Callable)
#                    qui calcule le texte selon l'état du jeu. Optionnel.
#     "objets": {
#         <id de l'objet accepté> : {
#             "pensee": <pensée d'Al' quand ça marche>,   (optionnel)
#             "action": <fonction de la pièce à appeler>, (optionnel)
#         },
#         ...
#     }
#   }
var utilisables: Dictionary = {}

# Les PNJ présents dans la pièce. Un PNJ est PEINT dans le décor ; sa
# zone cliquable est une simple Area2D invisible posée par-dessus.
# Forme attendue, pour chaque PNJ (clé = nom du nœud Area2D) :
#   {
#     "parler": <chemin .tres d'une Conversation>  -> clic SANS objet en main
#     "objets": {                                   -> verbe MONTRER
#         <id de l'objet montré> : <chemin .tres d'une Conversation>,
#     }
#   }
# MONTRER ne consomme jamais l'objet (une preuve reste une preuve).
var pnj_presents: Dictionary = {}

# ANCIEN champ de l'enchaînement en ligne droite. DÉSORMAIS INERTE :
# c'est la CARTE (EcranCarte) qui décide de la destination quand on
# quitte une pièce. On le laisse pour ne pas casser les pièces qui le
# renseignent encore ; on balaiera ces lignes mortes lors d'un nettoyage.
var scene_suivante: String = ""


# --- Point d'accroche à remplir par chaque pièce ---
func _definir_contenu() -> void:
    pass


# Appelée automatiquement une fois, au lancement de la scène.
func _ready() -> void:
    # 0. À l'arrivée, l'écran peut être encore noir : on révèle en fondu.
    Fondu.fondu_depuis_noir()

    # 1. La pièce déclare son contenu (pensées, objets, porte, PNJ...).
    _definir_contenu()

    # 2. Branchement des objets examinables.
    for nom_zone in pensees:
        var zone := get_node(nom_zone) as Area2D
        var texte: String = pensees[nom_zone]
        zone.input_event.connect(_sur_clic.bind(texte))

    # 3. Branchement des objets ramassables.
    for nom_zone in objets_ramassables:
        var zone := get_node(nom_zone) as Area2D
        var donnees: Dictionary = objets_ramassables[nom_zone]
        zone.input_event.connect(_sur_clic_ramassable.bind(nom_zone, donnees))

    # 3-bis. Branchement des zones UTILISABLES (un objet en main dessus).
    for nom_zone in utilisables:
        var zone := get_node(nom_zone) as Area2D
        var donnees: Dictionary = utilisables[nom_zone]
        zone.input_event.connect(_sur_clic_utilisable.bind(donnees))

    # 3-ter. Branchement des PNJ (leur parler / leur montrer un objet).
    for nom_zone in pnj_presents:
        var zone := get_node(nom_zone) as Area2D
        var donnees: Dictionary = pnj_presents[nom_zone]
        zone.input_event.connect(_sur_clic_pnj.bind(donnees))

    # 4. On s'abonne au service Dialogue : pendant une conversation,
    #    le décor se gèle ; à la fin, il se dégèle.
    Dialogue.conversation_demarree.connect(_sur_dialogue_demarre)
    Dialogue.conversation_terminee.connect(_sur_dialogue_termine)

    # 5. Lancement de la musique d'ambiance.
    music_player.play()


# --- GEL DU DÉCOR PENDANT UN DIALOGUE ---
func _sur_dialogue_demarre() -> void:
    _interactions_bloquees = true


func _sur_dialogue_termine() -> void:
    _interactions_bloquees = false


# --- EXAMINER ---
func _sur_clic(_viewport: Node, event: InputEvent, _shape_idx: int, texte: String) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    # Un objet en main ? Alors ce clic est une tentative d'UTILISER.
    if ObjetEnMain.a_un_objet():
        Voix.afficher_pensee(PENSEE_OBJET_INUTILE)
        return

    # Mains vides : examen normal.
    Voix.afficher_pensee(texte)


# --- RAMASSER ---
func _sur_clic_ramassable(_viewport: Node, event: InputEvent, _shape_idx: int,
        nom_zone: String, donnees: Dictionary) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    if ObjetEnMain.a_un_objet():
        Voix.afficher_pensee(PENSEE_OBJET_INUTILE)
        return

    if Inventaire.possede(donnees["id"]):
        return

    ramasser(nom_zone, donnees)


# Séquence de ramassage : pensée + sprite affiché, puis rangement.
func ramasser(nom_zone: String, donnees: Dictionary) -> void:
    pickup_sprite.texture = load(donnees["sprite"])
    pickup_sprite.scale = Vector2(ECHELLE_PICKUP, ECHELLE_PICKUP)
    pickup_sprite.visible = true

    await Voix.afficher_pensee_finie(donnees["pensee"])

    pickup_sprite.visible = false
    Inventaire.ajouter(donnees["id"])

    var zone := get_node(nom_zone) as Area2D
    zone.input_pickable = false


# --- UTILISER un objet sur une zone du décor ---
func _sur_clic_utilisable(_viewport: Node, event: InputEvent, _shape_idx: int,
        donnees: Dictionary) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    # CAS 1 — mains vides : on EXAMINE la zone.
    if not ObjetEnMain.a_un_objet():
        var texte: Variant = donnees.get("examiner", "")
        if texte is Callable:
            texte = texte.call()
        if texte != "":
            Voix.afficher_pensee(texte)
        return

    # CAS 2 — un objet est en main : on tente de l'utiliser ici.
    var id_objet: String = ObjetEnMain.id()
    var objets_acceptes: Dictionary = donnees.get("objets", {})

    # Mauvaise cible : pensée générique, objet GARDÉ.
    if not objets_acceptes.has(id_objet):
        Voix.afficher_pensee(PENSEE_OBJET_INUTILE)
        return

    # Bonne cible : on applique l'effet de cet objet sur cette zone.
    var effet: Dictionary = objets_acceptes[id_objet]

    if effet.get("pensee", "") != "":
        Voix.afficher_pensee(effet["pensee"])

    var action: Variant = effet.get("action", null)
    if action is Callable:
        action.call()

    # On repose l'objet (la clé n'est pas consommée : elle reste en inventaire).
    ObjetEnMain.reposer()


# --- MONTRER un objet à un PNJ, ou lui PARLER ---
func _sur_clic_pnj(_viewport: Node, event: InputEvent, _shape_idx: int,
        donnees: Dictionary) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    # CAS 1 — mains vides : on PARLE au PNJ (sa conversation par défaut).
    if not ObjetEnMain.a_un_objet():
        _jouer_conversation(donnees.get("parler", ""))
        return

    # CAS 2 — un objet est en main : on tente de le MONTRER.
    var id_objet: String = ObjetEnMain.id()
    var conversations: Dictionary = donnees.get("objets", {})

    if not conversations.has(id_objet):
        Voix.afficher_pensee(PENSEE_RIEN_A_MONTRER)
        return

    _jouer_conversation(conversations[id_objet])


# Petite aide : charge une Conversation (.tres) par son chemin et la joue.
func _jouer_conversation(chemin: String) -> void:
    if chemin == "":
        return
    var conversation := load(chemin) as Conversation
    if conversation != null:
        Dialogue.jouer(conversation)


# --- QUITTER UNE PIÈCE -> OUVRIR LA CARTE ---
# La carte de navigation REMPLACE l'ancienne sortie en ligne droite.
# Toute porte appelle "demander_a_quitter()" en UNE ligne, en fournissant
# seulement la pensée de départ de la pièce (sa "voix"). Ouvrir la carte
# EST la décision de partir ; le bouton "Fermer" de la carte sert de
# "non, finalement je reste" (plus besoin d'une question Oui/Non).
func demander_a_quitter(pensee_sortie: String = "") -> void:
    _ouvrir_la_carte(pensee_sortie)


func _ouvrir_la_carte(pensee_sortie: String) -> void:
    # On gèle le décor le temps de dire la pensée de départ, PUIS on le
    # dégèle juste avant d'afficher la carte : ainsi, si le joueur clique
    # "Fermer", la pièce n'est pas restée gelée derrière lui.
    _interactions_bloquees = true
    if pensee_sortie != "":
        await Voix.afficher_pensee_finie(pensee_sortie)
    _interactions_bloquees = false
    EcranCarte.ouvrir()
