class nginx_web {
  package { 'nginx':
    ensure => installed,
  }

  file { '/var/www/html/index.html':
    ensure  => file,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    content => epp('nginx_web/index.html.epp'),
    require => Package['nginx'],
  }

  service { 'nginx':
    ensure    => running,
    provider  => 'base',
    hasstatus => true,
    status    => 'pgrep -x nginx >/dev/null',
    start     => '/usr/sbin/nginx',
    stop      => '/usr/sbin/nginx -s quit',
    restart   => '/usr/sbin/nginx -s reload',
    require   => [Package['nginx'], File['/var/www/html/index.html']],
  }
}
