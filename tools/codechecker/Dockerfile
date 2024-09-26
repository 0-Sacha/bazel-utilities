FROM ubuntu:23.04

LABEL description="Analyzer environment"

RUN apt-get update && \
    apt-get install -y \
    software-properties-common \
    wget \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    build-essential \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    python3-setuptools \
    make \
    build-essential \
    cppcheck \
    mold

RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc >/dev/null \
    && add-apt-repository -y 'deb http://apt.llvm.org/noble/ llvm-toolchain-noble-18 main' \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        clang-18 \
        clang-tidy-18 \
        lld-18 \
        libc++-18-dev \
        libc++abi-18-dev

RUN curl -LJO "https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64" \
    && chmod +x bazelisk-linux-amd64 \
    && mv bazelisk-linux-amd64 /usr/local/bin/bazel

RUN update-alternatives --install /usr/bin/gcc              gcc          /usr/bin/gcc-14          10 \
    && update-alternatives --install /usr/bin/g++           g++          /usr/bin/g++-14          10 \
    && update-alternatives --install /usr/bin/clang++       clang++      /usr/bin/clang++-18      10 \
    && update-alternatives --install /usr/bin/clang         clang        /usr/bin/clang-18        10 \
    && update-alternatives --install /usr/bin/clang-tidy    clang-tidy   /usr/bin/clang-tidy-18   10 \
    && update-alternatives --install /usr/bin/cc            cc           /usr/bin/gcc-14          10 \
    && update-alternatives --install /usr/bin/c++           c++          /usr/bin/g++-14          10

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir codechecker
