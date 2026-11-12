# ==============================================================================
# Stage 1: Artifact Fetcher (Multi-stage build)
# Downloads official repository packages to keep runtime image free of build tools
# ==============================================================================
FROM ubuntu:24.04 AS fetcher

ARG PUPPET_RELEASE_URL=https://apt.puppet.com/puppet8-release-noble.deb

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    curl -fsSL -o /tmp/puppet8-release-noble.deb "${PUPPET_RELEASE_URL}" && \
    test -s /tmp/puppet8-release-noble.deb

# ==============================================================================
# Stage 2: Minimal Runtime Environment
# ==============================================================================
FROM ubuntu:24.04

LABEL maintainer="DevOps Engineering Team"
LABEL description="Unified Managed Node Base Image (Ubuntu 24.04, Puppet Agent 8, NRPE, SSH, Supervisor)"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/puppetlabs/bin:${PATH}"

# Install core runtime packages, configure official Puppet 8 repository, and install puppet-agent
COPY --from=fetcher /tmp/puppet8-release-noble.deb /tmp/puppet8-release-noble.deb

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        procps \
        iproute2 \
        openssh-server \
        nagios-nrpe-server \
        monitoring-plugins-basic \
        supervisor && \
    dpkg -i /tmp/puppet8-release-noble.deb && \
    rm -f /tmp/puppet8-release-noble.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends puppet-agent && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Prepare directories
RUN mkdir -p /run/sshd /run/nagios /var/log/supervisor /etc/puppetlabs/puppet /usr/lib/nagios/plugins

# Copy system configurations
COPY configs/supervisord.conf /etc/supervisor/supervisord.conf
COPY configs/nrpe.cfg /etc/nagios/nrpe.cfg
COPY configs/sshd_config /etc/ssh/sshd_config
COPY configs/puppet.conf /etc/puppetlabs/puppet/puppet.conf
COPY scripts/check_mem /usr/lib/nagios/plugins/check_mem
COPY scripts/check_mem_cgroup /usr/lib/nagios/plugins/check_mem_cgroup
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Apply permissions
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/lib/nagios/plugins/check_mem && \
    chmod 0755 /usr/lib/nagios/plugins/check_mem_cgroup && \
    chown -R nagios:nagios /etc/nagios/nrpe.cfg

# Internal container ports (documentation only; ports remain unexposed on the host)
EXPOSE 22 5666

# Health check to verify process supervisor, SSH, and NRPE status
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD supervisorctl status nrpe | grep -q RUNNING && \
        supervisorctl status sshd | grep -q RUNNING || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
