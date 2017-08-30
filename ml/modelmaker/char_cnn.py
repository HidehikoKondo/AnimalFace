# -*- coding:utf-8 -*-

import numpy as np

from keras.callbacks import LearningRateScheduler
from keras.layers import BatchNormalization, Concatenate, Conv2D, Dense, Dropout, Embedding, Flatten, Input, MaxPooling2D, Reshape
from keras.models import load_model, Model
from keras.optimizers import Adam


def create_model(embed_size=128, max_length=300, filter_sizes=(2, 3, 4, 5), filter_num=64):
    inp = Input(shape=(max_length,))
    emb = Embedding(0xffff, embed_size)(inp)
    emb_ex = Reshape((max_length, embed_size, 1))(emb)
    convs = []
    # Conv2Dを複数通りかける
    for filter_size in filter_sizes:
        conv = Conv2D(filter_num, (filter_size, embed_size), activation="relu")(emb_ex)
        pool = MaxPooling2D(pool_size=(max_length - filter_size + 1, 1))(conv)
        convs.append(pool)
    convs_merged = Concatenate()(convs)
    reshape = Flatten()(convs_merged)
    fc1 = Dense(64, activation="relu")(reshape)
    bn1 = BatchNormalization()(fc1)
    do1 = Dropout(0.5)(bn1)
    fc2 = Dense(1, activation='sigmoid')(do1)
    model = Model(inputs=inp, outputs=fc2)
    return model


def train(inputs, targets, batch_size=100, epoch_count=100, max_length=300, model_filepath="model.h5", learning_rate=0.001):

    # 学習率を少しずつ下げるようにする
    start = learning_rate
    stop = learning_rate * 0.01
    learning_rates = np.linspace(start, stop, epoch_count)

    # モデル作成
    model = create_model(max_length=max_length)
    optimizer = Adam(lr=learning_rate)
    model.compile(loss='binary_crossentropy',
                  optimizer=optimizer,
                  metrics=['accuracy'])

    # 学習
    model.fit(inputs, targets,
              epochs=epoch_count,
              batch_size=batch_size,
              verbose=1,
              validation_split=0.1,
              shuffle=True,
              callbacks=[
                  LearningRateScheduler(lambda epoch: learning_rates[epoch]),
              ])

    # モデルの保存
    model.save(model_filepath)


def load_data(max_length=300):
    # [(クラス, 文), (クラス, 文), ....]を返すように実装。文はmax_length長の固定長にすること
    # クラスは0 or 1の2値(モデルを修正すれば増やせる)
    raise NotImplementedError()

if __name__ == "__main__":
    comments = load_data()

    input_values = []
    target_values = []
    for target_value, input_value in comments:
        input_values.append(input_value)
        target_values.append(target_value)
    input_values = np.array(input_values)
    target_values = np.array(target_values)
    train(input_values, target_values, epoch_count=50)
