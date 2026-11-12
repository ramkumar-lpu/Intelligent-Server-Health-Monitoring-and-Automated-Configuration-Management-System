#!/bin/sh
set -e

# Initialize required runtime directories
mkdir -p /run/sshd /run/nagios /var/log/supervisor /etc/puppetlabs/puppet
chown -R nagios:nagios /run/nagios

# Generate SSH host keys at container runtime if absent (avoids baking host keys into the image)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[entrypoint] Generating SSH host keys..."
    ssh-keygen -A
fi

# Ensure devops management user exists for public-key SSH login
if ! id -u devops >/dev/null 2>&1; then
    echo "[entrypoint] Creating unprivileged user 'devops'..."
    useradd -m -s /bin/bash devops
    passwd -l devops >/dev/null 2>&1 # Lock password; SSH keys only
    mkdir -p /home/devops/.ssh
    chown -R devops:devops /home/devops/.ssh
    chmod 700 /home/devops/.ssh
fi

# Execute process supervisor as PID 1
echo "[entrypoint] Launching Supervisor..."
exec "$@"
