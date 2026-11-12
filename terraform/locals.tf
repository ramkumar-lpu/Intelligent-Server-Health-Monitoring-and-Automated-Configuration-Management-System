locals {
  managed_nodes = {
    for name, cfg in var.nodes : name => {
      ip_address = cfg.ip_address
      role       = cfg.role
      memory_mb  = cfg.memory_mb
      cpus       = cfg.cpus
      hostname   = "${name}.${var.domain_suffix}"
    }
  }
}
