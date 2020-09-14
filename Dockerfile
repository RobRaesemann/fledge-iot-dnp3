##################
# Build image
##################
FROM ubuntu:18.04 as build

# Install CMAKE required to build OpenDNP3
RUN apt update && apt upgrade -y  && apt install wget build-essential libssl-dev git -y
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

# Avoid interactive questions when installing Kerberos
ENV DEBIAN_FRONTEND=noninteractive

# Copy cmake and OpenDNP3 from the build stage
COPY --from=build /tmp_cmake /
COPY --from=build /tmp_dnp3 /

RUN apt update && apt upgrade -y && apt install wget rsyslog python3 python3-pip build-essential libssl-dev python-dev python3-dev git nano sed iputils-ping inetutils-telnet -y && \
    wget --no-check-certificate https://fledge-iot.s3.amazonaws.com/1.8.1/ubuntu1804/x86_64/fledge-1.8.1_x86_64_ubuntu1804.tgz && \
    tar -xzvf fledge-1.8.1_x86_64_ubuntu1804.tgz && \
    # Install any dependenies for the .deb file
    apt -y install `dpkg -I ./fledge/1.8.1/ubuntu1804/x86_64/fledge-1.8.1-x86_64.deb | awk '/Depends:/{print$2}' | sed 's/,/ /g'` && \
    dpkg-deb -R ./fledge/1.8.1/ubuntu1804/x86_64/fledge-1.8.1-x86_64.deb fledge-1.8.1-x86_64 && \
    cp -r fledge-1.8.1-x86_64/usr /. && \ 
    mv /usr/local/fledge/data.new /usr/local/fledge/data && \
    # Install plugins
    # Comment out any packages that you don't need to make the image smaller
    mkdir /package_temp && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-rule-simple-expression-1.8.1-x86_64.deb /package_temp/fledge-rule-simple-expression-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-service-notification-1.8.1-x86_64.deb /package_temp/fledge-service-notification-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-notify-python35-1.8.1-x86_64.deb /package_temp/fledge-notify-python35-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-notify-email-1.8.1-x86_64.deb /package_temp/fledge-notify-email-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-rule-outofbound-1.8.1-x86_64.deb /package_temp/fledge-rule-outofbound-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-rule-average-1.8.1-x86_64.deb /package_temp/fledge-rule-average-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-filter-python35-1.8.1-x86_64.deb /package_temp/fledge-filter-python35-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-filter-expression-1.8.1-x86_64.deb /package_temp/fledge-filter-expression-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-filter-delta-1.8.1-x86_64.deb /package_temp/fledge-filter-delta-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-benchmark-1.8.1-x86_64.deb /package_temp/fledge-south-benchmark-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-dnp3-1.8.1-x86_64.deb /package_temp/fledge-south-dnp3-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-expression-1.8.1-x86_64.deb /package_temp/fledge-south-expression-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-modbustcp-1.8.1-x86_64.deb /package_temp/fledge-south-modbustcp-1.8.1-x86_64/  && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-mqtt-sparkplug-1.8.1-x86_64.deb /package_temp/fledge-south-mqtt-sparkplug-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-opcua-1.8.1-x86_64.deb /package_temp/fledge-south-opcua-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-random-1.8.1-x86_64.deb /package_temp/fledge-south-random-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-randomwalk-1.8.1-x86_64.deb /package_temp/fledge-south-randomwalk-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-sinusoid-1.8.1-x86_64.deb /package_temp/fledge-south-sinusoid-1.8.1-x86_64/  && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-south-systeminfo-1.8.1-x86_64.deb /package_temp/fledge-south-systeminfo-1.8.1-x86_64/  && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-north-kafka-1.8.1-x86_64.deb /package_temp/fledge-north-kafka-1.8.1-x86_64/  && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-north-http-north-1.8.1-x86_64.deb /package_temp/fledge-north-http-north-1.8.1-x86_64/ && \
    dpkg-deb -R /fledge/1.8.1/ubuntu1804/x86_64/fledge-north-httpc-1.8.1-x86_64.deb /package_temp/fledge-north-httpc-1.8.1-x86_64/ && \
    # Copy plugins into place
    cp -r /package_temp/fledge-rule-simple-expression-1.8.1-x86_64/usr /. && \
    cp -r /package_temp/fledge-service-notification-1.8.1-x86_64/usr /. && \
    cp -r /package_temp/fledge-notify-python35-1.8.1-x86_64/usr /. && \
    cp -r /package_temp/fledge-notify-email-1.8.1-x86_64/usr /. && \
    cp -r /package_temp/fledge-rule-outofbound-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-rule-average-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-filter-python35-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-filter-expression-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-filter-delta-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-benchmark-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-dnp3-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-expression-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-north-http-north-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-north-httpc-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-north-kafka-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-modbustcp-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-mqtt-sparkplug-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-opcua-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-random-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-randomwalk-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-sinusoid-1.8.1-x86_64/usr /. && \ 
    cp -r /package_temp/fledge-south-systeminfo-1.8.1-x86_64/usr /.  && \ 
    rm ./*.tgz && \ 
    rm -r ./package_temp && \ 
    rm -r ./fledge && \ 
    # Install the patched version of pybindll that allows pydnp3 install
    git clone https://github.com/ChargePoint/pybind11.git && \
    cd /pybind11 && \
    python3 setup.py install && \ 
    cd / && \
    rm -r /pybind11 && \
    # General cleanup
    apt clean && \
    rm -rf /var/lib/apt/lists/* /fledge* /usr/include/boost

# Install Python plugins
COPY ./python /usr/local/fledge/python/

WORKDIR /usr/local/fledge
COPY fledge.sh fledge.sh
RUN  ./scripts/certificates fledge 365 && \
    chown -R root:root /usr/local/fledge && \
    chown -R ${SUDO_USER}:${SUDO_USER} /usr/local/fledge/data && \
    # install required python packages
    pip3 install -r /usr/local/fledge/python/requirements.txt && \
    pip3 install -r /usr/local/fledge/python/requirements-b100dnp3.txt && \
    pip3 install -r /usr/local/fledge/python/requirements-kafka.txt && \
    pip3 install -r /usr/local/fledge/python/requirements-modbustcp.txt && \
    pip3 install -r /usr/local/fledge/python/requirements-mqtt_sparkplug.txt
    
#RUN echo '192.168.69.167 seeeduino1' >> /etc/hosts

ENV FLEDGE_ROOT=/usr/local/fledge

VOLUME /usr/local/fledge/data

# Fledge API port for http and https, kerberos
EXPOSE 8081 1995 502 23

# start rsyslog, FLEDGE, and tail syslog
CMD ["bash","/usr/local/fledge/fledge.sh"]

LABEL maintainer="rob@raesemann.com" \
      author="Rob Raesemann" \
      target="Docker" \
      version="1.8.1" \
      description="Fledge IOT Framework with pydnp3 running in Docker - Installed from .deb packages"