FROM tensorflow/tensorflow:latest-gpu-py3-jupyter

RUN apt-get update -y
RUN apt-get install vim -y
VOLUME /mnt
WORKDIR /mnt
ADD requirements.txt /mnt
RUN pip install --upgrade pip
RUN pip install -r requirements.txt