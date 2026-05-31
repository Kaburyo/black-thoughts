# office_room.gd
# Pièce "Bureau d'Al'".
#
# Toute la MÉCANIQUE (examiner, ramasser, utiliser, verrou, sortie de
# pièce) vit dans le moule room_base.gd. La voix intérieure est le
# service "Voix". Ici, on ne déclare que ce qui est PROPRE au bureau :
#   - le contenu des pensées et des objets ramassables
#   - la PORTE : on UTILISE la clé dessus pour partir (verbe Utiliser
#     du curseur-objet). Mains vides, elle donne un indice ; clé en
#     main, elle s'ouvre ; autre objet, "Inutile ici.".
#   - la PHOTO de Luna : posée sur le bureau, mais seulement APRÈS
#     l'entretien avec Jenny ; elle se ramasse comme n'importe quel
#     objet (mécanique héritée), puis disparaît une fois rangée. (L.24)

extends RoomBase


# --- Textes de la porte ---
# Mains vides, selon qu'on a déjà les clés ou non (règle E : le joueur
# doit toujours comprendre QUOI faire).
const PORTE_SANS_CLES: String = "Je ferais mieux de prendre\n mon manteau et mes CLES\n avant de partir."
const PORTE_AVEC_CLES: String = "JE ferais mieux de fermer\n avant de partir.\n Mes clés devraient faire l'affaire."
# Quand on UTILISE la clé sur la porte : elle s'ouvre, on part.
const PORTE_OUVERTE: String = "Bon, il est temps d'y aller.\n Cette enquête n'avancera pas toute seule."


# --- Contenu propre au bureau ---
# Appelée par le moule (room_base.gd) au tout début de _ready().
func _definir_contenu() -> void:
    # Les objets EXAMINABLES : clé = nom du nœud Area2D, valeur = pensée.
    pensees = {
        "LampArea": "Cette lampe a vu plus de nuits blanches que moi.",
        "WindowArea": "Temps de merde, pour une ville de merde...",
        "AlcoolArea": "Ce n'est pas raisonnable durant une enquête...",
        "PaintingArea": "Je me souviens même pas avoir acheté ce truc.",
        "FilesArea": "Si il y a bien quelque chose que je déteste,\n c'est la PAPERASSE !",
        "ChairArea": "J'ai plus dormi sur cette chaise\n que dans mon lit ces derniers temps...",
    }

    # Les objets RAMASSABLES : pour chaque zone, la pensée, l'id
    # d'inventaire et le sprite montré au centre de l'écran au ramassage.
    objets_ramassables = {
        "JacketArea": {
            "pensee": "Les CLES du bureau sont\n toujours dans la poche.",
            "id": "cles",
            "sprite": "res://assets/art/ui/item_keys.png",
        },
        "AshtrayArea": {
            "pensee": "Pas maintenant.\n Je peux les prendre pour plus tard.",
            "id": "cigarettes",
            "sprite": "res://assets/art/ui/item_cigarettes.png",
        },
        "PhotoArea": {
            "pensee": "La photo de la petite Luna.\n Autant la garder sur moi —\n c'est tout ce que j'ai pour l'instant.",
            "id": "picture_luna",
            "sprite": "res://assets/art/characters/Picture/picture_luna.png",
        },
    }

    # La PORTE est une zone UTILISABLE : on lui applique un objet en main.
    #   - mains vides  -> indice calculé par _texte_porte_fermee()
    #   - clé en main  -> PORTE_OUVERTE + on quitte la pièce
    #   - autre objet  -> "Inutile ici." (géré par le moule)
    utilisables = {
        "DoorArea": {
            "examiner": _texte_porte_fermee,
            "objets": {
                "cles": {
                    "pensee": PORTE_OUVERTE,
                    "action": _quitter_la_piece,
                },
            },
        },
    }

    # --- LA PHOTO DE LUNA (étape L.24, option A) ---
    # 1. Au départ, la photo n'est pas encore sur le bureau : cachée et
    #    non cliquable.
    _montrer_photo(false)
    # 2. Quand l'entretien se termine, Jenny a laissé la photo :
    #    on la fait apparaître sur le bureau.
    Dialogue.conversation_terminee.connect(_sur_entretien_termine)
    # 3. Une fois la photo rangée dans l'inventaire, on la retire du bureau.
    Inventaire.inventaire_modifie.connect(_sur_inventaire_modifie)

 ####
# --- TEST TEMPORAIRE D5 (à retirer ensuite) ---
    # On lance la conversation APRÈS la fin du _ready() de la pièce,
    # pour que l'abonnement aux signaux de Dialogue soit déjà fait.
    _lancer_test_dialogue.call_deferred()


# --- TEST TEMPORAIRE D5 (à retirer ensuite) ---
func _lancer_test_dialogue() -> void:
    var entretien: Conversation = load("res://resources/entretien_bureau.tres")
    Dialogue.jouer(entretien)
####


# --- LA PORTE : texte quand on la clique MAINS VIDES ---
# On adapte l'indice à l'état du jeu : pas encore les clés -> aller les
# chercher ; clés en poche -> penser à les utiliser sur la porte.
func _texte_porte_fermee() -> String:
    if Inventaire.possede("cles"):
        return PORTE_AVEC_CLES
    return PORTE_SANS_CLES


# --- LA PHOTO DE LUNA : apparition / disparition ---

# Montre ou cache la photo sur le bureau, EN MÊME TEMPS que sa zone
# cliquable. On règle les deux ensemble : ainsi on ne peut jamais
# cliquer une photo invisible, ni voir une photo non cliquable.
func _montrer_photo(est_visible: bool) -> void:
    $PhotoArea.visible = est_visible
    $PhotoArea.input_pickable = est_visible


# Fin de l'entretien : la photo apparaît sur le bureau.
# (On ne la ré-affiche pas si Al' l'a déjà ramassée.)
func _sur_entretien_termine() -> void:
    if Inventaire.possede("picture_luna"):
        return
    _montrer_photo(true)


# L'inventaire a changé : si la photo vient d'y entrer, on l'enlève
# du bureau.
func _sur_inventaire_modifie() -> void:
    if Inventaire.possede("picture_luna"):
        _montrer_photo(false)
