ARG CF_SRC_OS_IMAGE

FROM ${CF_SRC_OS_IMAGE}

#
# Based on https://github.com/josht/docker-micropython-esp/blob/master/esp32/Dockerfile
#

ENV DEBIAN_FRONTEND=noninteractive

RUN \
	apt-get update \
	&& apt-get upgrade -y \
	&& apt-get dist-upgrade -y \
	&& apt-get install -y --no-install-recommends \
			git \
			build-essential \
			libncurses-dev flex bison gperf \
			python python-pip python-setuptools python-serial \
			python-cryptography python-future python-pyparsing python-pyelftools \
			python3 python3-pip python3-setuptools python3-serial \
			python3-cryptography python3-future python3-pyparsing python3-pyelftools \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /esp esp

USER esp
ENV HOME=/esp

WORKDIR /esp

#
ARG CF_XTENSA_VER
ENV CF_XTENSA_VER=${CF_XTENSA_VER}

ARG CF_ESPIDF_GIT_HASH
ENV CF_ESPIDF_GIT_HASH=${CF_ESPIDF_GIT_HASH}

ARG CF_MPY_VER
ENV CF_MPY_VER=${CF_MPY_VER}

## Install Xtensa ESP32 Toolchain (cross-compiler)

#RUN \
#	curl -O https://dl.espressif.com/dl/${CF_XTENSA_VER}.tar.gz \
#	&& tar -xzf ${CF_XTENSA_VER}.tar.gz \
#	&& rm ${CF_XTENSA_VER}.tar.gz

ADD cache/xtensa_esp32_toolchain/${CF_XTENSA_VER}.tgz /esp/

## Checkout Espressif IDF (IoT development framework, aka SDK)
RUN \
	cd /esp \
	&& git clone --recursive https://github.com/espressif/esp-idf.git \
	&& cd esp-idf \
	&& git checkout ${CF_ESPIDF_GIT_HASH} \
	&& git submodule update --init --recursive

## Checkout MicroPython
RUN \
	cd /esp \
	&& git clone --recursive https://github.com/micropython/micropython \
	&& cd micropython \
	&& git checkout ${CF_MPY_VER}

## Set environmental variables before building, but after code is checked out
ENV ESPIDF=/esp/esp-idf
ENV PATH=/esp/xtensa-esp32-elf/bin:$PATH

ARG CF_MPY_SDKCONFIG=sdkconfig
ENV CF_MPY_SDKCONFIG=${CF_MPY_SDKCONFIG}

## Set environmental variables needed if flashing from images (only possible when the host system is linux)
#ENV PORT = /dev/ttyUSB0
#ENV FLASH_MODE = qio
#ENV FLASH_SIZE = 4MB
#ENV CROSS_COMPILE = xtensa-esp32-elf-

## Build MicroPython cross-compiler
RUN \
	cd /esp/micropython \
	&& make -C mpy-cross

## Make sure we have the Berkeley DB external dependency
RUN \
	cd /esp/micropython \
	&& git submodule init lib/berkeley-db-1.xx \
	&& git submodule update

## Backup original modules
RUN \
	cd /esp/micropython/ports/esp32 \
	&& tar czf /esp/modules-org.tgz modules

##
ENV DEBIAN_FRONTEND=dialog

WORKDIR /esp/micropython/ports/esp32

VOLUME [ \
		"/esp/micropython/ports/esp32/build", \
		#"/esp/micropython/ports/esp32/modules", \
		"/esp/micropython/ports/esp32/scripts" \
	]

## Build base clean firmware image by default
CMD ["make", "SDKCONFIG=boards/${CF_MPY_SDKCONFIG}"]
