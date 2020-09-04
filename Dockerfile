##################
# Build image
##################
FROM ubuntu:18.04 as build

# Install CMAKE required to build OpenDNP3
RUN apt update && apt install wget build-essential libssl-dev git  -y
RUN wget --quiet https://github.com/Kitware/CMake/releases/download/v3.18.2/cmake-3.18.2.tar.gz
RUN tar xvzf cmake-3.18.2.tar.gz
RUN cd cmake-3.18.2
WORKDIR /cmake-3.18.2
RUN ./bootstrap
RUN make
# make install for next stage
RUN make DESTDIR=/tmp_cmake install
# make install for building opendnp3
RUN make install

# Build OpenDNP3 libraries required for pydnp3
WORKDIR /
RUN git clone https://github.com/dnp3/opendnp3.git
WORKDIR /opendnp3
RUN mkdir build
RUN cd build
WORKDIR /opendnp3/build
RUN pwd
RUN cmake ..
RUN make
RUN make DESTDIR=/tmp_dnp3 install

##################
# Deployment image
##################
FROM ubuntu:18.04

# Copy cmake and OpenDNP3 from the build stage
COPY --from=build /tmp_cmake /
COPY --from=build /tmp_dnp3 /

RUN apt update && apt install python3 python3-pip build-essential libssl-dev python-dev python3-dev git nano -y

COPY --from=build /tmp_cmake /
COPY --from=build /tmp_dnp3 /

RUN git clone https://github.com/ChargePoint/pybind11.git
WORKDIR /pybind11
RUN python3 setup.py install 
WORKDIR /
RUN rm -r pybind11

RUN pip3 install pydnp3

RUN mkdir dnp3_dev
COPY ./dnp3_dev/* /dnp3_dev/
