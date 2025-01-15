# Stage 1: Build FFmpeg with NVIDIA support
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    yasm \
    cmake \
    libtool \
    libc6 \
    libc6-dev \
    unzip \
    wget \
    nasm \
    libnuma1 \
    libnuma-dev \
    git \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Clone and install nv-codec-headers
RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && \
    make install && \
    cd ..

# Clone FFmpeg
RUN git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg

# Build FFmpeg
WORKDIR /ffmpeg
RUN ./configure \
    --enable-nonfree \
    --enable-cuda-nvcc \
    --enable-libnpp \
    --extra-cflags=-I/usr/local/cuda/include \
    --extra-ldflags=-L/usr/local/cuda/lib64 \
    --disable-static \
    --enable-shared && \
    make -j$(nproc) && \
    make install

# Stage 2: Create the final image
FROM python:3.11-slim-bookworm

# Install necessary runtime libraries, git and aria2c
RUN apt-get update && apt-get install -y \
    libgomp1 \
    libass9 \
    libvdpau1 \
    libnuma1 \
    build-essential \
    curl \
    gcc \
    g++ \
    aria2 \
    libgl1 \
    libglib2.0-0 \
    fonts-dejavu-core \
    git \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Copy FFmpeg binaries from the builder stage
COPY --from=builder /usr/local/bin/ffmpeg /usr/local/bin/
COPY --from=builder /usr/local/bin/ffprobe /usr/local/bin/

# Copy necessary shared libraries
COPY --from=builder /usr/local/lib/lib*.so* /usr/local/lib/

# Update the dynamic linker run-time bindings
RUN ldconfig

ENV PIP_ROOT_USER_ACTION=ignore
ENV COMFYUI_DOWNLOAD_STD_MODELS=true
ENV COMFYUI_DOWNLOAD_VIDEO_MODELS=true

# Define build argument for CUDA version with default value
ARG CUDA_VERSION=cu124

# Install torch, torchvision, torchaudio and xformers
RUN pip install --no-cache-dir --break-system-packages \
    torch \
    torchvision \
    torchaudio \
    xformers \
    --index-url https://download.pytorch.org/whl/${CUDA_VERSION}

# Install onnxruntime-gpu
RUN pip uninstall --break-system-packages --yes \
    onnxruntime-gpu \
    && pip install --no-cache-dir --break-system-packages \
    onnxruntime-gpu \
    --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/

# Install dependencies for ComfyUI and ComfyUI-Manager
RUN pip install --no-cache-dir --break-system-packages \
    -r https://raw.githubusercontent.com/comfyanonymous/ComfyUI/master/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/requirements.txt

# Install envsubst
RUN curl -L https://github.com/a8m/envsubst/releases/download/v1.4.2/envsubst-$(uname -s)-$(uname -m) -o /usr/local/bin/envsubst && \
    chmod +x /usr/local/bin/envsubst

# Create a low-privilege user
RUN useradd -m -d /app runner \
    && mkdir -p /scripts /data /config \
    && chown runner:runner /app /scripts /data /config
    
COPY --chown=runner:runner root/. /

# Add runner to sudoers
RUN echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner

USER runner:runner

VOLUME [ "/app", "/config", "/data" ]

WORKDIR /app

EXPOSE 8188

ENV CLI_ARGS=""

CMD ["bash","/scripts/entrypoint.sh"]