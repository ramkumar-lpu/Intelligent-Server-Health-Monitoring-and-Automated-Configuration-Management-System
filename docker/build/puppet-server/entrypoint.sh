#!/usr/bin/env bash
set -e

echo "[entrypoint] Initializing Puppet Server 8.10 environment..."

# 1. Reliable JAVA_ARGS Configuration
# Defaults to 256MB initial and 512MB maximum heap
export JAVA_ARGS="${JAVA_ARGS:--Xms256m -Xmx512m -Djruby.logger.class=default}"

if [ -f /etc/default/puppetserver ]; then
    if grep -q '^JAVA_ARGS=' /etc/default/puppetserver; then
        sed -i "s|^JAVA_ARGS=.*|JAVA_ARGS=\"${JAVA_ARGS}\"|" /etc/default/puppetserver
    else
        echo "JAVA_ARGS=\"${JAVA_ARGS}\"" >> /etc/default/puppetserver
    fi
else
    mkdir -p /etc/default
    echo "JAVA_ARGS=\"${JAVA_ARGS}\"" > /etc/default/puppetserver
fi
echo "[entrypoint] Configured JVM arguments in /etc/default/puppetserver: ${JAVA_ARGS}"

# 2. Safe Volume Ownership (First-run initialization only; avoids recursive chown on every boot)
mkdir -p /etc/puppetlabs/puppetserver/ca \
         /etc/puppetlabs/puppet/ssl \
         /etc/puppetlabs/code \
         /var/run/puppetlabs/puppetserver \
         /var/log/puppetlabs/puppetserver

if [ "$(stat -c '%U' /etc/puppetlabs/puppetserver/ca 2>/dev/null)" != "puppet" ]; then
    echo "[entrypoint] First run detected: Setting initial ownership for CA directory..."
    chown -R puppet:puppet /etc/puppetlabs/puppetserver/ca
else
    echo "[entrypoint] CA directory ownership already verified (puppet)."
fi

if [ "$(stat -c '%U' /etc/puppetlabs/code 2>/dev/null)" != "puppet" ]; then
    chown puppet:puppet /etc/puppetlabs/code 2>/dev/null || true
fi

chown puppet:puppet /var/run/puppetlabs/puppetserver /var/log/puppetlabs/puppetserver

# 3. Persistent CA Inspection
if [ -f /etc/puppetlabs/puppetserver/ca/ca_crt.pem ]; then
    echo "[entrypoint] Existing Certificate Authority found. Preserving CA state."
else
    echo "[entrypoint] No existing CA found. First boot will initialize new CA."
fi

# 4. Process Hand-off as PID 1 via gosu
echo "[entrypoint] Starting Puppet Server process as 'puppet'..."
exec /usr/sbin/gosu puppet /opt/puppetlabs/bin/puppetserver "$@"
