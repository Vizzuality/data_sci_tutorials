#!/bin/bash

#  --- Define variables ---

# set containers ports
# pt_py='8888'
pt_r='8889'

# set directory
folder="data_sci_tutorials/work"
basedir="/Users/alejandroguizar/vizz/"
projectdir=$basedir$folder

# set containers names
containername='viz-notebook'
# name_py=$containername'-py'
name_r=$containername'-r'

#--- Build R container
docker run -p $pt_r:8787 --name $name_r -v "$projectdir":/home/rstudio/work/ rocker/geospatial

# --- Build Jupyter container
# docker run -p $pt_py:8888 --name $name_py  -v "$projectdir":/home/jovyan/work/ ecornejo/jupyter:testing start-notebook.sh --NotebookApp.token=''

# --- Build project folder structure
# cd "$projectdir"
# mkdir data
# mkdir code
# mkdir notebooks
# mkdir docs
# mkdir plots
# mkdir sandox
# mkdir notes

# add .gitignore and GEE authorization nb
# cp ~/datadb/sources/authorize_notebook_server.ipynb .
# cp ~/datadb/sources/.gitignore .

# ignore data folder
# line1="*"
# line2="!.gitignore"
# linewrite="$line1\n$line2"
# echo -e "$linewrite" > data/.gitignore
