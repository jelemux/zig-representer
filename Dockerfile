FROM registry.opensuse.org/opensuse/tumbleweed:latest as builder

ARG ZIG_VERSION=0.10.1

RUN zypper refresh && \
    zypper install -y -f git zig=$ZIG_VERSION

WORKDIR /representer
COPY . .

RUN git submodule update --init && \
    zig build -Drelease-safe=true

FROM registry.opensuse.org/opensuse/tumbleweed:latest

WORKDIR /opt/representer

COPY --from=builder /representer/zig-out/bin/zig-representer ./bin/
COPY scripts/* ./bin/

ENTRYPOINT ["/opt/representer/bin/run.sh"]