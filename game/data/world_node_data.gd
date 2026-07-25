class_name WorldNodeData
extends Resource

## Datos de un node del mapa (DAG).
## Es un Resource puro: solo describe el node, no ejecuta lógica.
## Crea un .tres por cada node del juego (nave, cresta, tunel, etc.).

# --- Identidad ---
@export var node_id: String = ""          ## Único: "nave", "cresta", "tunel"...
@export var depth: int = 0                ## Profundidad en el DAG: 0 = nave, mayor = más cerca del módulo
@export var biome: String = "default"     ## "cresta", "tunel", "marisma", "llanura", "modulo"

# --- Presentación ---
@export var display_name: String = ""     ## Nombre visible: "Cresta de Vidrio"
@export_multiline var description: String = ""

# --- Economía / peligro ---
@export var base_o2_cost: int = 10        ## Coste base de O₂ al comprometerse con este node
@export var base_threats: PackedStringArray = []  ## ["frio", "cortes", "oscuridad"...]

# --- Conexión de la ruta ---
## Siguiente node en la secuencia. null si este es el final (módulo).
@export var next_node: WorldNodeData = null

# --- Escena y arte ---
@export_file("*.tscn") var scene_path: String = ""  ## Escena jugable de este node
@export var background_texture: Texture2D
@export_range(0.0, 1.0) var parallax_speed: float = 0.3
@export var color_tint: Color = Color.WHITE

# --- Audio ---
@export_file("*.ogg", "*.wav") var audio_ambience: String = ""


## Devuelve true si este node tiene un siguiente node en la ruta.
func has_next() -> bool:
	return next_node != null
