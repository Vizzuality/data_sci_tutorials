#!/bin/bash

#  --- Define variables ---

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
