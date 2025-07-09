FROM ubuntu:jammy
ARG DEBIAN_FRONTEND=noninteractive

# A word about HTTP_PROXY
# On systems that need to access a proxy to download packages, the build
# should be called with a build-arg that passes in the proxy to use.
#  A symptom that this is needed is that apt-get cannot access packages.
#  pip uses a different mechanism for accessing via a proxy.
# This is not needed if building on a system that does not  use a proxy.
#
# apt can be enabled for a proxy with this syntax:
# RUN DEBIAN_FRONTEND=noninteractive apt-get \
#    --option acquire::http::proxy="${HTTP_PROXY}" \
#    --option acquire::https::proxy=false \
#        -y update
#
# To set the proxy variable from the build environment:
# docker build --build-arg HTTP_PROXY .
#


LABEL vendor="Computational Radiology Laboratory"
LABEL vendor="crl.med.harvard.edu"

# Update the ubuntu.
RUN apt-get -y \
    --option acquire::http::proxy="${HTTP_PROXY}" \
    --option acquire::https::proxy=false \
    update && \
    apt-get -y \
    --option acquire::http::proxy="${HTTP_PROXY}" \
    --option acquire::https::proxy=false \
    upgrade

ENV LANG=en_US.UTF-8 
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_TYPE=en_US.UTF-8

# build-essential and git are needed if a python wheel is no longer supported,
# and must be built from scratch.
RUN DEBIAN_FRONTEND=noninteractive apt-get \
    --option acquire::http::proxy="${HTTP_PROXY}" \
    --option acquire::https::proxy=false \
    install -y \
    build-essential software-properties-common \
    wget curl vim nano zip git \
    python3-pip

# install CRKIT
RUN mkdir /opt/crkit && \
        cd /opt/crkit && \
        wget http://crl.med.harvard.edu/CRKIT/CRKIT-1.6.0-RHEL6.tar.gz && \
        tar -xf CRKIT-1.6.0-RHEL6.tar.gz && \
        rm CRKIT-1.6.0-RHEL6.tar.gz

COPY requirements.txt /tmp/requirements.txt
RUN apt-get install -y python3-pip
RUN pip3 install -r /tmp/requirements.txt
RUN pip3 install SimpleITK

# add env variables
ENV BUNDLE /opt/crkit/crkit-1.6.0
ENV PATH $PATH:$BUNDLE/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$BUNDLE/itk-4.6.1/lib
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$BUNDLE/Frameworks/InsightToolkit:$BUNDLE/Frameworks/vtk-6.1:$BUNDLE/Frameworks/qt-5.3.2/lib:$BUNDLE/lib:$BUNDLE/bin
ENV QT_PLUGIN_PATH $BUNDLE/Frameworks/qt-5.3.2/plugins
ENV DYLD_LIBRARY_PATH ""

# install GGR-recon
RUN mkdir -p /opt/GGR-recon
COPY utils.py /opt/GGR-recon
COPY preprocess.py /opt/GGR-recon
COPY recon.py /opt/GGR-recon
ENV PATH ${PATH}:/opt/GGR-recon
RUN chmod a+rx /opt/GGR-recon/preprocess.py
RUN chmod a+rx /opt/GGR-recon/recon.py

WORKDIR /opt/GGR-recon

# DEFAULT CMD provides a list of programs.
ENV msg="\nRun one of these programs:\n"
CMD echo $msg; find /opt/GGR-recon/ -type f -name "*.py"; echo $msg


# How to build the container:
# export HTTP_PROXY=http://proxy.example.com:3128
# docker build --network=host --build-arg HTTP_PROXY=${HTTP_PROXY} \
#  --no-cache=true --progress=plain \
#  -t crl/ggr-recon:latest -f Dockerfile .
#

