# Nagios Core Dockerfile
# Pinned to official maintained jasonrivers/nagios:4.5.2 release
FROM jasonrivers/nagios:4.5.2

LABEL maintainer="DevOps Team" \
      description="Nagios Core 4.5.2 monitoring server for intelligent infrastructure" \
      version="4.5.2"

# Ensure custom configurations are in place before initialization
COPY config/nagios.cfg /opt/nagios/etc/nagios.cfg
COPY config/cgi.cfg /opt/nagios/etc/cgi.cfg
COPY config/objects/commands.cfg /opt/nagios/etc/objects/commands.cfg
COPY config/objects/contacts.cfg /opt/nagios/etc/objects/contacts.cfg
COPY config/objects/timeperiods.cfg /opt/nagios/etc/objects/timeperiods.cfg
COPY config/objects/templates.cfg /opt/nagios/etc/objects/templates.cfg
COPY config/objects/localhost.cfg /opt/nagios/etc/objects/localhost.cfg
COPY config/objects/hosts/*.cfg /opt/nagios/etc/conf.d/

# Fix permissions to match nagios user and group
RUN chown -R nagios:nagios /opt/nagios/etc/

EXPOSE 80

# Inherit /usr/local/bin/start_nagios entrypoint from base
