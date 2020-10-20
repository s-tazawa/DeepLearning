# coding: utf-8
import os,os.path
import csv

f = open('corpus.csv', 'w')
csv_writer = csv.writer(f,quotechar="'")
files = os.listdir('./')

datas = []
for filename in files:
    if os.path.isfile(filename):
        continue

    category = filename
    for file in os.listdir('./'+filename):
    	path = './'+filename+'/'+file
    	r = open(path, 'r')
    	line_a = r.readlines()

    	text = ''
        for line in line_a[2:]:
        	text += line.strip()
    	r.close()

    	datas.append([text,category])
        print(text)
csv_writer.writerows(datas)
f.close()