FROM debian:10-slim AS donwload-samtools
RUN apt-get update && apt-get install -y curl bzip2 && rm -rf /var/lib/apt/lists/*
RUN curl -OL https://github.com/samtools/samtools/releases/download/1.10/samtools-1.10.tar.bz2
RUN curl -OL https://github.com/samtools/bcftools/releases/download/1.10.2/bcftools-1.10.2.tar.bz2
RUN curl -OL https://github.com/samtools/htslib/releases/download/1.10.2/htslib-1.10.2.tar.bz2
RUN tar xjf samtools-1.10.tar.bz2
RUN tar xjf bcftools-1.10.2.tar.bz2
RUN tar xjf htslib-1.10.2.tar.bz2

FROM debian:10-slim AS samtools-build
RUN apt-get update && apt-get install -y libssl-dev libncurses-dev build-essential zlib1g-dev liblzma-dev libbz2-dev curl libcurl4-openssl-dev
COPY --from=donwload-samtools /samtools-1.10 /build
WORKDIR /build
RUN ./configure && make -j4 && make install

FROM debian:10-slim AS bcftools-build
RUN apt-get update && apt-get install -y libssl-dev libncurses-dev build-essential zlib1g-dev liblzma-dev libbz2-dev curl libcurl4-openssl-dev
COPY --from=donwload-samtools /bcftools-1.10.2 /build
WORKDIR /build
RUN ./configure && make -j4 && make install

FROM debian:10-slim AS htslib-build
RUN apt-get update && apt-get install -y libssl-dev libncurses-dev build-essential zlib1g-dev liblzma-dev libbz2-dev curl libcurl4-openssl-dev
COPY --from=donwload-samtools /htslib-1.10.2 /build
WORKDIR /build
RUN ./configure && make -j4 && make install

FROM debian:10-slim AS download-igv
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl -OL https://data.broadinstitute.org/igv/projects/downloads/2.8/IGV_2.8.0.zip
RUN unzip IGV_2.8.0.zip

FROM openjdk:11-jre-slim-buster
RUN apt-get update && \
    apt-get install -y ncurses-base zlib1g liblzma5 libbz2-1.0 curl libcurl4 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY --from=samtools-build /usr/local /usr/local
COPY --from=bcftools-build /usr/local /usr/local
COPY --from=htslib-build /usr/local /usr/local
COPY --from=download-igv /IGV_2.8.0 /opt/igv
ENV PATH=/opt/igv:$PATH
COPY run.sh /
ENTRYPOINT [ "/bin/bash", "/run.sh" ]