class backup_node {
  package { ['rsync', 'cron']:
    ensure => installed,
  }

  file { ['/var/backups/infra', '/var/backups/infra/daily']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  file { '/usr/local/bin/infra-backup-check.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => epp('backup_node/backup-check.sh.epp'),
    require => File['/var/backups/infra/daily'],
  }

  file { '/etc/cron.d/infra-backup':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "0 2 * * * root /usr/local/bin/infra-backup-check.sh >> /var/log/infra-backup.log 2>&1\n",
    require => [Package['cron'], File['/usr/local/bin/infra-backup-check.sh']],
  }

  service { 'cron':
    ensure    => running,
    provider  => 'base',
    hasstatus => true,
    status    => 'pgrep -x cron >/dev/null',
    start     => '/etc/init.d/cron start',
    stop      => '/etc/init.d/cron stop',
    restart   => '/etc/init.d/cron restart',
    require   => [Package['cron'], File['/etc/cron.d/infra-backup']],
  }
}
