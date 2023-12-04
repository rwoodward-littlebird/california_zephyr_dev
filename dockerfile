#----------------------------------------------------------------------------------------------------
# Build this Docker image with:
#           docker build \
#             --build-arg ARCHITECTURE=x86_64 \
#             --build-arg ZEPHYR_SDK_VERSION=0.16.0 \
#             --build-arg ZEPHYR_VERSION=main \
#             --build-arg TOOLCHAIN=all \
#             -t rw_lb_zephyr:main-0.16.0sdk \          
#             .
# NOTE: You can change thew name of the image from 'rw_lb_zephyr' to something more recognizable
#----------------------------------------------------------------------------------------------------
# Original Author   : Johnathan Beri
# Repository        : https://github.com/beriberikix/zephyr-docker
#----------------------------------------------------------------------------------------------------


# Use Debian stable-slim as the base image
FROM debian:stable-slim AS base

# Update package lists and install essential dependencies
RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  cmake \
  device-tree-compiler \
  git \
  ninja-build \
  python3 \
  python3-pip \
  wget \
  xz-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Create a new stage based on the 'base' image
FROM base AS sdk

# Set build arguments and environment variables for Zephyr SDK
ARG ZEPHYR_SDK_VERSION=0.16.3
ARG ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
ARG ZEPHYR_SDK_TOOLCHAIN="-t arm-zephyr-eabi"
ENV ZEPHYR_SDK_TOOLCHAIN=${ZEPHYR_SDK_TOOLCHAIN}

# Download and install Zephyr SDK
RUN \
  export sdk_file_name="zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-$(uname -m)_minimal.tar.xz" \
  && apt-get -y update \
  && apt-get -y install --no-install-recommends \
  wget \
  xz-utils \
  && wget -q "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/${sdk_file_name}" \
  && mkdir -p ${ZEPHYR_SDK_INSTALL_DIR} \
  && tar -xvf ${sdk_file_name} -C ${ZEPHYR_SDK_INSTALL_DIR} --strip-components=1 \
  && ${ZEPHYR_SDK_INSTALL_DIR}/setup.sh ${ZEPHYR_SDK_TOOLCHAIN} \
  && rm ${sdk_file_name} \
  && apt-get remove -y --purge \
  wget \
  xz-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Create a new stage based on the 'sdk' image
FROM sdk AS west

# Install Python dependencies including the 'west' tool
RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  python3 \
  python3-pip \
  && pip3 install --break-system-packages --no-cache-dir wheel west \
  && apt-get remove -y --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Create a new stage based on the 'west' image
FROM west AS python

# Set Zephyr version build argument and environment variable
ARG ZEPHYR_VERSION=v3.4.0
ENV ZEPHYR_VERSION=${ZEPHYR_VERSION}

# Install Python dependencies for Zephyr development
RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  python3 \
  python3-pip \
  && pip3 install --break-system-packages --no-cache-dir wheel \
  && pip3 install --break-system-packages --no-cache-dir \
  -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/${ZEPHYR_VERSION}/scripts/requirements-base.txt \
  && apt-get remove -y --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
