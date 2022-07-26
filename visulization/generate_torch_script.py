import torch
from scipy.special import softmax
import numpy as np

from transformers import AutoTokenizer, AutoModelForSequenceClassification
import urllib.request
import csv

tokenizer = AutoTokenizer.from_pretrained("cardiffnlp/twitter-roberta-base-sentiment")

origin_model = AutoModelForSequenceClassification.from_pretrained("cardiffnlp/twitter-roberta-base-sentiment", return_dict=False)



text = "Good night 😊"
encoded_input = tokenizer(text, return_tensors='pt')


traced_cpu = torch.jit.trace(origin_model, (encoded_input["input_ids"], encoded_input["attention_mask"]))

torch.jit.save(traced_cpu, "trace_model.pt")



model = torch.jit.load("trace_model.pt")


output = model(**encoded_input)
scores = output[0][0].detach().numpy()
scores = softmax(scores)
task='sentiment'

labels=[]
mapping_link = f"https://raw.githubusercontent.com/cardiffnlp/tweeteval/main/datasets/{task}/mapping.txt"
with urllib.request.urlopen(mapping_link) as f:
    html = f.read().decode('utf-8').split("\n")
    csvreader = csv.reader(html, delimiter='\t')
labels = [row[1] for row in csvreader if len(row) > 1]

ranking = np.argsort(scores)
ranking = ranking[::-1]
for i in range(scores.shape[0]):
    l = labels[ranking[i]]
    s = scores[ranking[i]]
    print(f"{i+1}) {l} {np.round(float(s), 4)}")
