class_name WindowPopup
extends Window

@onready var message_label = $Message
@onready var ok_button = $OkButton

@export var message_text: String
@export var relative_position: Vector2
@export var hovered_button_color: Color

func _ready():
	mode = Window.MODE_WINDOWED

func _process(_delta):
	var monitor_size = DisplayServer.screen_get_size()
	var right_bottom_max = Vector2(monitor_size - size)
	message_label.text = message_text
	position = right_bottom_max * relative_position
