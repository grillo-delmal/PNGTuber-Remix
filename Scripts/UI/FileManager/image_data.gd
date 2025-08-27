extends Resource
class_name ImageData

var runtime_texture = null
var anim_texture 
var img_animated : bool = false
var is_apng : bool = false
var image_data = null
var frames : Array[AImgIOFrame] = []
var animated_frames : Array[AnimatedFrame]
var has_data : bool = false
var image_name : String = "Placeholder"
var trimmed = false
var offset = Vector2.ZERO

var id : int = randi()

func get_data() -> Dictionary:
	var data : Dictionary = {
		runtime_texture = runtime_texture.get_image().save_png_to_buffer(),
		anim_texture = anim_texture,
		img_animated = img_animated,
		is_apng = is_apng,
		image_data = image_data,
		image_name = image_name,
		trimmed = trimmed,
		offset = offset,
		id = id,
	}
	return data

func set_data(_data : Dictionary):
	if _data.get("runtime_texture", null) != null:
		var img = Image.new()
		img.load_png_from_buffer(_data.runtime_texture)
		var texture = ImageTexture.create_from_image(img)
		runtime_texture = texture
	
	img_animated = _data.get("img_animated", false)
	is_apng = _data.get("is_apng", false)
	anim_texture =  _data.get("anim_texture", null)
	if anim_texture != null:
		if img_animated:
			SaveAndLoad.load_gif_from_buffer(anim_texture, self)
		elif is_apng:
			SaveAndLoad.load_apng_from_buffer(anim_texture, self)
	
	image_data = _data.get("image_data", [])
	image_name = _data.get("image_name", "Placeholder")
	trimmed = _data.get("trimmed", false)
	offset = _data.get("offset", Vector2.ZERO)
	id = _data.get("id", randi())
	
	#printt(img_animated, is_apng)

func image_replaced():
	Global.image_replaced.emit(self)
