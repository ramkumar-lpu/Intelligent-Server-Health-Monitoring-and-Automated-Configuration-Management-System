class nodejs_app {
  package { 'nodejs':
    ensure => installed,
  }

  file { '/opt/nodejs-app':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/opt/nodejs-app/health.js':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('nodejs_app/health.js.epp'),
    require => [Package['nodejs'], File['/opt/nodejs-app']],
  }

  service { 'nodejs-health':
    ensure    => running,
    provider  => 'base',
    hasstatus => true,
    status    => 'start-stop-daemon --status --pidfile /run/nodejs-health.pid',
    start     => 'start-stop-daemon --start --background --make-pidfile --pidfile /run/nodejs-health.pid --exec /usr/bin/node -- /opt/nodejs-app/health.js',
    stop      => 'start-stop-daemon --stop --quiet --retry=TERM/5/KILL/2 --pidfile /run/nodejs-health.pid --remove-pidfile',
    restart   => 'start-stop-daemon --stop --quiet --retry=TERM/5/KILL/2 --pidfile /run/nodejs-health.pid --remove-pidfile && start-stop-daemon --start --background --make-pidfile --pidfile /run/nodejs-health.pid --exec /usr/bin/node -- /opt/nodejs-app/health.js',
    require   => File['/opt/nodejs-app/health.js'],
  }
}
