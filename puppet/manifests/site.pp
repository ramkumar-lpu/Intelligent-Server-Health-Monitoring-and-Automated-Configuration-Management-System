# Main Puppet Classification Manifest (Phase 2 Baseline)

node 'node-01.infra.internal' {
  include base_system
}

node default {
  include base_system
}
