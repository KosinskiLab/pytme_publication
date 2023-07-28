FROM ubuntu:22.04

ARG PYTHON_VERSION=3.11
ARG SITUS_VERSION=3.1

RUN apt-get update --fix-missing && \
    apt-get install -y \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python3-pip \
        wget \
        time

RUN python${PYTHON_VERSION} -mpip install  \
    bs4 \
    ftputil \
    numpy \
    pandas \
    pysolr \
    wget \
    matplotlib \
    mrcfile \
    pyfftw \
    pytest \
    PyWavelets \
    PyYAML \
    requests \
    scikit-image \
    scikit_learn \
    scipy \
    pybind11

RUN mkdir /src

RUN apt-get update && \
    cd /src && \
    wget http://situs.biomachina.org/disseminate/Situs_${SITUS_VERSION}.tar.gz && \
    tar xvf Situs_${SITUS_VERSION}.tar.gz && \
    rm Situs_${SITUS_VERSION}.tar.gz && \
    cd Situs_${SITUS_VERSION}/src && \
    make && \
    make install && \
    make clean && \
    ln -s /src/Situs_${SITUS_VERSION}/bin/* /usr/bin/

COPY edm_simulation /src/edm_simulation
RUN cd /src/edm_simulation && python${PYTHON_VERSION} -mpip install .
RUN cd /src/edm_simulation && pytest -vvv