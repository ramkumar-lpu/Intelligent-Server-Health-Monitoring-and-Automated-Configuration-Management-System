FROM ubuntu:22.04@sha256:8a2321a92b438238f93b4346fff61bc4259c99fdd4d9b52ee86f153fee0c344f

LABEL maintainer="DevOps Engineering Team"
LABEL description="Puppet Server 8.7.0 on Ubuntu 22.04 LTS (Pinned Digest)"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/puppetlabs/bin:/opt/puppetlabs/server/bin:${PATH}"

# Install core utilities, OpenJDK 17, and official Puppet 8 repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        procps \
        net-tools \
        gosu \
        openjdk-17-jre-headless && \
    curl -fsSL -o /tmp/puppet8-release.deb https://apt.puppet.com/puppet8-release-jammy.deb && \
    dpkg -i /tmp/puppet8-release.deb && \
    rm -f /tmp/puppet8-release.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends puppetserver=8.7.0-1jammy && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Directory preparation with puppet service permissions
RUN mkdir -p /etc/puppetlabs/puppetserver/ca \
             /etc/puppetlabs/code \
             /var/log/puppetlabs/puppetserver \
             /var/run/puppetlabs/puppetserver && \
    chown -R puppet:puppet /etc/puppetlabs /var/log/puppetlabs /var/run/puppetlabs

EXPOSE 8140

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

HEALTHCHECK --interval=15s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -kfsS https://127.0.0.1:8140/status/v1/simple | grep -q "^running$" || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["foreground"]
