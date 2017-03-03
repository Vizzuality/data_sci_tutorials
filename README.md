# Data Science Tutorials

## Notebooks in ./work

* Minifying rasters
* Working with NetCDF

### Docker

This repo contains some in depth notebook tutorials, relating to libraries and methods relevant to Vizzuality's Data Science Group.
The notebooks are all housed in `./work` as the notebooks can all be run with a Docker image called Jupyter_dev, built using Alpine,
Andaconda, Python 3.6, R, and geospatial libraries.

To launch the docker environment, execute:

```bash
sh jupyter.sh develop
```

To use the docker image in interactive mode:
```bash
docker run -it Jupyter_dev /bin/bash
```

To connect to Earth Engine, launch the docker image in interactive mode, and execute `earthengine authenticate`, then follow the terminal instructions.
