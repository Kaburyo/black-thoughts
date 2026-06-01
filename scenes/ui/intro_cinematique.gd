extends Control

# ============================================================
#  CINÉMATIQUE D'INTRO — Planche BD façon "Blacksad"
#  Étape 1 : composition statique des 3 cases + musique.
#  (La chorégraphie d'apparition case par case, le switch
#   image 3 -> 4, le "toc toc", la bulle et le passage au
#   bureau seront ajoutés à l'étape 2.)
# ============================================================

# --- Références aux cases (prêtes pour l'étape 2) ---
@onready var case1: TextureRect = $Case1
@onready var case2: TextureRect = $Case2
@onready var case3: TextureRect = $Case3
@onready var case3_detail: TextureRect = $Case3/Case3_detail  # image 4 (ombre de la main)
@onready var plaque_agence: Label = $Case3/PlaqueAgence


func _ready() -> void:
    # Étape 1 : on affiche simplement la planche complète, musique lancée.
    # Rien d'autre pour l'instant : on valide d'abord la composition à l'écran.
    pass
