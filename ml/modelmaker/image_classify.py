# -*- coding:utf-8 -*-


from keras.layers import Activation, Conv2D, Dense, Flatten, MaxPooling2D
from keras.models import Sequential
from keras.preprocessing.image import ImageDataGenerator

model = Sequential()
model.add(Conv2D(64, (3, 3), activation="relu", input_shape=(32, 32, 3)))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Conv2D(128, (3, 3), activation="relu"))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Flatten())
model.add(Dense(128, activation="relu"))
model.add(Dense(12, activation="softmax"))
model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

# データのディレクトリ構造はImageDataGeneratorのドキュメントを読んでください。
train_generator = ImageDataGenerator( rescale=1./255).flow_from_directory( 'data/train', target_size=(32, 32))
test_generator = ImageDataGenerator( rescale=1./255).flow_from_directory( 'data/test', target_size=(32, 32))

model.fit_generator(train_generator, steps_per_epoch=2000, epochs=50, validation_data=test_generator, validation_steps=800)

model.save("model.h5")
