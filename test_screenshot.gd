extends SceneTree

func _init():
	# Attendre 3 secondes pour que la scène se charge
	await get_tree().create_timer(3.0).timeout
	
	# Capturer l'écran
	var img = get_viewport().get_texture().get_image()
	img.save_png("user://screenshot.png")
	
	print("Screenshot capturé dans user://screenshot.png")
	
	# Quitter
	quit()
