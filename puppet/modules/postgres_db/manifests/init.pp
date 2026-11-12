class postgres_db {
  package { 'postgresql':
    ensure => installed,
  }

  service { 'postgresql':
    ensure    => running,
    provider  => 'base',
    hasstatus => true,
    status    => '/etc/init.d/postgresql status >/dev/null 2>&1',
    start     => '/etc/init.d/postgresql start',
    stop      => '/etc/init.d/postgresql stop',
    restart   => '/etc/init.d/postgresql restart',
    require   => Package['postgresql'],
  }
}
