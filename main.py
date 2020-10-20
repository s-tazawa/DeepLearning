# -*- coding: utf-8 -*-
# ! /usr/bin/python
import pandas as pd
import numpy as np
from sklearn.preprocessing import LabelEncoder
from sklearn.externals import joblib
import os.path
import nlp_tasks

from sklearn.neural_network import MLPClassifier  # c

def train():
    classifier = MLPClassifier()
    classifier.train('corpus.csv')

def predict():
    classifier = MLPClassifier()
    classifier.load_model()
    result = classifier.predict(u"{カテゴリ判別したい記事内容}")
    print(result)

class MLPClassifier():
    model = None
    model_name = "mlp"

    def load_model(self):
    	if os.path.exists(self.get_model_path())==False:
        	raise Exception('no model file found!')
    	self.model = joblib.load(self.get_model_path())
    	self.classes =  joblib.load(self.get_model_path('class')).tolist()
    	self.vectorizer = joblib.load(self.get_model_path('vect'))
    	self.le = joblib.load(self.get_model_path('le'))

    def get_model_path(self,type='model'):
    	return 'models/'+self.model_name+"_"+type+'.pkl'

    def get_vector(self,text):
    	return self.vectorizer.transform([text])



    def train(self, csvfile):
    	df = pd.read_csv(csvfile,names=('text','category'))
    	X, vectorizer = nlp_tasks.get_vector_by_text_list(df["text"])

    	# loading labels
        le = LabelEncoder()
    	le.fit(df['category'])
    	Y = le.transform(df['category'])

    	model = MLPClassifier(max_iter=300, hidden_layer_sizes=(100,),verbose=10,)
    	model.fit(X, Y)

    	# save models
        joblib.dump(model	, self.get_model_path())
    	joblib.dump(le.classes_, self.get_model_path("class"))
    	joblib.dump(vectorizer, self.get_model_path("vect"))
    	joblib.dump(le, self.get_model_path("le"))

    	self.model = model
    	self.classes = le.classes_.tolist()
    	self.vectorizer = vectorizer

    def predict(self,query):
    	X = self.vectorizer.transform([query])
    	key = self.model.predict(X)
    	return self.classes[key[0]]

class DataFrame:
	print(os.listdir('./text/'))




if __name__ == '__main__':
    train()
    #predict()