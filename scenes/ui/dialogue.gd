# dialogue.gd
# Service autonome du SYSTÈME DE DIALOGUE — autoload "Dialogue".
#
# C'est la boîte de texte des conversations entre personnages
# (Al' et Jenny, plus tard les autres). À ne pas confondre avec la
# VOIX INTÉRIEURE (service "Voix") : ce sont deux services séparés.
#   - Voix     : les pensées d'Al', boîte SOMBRE, disparaît seule.
#   - Dialogue : les conversations, boîte CLAIRE, reste affichée,
#                avance au CLIC du joueur (voir la "bible", section E).
#
# ÉTAT À CETTE ÉTAPE (D5) : le service joue une conversation, gère les
# choix et leur effet, ET annonce le début / la fin de la conversation.
# Pendant un dialogue, le HUD est caché (appel direct) et le décor est
# gelé (la pièce s'abonne aux signaux ci-dessous et gère son verrou).
# NOTE : les valeurs cachées des choix valent toutes 0 pour l'instant.
# PAS ENCORE GÉRÉ : la VARIATION du texte d'Al' selon son palier.

extends CanvasLayer


# --- Signaux ---
# Émis quand une conversation COMMENCE et quand elle SE TERMINE.
# Les pièces (room_base.gd) s'y abonnent pour geler / dégeler leur
# point-and-click. Le service annonce ; chacun en tire les
# conséquences chez soi (même patron qu'Inventaire ou les jauges).
signal conversation_demarree
signal conversation_terminee


# --- Références aux nœuds ---
@onready var boite: Panel = $BoiteDialogue
@onready var texte_dialogue: Label = $BoiteDialogue/TexteDialogue
@onready var zone_choix: VBoxContainer = $ZoneChoix


# --- Réglage de l'animation du texte ---
const VITESSE_LETTRE: float = 0.045

# Taille du texte sur les boutons de choix.
const TAILLE_TEXTE_CHOIX: int = 36


# --- État de l'affichage ---
enum Etat { REPOS, ECRITURE, FINIE, CHOIX }
#   REPOS    : aucune conversation en cours, boîte cachée.
#   ECRITURE : une réplique est en train de s'écrire lettre par lettre.
#   FINIE    : la réplique est entièrement affichée, on attend le clic.
#   CHOIX    : 3 boutons sont affichés, on attend que le joueur choisisse.
var _etat: Etat = Etat.REPOS


# --- Conversation en cours ---
#   _conversation : le .tres en train d'être joué.
#   _index        : le numéro de la réplique actuellement affichée.
#   _choix_courant: le choix en cours d'affichage (null hors d'un choix).
var _conversation: Conversation = null
var _index: int = 0
var _choix_courant: ChoixDialogue = null


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    boite.visible = false
    zone_choix.visible = false
    boite.gui_input.connect(_sur_clic_boite)
    print("Dialogue prêt.")


# --- DÉMARRER UNE CONVERSATION ---
func jouer(conversation: Conversation) -> void:
    # Sécurité : une conversation vide ou absente ne lance rien.
    if conversation == null or conversation.repliques.is_empty():
        push_warning("Dialogue : conversation vide ou absente.")
        return

    _conversation = conversation
    _index = 0

    # On annonce le début : le HUD se cache, le décor se gèle.
    Hud.cacher()
    conversation_demarree.emit()

    _afficher_replique_courante()


# --- AFFICHER LA RÉPLIQUE COURANTE ---
func _afficher_replique_courante() -> void:
    var replique: RepliqueDialogue = _conversation.repliques[_index]

    # Pour l'instant on affiche toujours le texte de base. La variation
    # selon le palier de santé mentale d'Al' sera branchée plus tard.
    var texte: String = replique.texte

    texte_dialogue.text = texte
    texte_dialogue.visible_ratio = 0.0
    boite.visible = true

    _etat = Etat.ECRITURE
    _ecrire_lettre_par_lettre(texte.length())


# --- L'ÉCRITURE LETTRE PAR LETTRE ---
func _ecrire_lettre_par_lettre(nb_lettres: int) -> void:
    for i in range(nb_lettres):
        if _etat != Etat.ECRITURE:
            return
        texte_dialogue.visible_ratio = float(i + 1) / float(nb_lettres)
        await get_tree().create_timer(VITESSE_LETTRE).timeout

    _etat = Etat.FINIE


# --- CLIC SUR LA BOÎTE ---
func _sur_clic_boite(event: InputEvent) -> void:
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    if _etat == Etat.ECRITURE:
        _afficher_tout_de_suite()
    elif _etat == Etat.FINIE:
        _apres_replique()


# --- AFFICHER LA RÉPLIQUE D'UN COUP ---
func _afficher_tout_de_suite() -> void:
    _etat = Etat.FINIE
    texte_dialogue.visible_ratio = 1.0


# --- APRÈS UNE RÉPLIQUE FINIE ---
func _apres_replique() -> void:
    var replique: RepliqueDialogue = _conversation.repliques[_index]

    if replique.choix != null:
        _afficher_choix(replique.choix)
    else:
        _replique_suivante()


# --- AFFICHER UN CHOIX ---
func _afficher_choix(choix: ChoixDialogue) -> void:
    _etat = Etat.CHOIX
    _choix_courant = choix

    for ancien in zone_choix.get_children():
        ancien.queue_free()

    zone_choix.add_child(_creer_bouton_choix(choix.texte_a, 0))
    zone_choix.add_child(_creer_bouton_choix(choix.texte_b, 1))
    zone_choix.add_child(_creer_bouton_choix(choix.texte_c, 2))

    zone_choix.visible = true


# Construit un bouton de choix à partir d'un texte et de son numéro.
func _creer_bouton_choix(texte: String, numero: int) -> Button:
    var bouton := Button.new()
    bouton.text = texte
    bouton.add_theme_font_size_override("font_size", TAILLE_TEXTE_CHOIX)
    bouton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    bouton.pressed.connect(_sur_clic_choix.bind(numero))
    return bouton


# --- CLIC SUR UNE OPTION DE CHOIX ---
func _sur_clic_choix(numero: int) -> void:
    if _etat != Etat.CHOIX:
        return

    var delta: float = _valeur_option(numero)
    SanteMentale.modifier(delta)
    print("Dialogue : option %d choisie -> santé mentale %+.0f"
            % [numero, delta])

    _cacher_choix()
    _replique_suivante()


# --- VALEUR CACHÉE D'UNE OPTION ---
func _valeur_option(numero: int) -> float:
    match numero:
        0:
            return _choix_courant.valeur_a
        1:
            return _choix_courant.valeur_b
        2:
            return _choix_courant.valeur_c
        _:
            return 0.0


# --- CACHER LES BOUTONS DE CHOIX ---
func _cacher_choix() -> void:
    for bouton in zone_choix.get_children():
        bouton.queue_free()
    zone_choix.visible = false
    _choix_courant = null


# --- PASSER À LA RÉPLIQUE SUIVANTE ---
func _replique_suivante() -> void:
    _index += 1

    if _index >= _conversation.repliques.size():
        _terminer()
        return

    _afficher_replique_courante()


# --- FIN DE LA CONVERSATION ---
func _terminer() -> void:
    boite.visible = false
    zone_choix.visible = false
    _etat = Etat.REPOS
    _conversation = null
    _index = 0
    _choix_courant = null

    # On annonce la fin : le décor se dégèle, le HUD revient.
    conversation_terminee.emit()
    Hud.montrer()

    print("Dialogue : conversation terminée.")
