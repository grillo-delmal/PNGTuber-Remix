extends Node
# image_trimmer.gd
class_name ImageTrimmer

# Calculate the trim boundaries of an image
static func calculate_trim_info(image: Image) -> Dictionary:
	var width = image.get_width()
	var height = image.get_height()
	
	# Find boundaries of non-transparent pixels
	var min_x = width
	var min_y = height
	var max_x = -1
	var max_y = -1
	
	# Scan the entire image for non-transparent pixels
	for y in range(height):
		for x in range(width):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.01:  # If pixel is not fully transparent
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	
	# Check if we found any non-transparent pixels
	if max_x >= min_x and max_y >= min_y:
		var trim_width = max_x - min_x + 1
		var trim_height = max_y - min_y + 1
		var rect = Rect2(min_x, min_y, trim_width, trim_height)
		
		return {
			"width": trim_width,
			"height": trim_height,
			"rect": rect,
			"min_x": min_x,
			"min_y": min_y,
			"max_x": max_x,
			"max_y": max_y
		}
	
	# Return empty result if image is fully transparent
	return {}

# Trim the image based on non-transparent pixels
static func trim_image(image: Image) -> Image:
	var trim_info = calculate_trim_info(image)
	
	# If no trim needed, return original image
	if trim_info.is_empty():
		return image
	
	# Create trimmed image
	var trimmed_image = Image.create(trim_info.width, trim_info.height, false, image.get_format())
	
	# Blit the non-transparent area
	trimmed_image.blit_rect(image, trim_info.rect, Vector2.ZERO)
	
	return trimmed_image
