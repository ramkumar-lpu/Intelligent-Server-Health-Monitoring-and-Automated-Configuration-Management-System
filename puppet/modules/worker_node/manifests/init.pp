class worker_node {
  file { '/opt/worker':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/opt/worker/worker.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "#!/bin/sh\nwhile true; do sleep 60; done\n",
    require => File['/opt/worker'],
  }

  service { 'devops-worker':
    ensure    => running,
    provider  => 'base',
    hasstatus => true,
    status    => 'start-stop-daemon --status --pidfile /run/devops-worker.pid',
    start     => 'start-stop-daemon --start --background --make-pidfile --pidfile /run/devops-worker.pid --exec /bin/sh -- /opt/worker/worker.sh',
    stop      => 'start-stop-daemon --stop --quiet --retry=TERM/5/KILL/2 --pidfile /run/devops-worker.pid --remove-pidfile',
    restart   => 'start-stop-daemon --stop --quiet --retry=TERM/5/KILL/2 --pidfile /run/devops-worker.pid --remove-pidfile && start-stop-daemon --start --background --make-pidfile --pidfile /run/devops-worker.pid --exec /bin/sh -- /opt/worker/worker.sh',
    require   => File['/opt/worker/worker.sh'],
  }
}
