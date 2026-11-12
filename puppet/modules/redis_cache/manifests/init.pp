class redis_cache {
  package { 'redis-server':
    ensure => installed,
  }

  service { 'redis-server':
    ensure    => running,
    provider  => 'base',
    hasstatus => true,
    status    => 'pgrep -x redis-server >/dev/null',
    start     => '/etc/init.d/redis-server start',
    stop      => '/etc/init.d/redis-server stop',
    restart   => '/etc/init.d/redis-server restart',
    require   => Package['redis-server'],
  }
}
