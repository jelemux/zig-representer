FROM registry.opensuse.org/opensuse/tumbleweed:latest as builder

ARG ZIG_VERSION=0.10.1

RUN zypper refresh && \
    zypper install -y -f git zig=$ZIG_VERSION

WORKDIR /build
COPY . .

RUN git submodule update --init && \
    zig build -Drelease-safe=true -p out && \
    cp scripts/* out/bin/ && \
    chmod +x out/bin/run.sh

FROM registry.opensuse.org/opensuse/tumbleweed:latest

WORKDIR /opt/representer

COPY --from=builder /build/out/bin/* bin/

ENTRYPOINT ["/opt/representer/bin/run.sh"]