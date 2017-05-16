FROM ecornejo/jupyter:testing
COPY requirements.txt /home/jovyan/work
COPY conda-requirements.txt /home/jovyan/work

USER root
RUN apk update && apk upgrade && apk add --no-cache --update g++ make

RUN  pip install -r requirements.txt
RUN  conda install --file conda-requirements.txt
USER jovyan