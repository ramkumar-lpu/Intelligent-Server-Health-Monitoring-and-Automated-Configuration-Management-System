output "nodes" {
  description = "Provisioned container metadata keyed by node name."
  value = {
    for name, c in docker_container.this : name => {
      container_id = c.id
      hostname     = c.hostname
      ip_address   = var.nodes[name].ip_address
      role         = var.nodes[name].role
      memory_mb    = var.nodes[name].memory_mb
      cpus         = var.nodes[name].cpus
    }
  }
}
