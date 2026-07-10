FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY tt5srv /usr/local/bin/tt5srv
RUN chmod +x /usr/local/bin/tt5srv
WORKDIR /data
ENTRYPOINT ["/usr/local/bin/tt5srv"]
