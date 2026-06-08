# office_room.gd — Pièce "Bureau d'Al'".
class_name OfficeRoom
extends RoomBase


static var entretien_deja_joue: bool = false

# État VERROU du bureau (mutable, survit aux changements de pièce). Lu
# plus tard par l'événement de cambriolage du jeu complet. Remis à false
# en nouvelle partie (ecran_titre). Modifiable à tout moment via les clés
# sur la porte : un "Non" raté à la 1re sortie n'est donc JAMAIS définitif.
static var bureau_verrouille: bool = false


# Pensée si Al' tente de partir sans ses clés (indice dur, anti-softlock).
const PORTE_SANS_CLES: String = "Je ferais mieux de prendre mon manteau et\n mes clés du bureau avant de partir."

# Fait Progression : le bureau a-t-il déjà été quitté une fois ?
const FAIT_BUREAU_QUITTE: String = "bureau_quitte"


func _definir_contenu() -> void:
    pensees = {
        "LampArea": "Cette lampe a vu plus de nuits blanches que moi.",
        "WindowArea": "Temps de merde, pour une ville de merde...",
        "AlcoolArea": "Ce n'est pas raisonnable durant une enquête...",
        "PaintingArea": "Je me souviens même pas avoir acheté ce truc.",
        "FilesArea": "Si il y a bien quelque chose que je déteste,\n c'est la PAPERASSE !",
        "ChairArea": "J'ai plus dormi sur cette chaise\n que dans mon lit ces derniers temps...",
        "AshtrayArea": "Un cendrier qui déborde.\n Autant de petites heures parties en fumée.",
    }

    objets_ramassables = {
        "JacketArea": {
            "pensee": "Les clés du bureau sont\n toujours dans la poche.",
            "id": "cles",
            "sprite": "res://assets/art/ui/item_keys.png",
        },
        "CigarettesArea": {
            "pensee": "Pas maintenant...\n Je peux les prendre au cas ou,\n pour plus tard.",
            "id": "cigarettes",
            "sprite": "res://assets/art/ui/item_cigarettes.png",
        },
        "PhotoArea": {
            "pensee": "La photo de Luna.\n Autant la garder sur moi —\n c'est tout ce que j'ai pour l'instant.",
            "id": "picture_luna",
            "sprite": "res://assets/art/characters/picture/picture_luna.png",
        },
    }

    # La PORTE : 1re sortie exige les clés (indice dur) et ouvre la chambre.
    # En plus, UTILISER les clés sur la porte (re)bascule le verrou.
    porte = {
        "zone": "DoorArea",
        "fait_sortie": FAIT_BUREAU_QUITTE,
        "objet_requis": "cles",
        "pensee_manque": PORTE_SANS_CLES,
        "debloque": "chambre_luna",
        "objet_action": { "cles": _basculer_verrou },
    }

    # --- PHOTO DE LUNA ---
    # Pendant l'entretien d'ouverture, elle est cachée (révélée à la fin).
    # À un RETOUR (l'entretien ne rejoue pas), on la montre tout de suite
    # tant qu'elle n'est pas ramassée — pour pouvoir revenir la chercher.
    if entretien_deja_joue:
        _montrer_photo(not Inventaire.possede("picture_luna"))
    else:
        _montrer_photo(false)

    Inventaire.inventaire_modifie.connect(_sur_inventaire_modifie)

    if Inventaire.possede("cigarettes"):
        _montrer_cigarettes(false)

    # --- ENTRETIEN D'OUVERTURE (une seule fois) ---
    # À sa fin, la photo de Luna apparaît (connexion utile seulement ici).
    if not entretien_deja_joue:
        entretien_deja_joue = true
        Dialogue.conversation_terminee.connect(_sur_entretien_termine)
        _lancer_entretien.call_deferred()


func _lancer_entretien() -> void:
    var entretien: Conversation = load("res://resources/entretien_bureau.tres")
    Dialogue.jouer(entretien)


# --- PREMIÈRE SORTIE : on propose de VERROUILLER ---
# On redéfinit la confirmation de 1re sortie du moule pour y glisser la
# question du verrou. On ne FORCE rien, et ce n'est PAS définitif : on
# peut toujours rebasculer le verrou en utilisant les clés sur la porte.
func _confirmer_premiere_sortie() -> void:
    Confirmation.demander("Penser à verrouiller le bureau en partant ?",
            _sortir_en_verrouillant, _sortir_sans_verrouiller)


func _sortir_en_verrouillant() -> void:
    bureau_verrouille = true
    _finaliser_premiere_sortie()


func _sortir_sans_verrouiller() -> void:
    bureau_verrouille = false
    # "Non" ou "Esc" : Al' remet le verrou à plus tard. On laisse la
    # pensée se finir AVANT d'ouvrir la carte (sinon elle la recouvrirait).
    await Voix.afficher_pensee_finie("Bah...\n Je verrouillerai plus tard.")
    _finaliser_premiere_sortie()


# UTILISER les clés sur la porte : bascule le verrou, à tout moment.
# La soupape de sécurité — un choix raté à la 1re sortie se rattrape ici.
# (Les clés sont un outil : elles ne se consomment pas.)
func _basculer_verrou() -> void:
    bureau_verrouille = not bureau_verrouille
    if bureau_verrouille:
        Voix.afficher_pensee("Je n'oublirai pas de fermer avant de partir.")
    else:
        Voix.afficher_pensee("Finalement non, je vais laisser ouvert.\n Pas sûr que ce soit une bonne idée par contre...")


func _montrer_photo(est_visible: bool) -> void:
    $PhotoArea.visible = est_visible
    $PhotoArea.input_pickable = est_visible


func _montrer_cigarettes(est_visible: bool) -> void:
    $CigarettesArea.visible = est_visible
    $CigarettesArea.input_pickable = est_visible


# Fin de l'entretien : la photo de Luna apparaît (si pas déjà prise).
func _sur_entretien_termine() -> void:
    if Inventaire.possede("picture_luna"):
        return
    _montrer_photo(true)


func _sur_inventaire_modifie() -> void:
    if Inventaire.possede("picture_luna"):
        _montrer_photo(false)
    if Inventaire.possede("cigarettes"):
        _montrer_cigarettes(false)
