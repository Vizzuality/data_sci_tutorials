FROM gliderlabs/alpine:latest
MAINTAINER @AlyGM
# Based on this project https://github.com/show0k/alpine-jupyter-docker

USER root

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/$NB_USER

# Configure Miniconda
ENV MINICONDA_VER 4.2.12
ENV MINICONDA Miniconda3-$MINICONDA_VER-Linux-x86_64.sh
ENV MINICONDA_URL https://repo.continuum.io/miniconda/$MINICONDA
ENV MINICONDA_MD5_SUM d0c7c71cc5659e54ab51f2005a8d96f3

RUN apk --update add \
    wget \
    --update tini \
    gdal \
    geos \
    --no-cache bash gawk sed grep bc coreutils \
    git \
    curl \
    ca-certificates \
    bzip2 \
    unzip \
    sudo \
    libstdc++ \
    glib \
    libxext \
    libxrender \
    ttf-dejavu \
    gfortran \
    gcc \
    vim \
    openssl \
    --update-cache \
    --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted \
    --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted \
    && ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.25-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    apk del glibc-i18n && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" \
    && apk --update add --virtual build-dependencies \
        build-base \
        gdal-dev \
        geos-dev \
        --update-cache \
        --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted \
        --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted  \
    && apk del build-dependencies

ENV LANG=C.UTF-8

# Create $NB_USER user with UID=1000 and in the 'users' group
RUN adduser -s /bin/bash -u $NB_UID -D $NB_USER && \
    mkdir -p /opt/conda && \
    chown $NB_USER /opt/conda

USER $NB_USER

# Setup $NB_USER home directory and
# Install conda as $NB_USER

RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.local && \
    cd /tmp && \
    mkdir -p $CONDA_DIR && \
    curl -L $MINICONDA_URL  -o miniconda.sh && \
    echo "$MINICONDA_MD5_SUM  miniconda.sh" | md5sum -c - && \
    /bin/bash miniconda.sh -f -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    $CONDA_DIR/bin/conda install --yes conda==$MINICONDA_VER

# Install Jupyter Notebook and Hub and also
# Install Python 2 packages
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
COPY env/python2environment.yml /home/$NB_USER/env/python2environment.yml
RUN conda install --quiet --yes python=3.5 \
    notebook \
    terminado \
    ipywidgets \
    'nomkl' \
    'numpy=1.11*' \
    'rasterio=0.36.*' \
    'fiona=1.7*' \
    'pandas=0.19*' \
    'beautifulsoup4=4.5.*' \
    'vincent=0.4.*' \
    'cython=0.23*' \
    'ipywidgets=5.2*' \
    'numexpr=2.6*' \
    'matplotlib=1.5*' \
    'scipy=0.18*' \
    'seaborn=0.7*' \
    'gensim=0.13*' \
    'netcdf4=1.2*' \
    'scikit-learn=0.18*' \
    'scikit-image=0.12*' \
    'sympy=1.0*' \
    'patsy=0.4*' \
    'statsmodels=0.6*' \
    'cloudpickle=0.1*' \
    'dill=0.2*' \
    'numba=0.30*' \
    'bokeh=0.11*' \
    'sqlalchemy=1.0*' \
    'hdf5=1.8.17' \
    'h5py=2.6*' \
    'xlrd' \
    && conda clean -yt \
    && conda install -c conda-forge \
        jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator \
        shapely \
    && conda install -c ioos rtree=0.8.2 \
    && conda clean -yt \
    && conda env create -p $CONDA_DIR/envs/python2 -f /home/$NB_USER/env/python2environment.yml\
    && ls \
    && conda clean -yt \
    && conda config --add channels r \
    && conda install --quiet --yes \
    'r-base=3.3.2' \
    'r-irkernel=0.7*' \
    'r-plyr=1.8*' \
    'r-devtools=1.12*' \
    'r-tidyverse=1.0*' \
    'r-shiny=0.14*' \
    'r-rmarkdown=1.2*' \
    'r-forecast=7.3*' \
    'r-rsqlite=1.1*' \
    'r-reshape2=1.4*' \
    'r-nycflights13=0.2*' \
    'r-caret=6.0*' \
    'r-rcurl=1.95*' \
    'r-crayon=1.3*' \
    'r-randomforest=4.6*' \
    && conda clean -yt


USER root
RUN mv /sbin/ldconfig /sbin/ldconfig_old \
    && ln /usr/glibc-compat/sbin/ldconfig /sbin/ldconfig

# Install non core dependencies from conda and pip
COPY requirements/piprequirements.txt /home/$NB_USER/piprequirements.txt
COPY requirements/condap2_requirements.txt /home/$NB_USER/condap2_requirements.txt
COPY requirements/condap3_requirements.txt /home/$NB_USER/condap3_requirements.txt
COPY requirements/condar_requirements.txt /home/$NB_USER/condar_requirements.txt
RUN pip install --upgrade pip && \
    pip install -r /home/$NB_USER/piprequirements.txt \
    && conda install --quiet --yes --file /home/$NB_USER/condap3_requirements.txt \
    && conda clean -yt \
    && conda install --quiet --yes --file /home/$NB_USER/condar_requirements.txt  \
    && conda clean -yt \
    && conda install --quiet --yes --name python2 --file /home/$NB_USER/condap2_requirements.txt \
    && conda clean -yt \
    && rm \
        /home/$NB_USER/piprequirements.txt \
        /home/$NB_USER/condap2_requirements.txt \
        /home/$NB_USER/condap3_requirements.txt \
        /home/$NB_USER/condar_requirements.txt \
        /home/$NB_USER/env/python2environment.yml


EXPOSE 8888

WORKDIR /home/$NB_USER/work

# Configure container startup
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting also
# Install Python 2 kernel spec globally to avoid permission problems when NB_UID
# switching at runtime. and finally
# Switch back to $NB_USER to avoid accidental container runs as root
COPY start-notebook.sh /usr/local/bin/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
COPY custom/custom.css /home/$NB_USER/.jupyter/custom/custom.css
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter && \
    chmod +x /usr/local/bin/start-notebook.sh && \
    $CONDA_DIR/envs/python2/bin/python \
    $CONDA_DIR/envs/python2/bin/ipython \
    kernelspec install-self && \
    chown -R $NB_USER:users /home/$NB_USER/.local
USER $NB_USER
