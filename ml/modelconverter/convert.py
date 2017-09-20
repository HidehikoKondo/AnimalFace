import coremltools

print("\n\n\nconvert!!!\n\n\n")

path = 'model.h5'
coreml_model = coremltools.converters.keras.convert(
	path, 
	image_input_names='image',
	is_bgr = False, 
	image_scale = 1.0, 
	predicted_feature_name = "label", 
	input_names='image',
	class_labels = ['coala','inu','kaba','kitsune','kuma','neko','panda','penguin','risu','uma','usagi','ushi']
)

coreml_model.save('model.mlmodel')



# virtualenv setting
# virtualenv /Users/hidehiko/machinelearning
# source /Users/hidehiko/machinelearning/bin/activate
