class base_system (
  String $environment_label = 'production'
) {
  file { '/etc/motd':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('base_system/motd.epp', { 'environment_label' => $environment_label }),
  }

  file { '/etc/devops_managed.json':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('base_system/devops_managed.json.epp', { 'environment_label' => $environment_label }),
  }
}
