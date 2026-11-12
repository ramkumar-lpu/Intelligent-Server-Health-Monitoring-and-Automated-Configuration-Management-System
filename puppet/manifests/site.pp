# Main Puppet Classification Manifest (Phase 4 Role-Based Classification)

Exec['apt_update'] -> Package <| |>

node 'node-01.infra.internal', 'node-02.infra.internal' {
  include base_system
  include nginx_web
}

node 'node-03.infra.internal', 'node-04.infra.internal' {
  include base_system
  include postgres_db
}

node 'node-05.infra.internal', 'node-06.infra.internal' {
  include base_system
  include nodejs_app
}

node 'node-07.infra.internal', 'node-08.infra.internal' {
  include base_system
  include redis_cache
}

node 'node-09.infra.internal' {
  include base_system
  include worker_node
}

node 'node-10.infra.internal' {
  include base_system
  include backup_node
}

node default {
  include base_system
}
