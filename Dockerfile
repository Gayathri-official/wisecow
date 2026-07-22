FROM ubuntu:22.04

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies:
#  - cowsay, fortune-mod  -> required by wisecow.sh
#  - netcat-openbsd       -> provides `nc` used to serve requests
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cowsay \
        fortune-mod \
        fortunes \
        netcat-openbsd \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# cowsay/fortune binaries live under /usr/games on Debian/Ubuntu
ENV PATH="/usr/games:${PATH}"

WORKDIR /app

COPY wisecow.sh /app/wisecow.sh
RUN chmod +x /app/wisecow.sh

EXPOSE 4499

ENTRYPOINT ["/app/wisecow.sh"]
