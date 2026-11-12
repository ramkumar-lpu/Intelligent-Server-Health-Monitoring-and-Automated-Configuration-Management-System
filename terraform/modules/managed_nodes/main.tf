terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_container" "this" {
  for_each = var.nodes

  name     = each.key
  hostname = each.value.hostname
  image    = var.image_id
  restart  = "unless-stopped"
  must_run = true

  memory = each.value.memory_mb
  cpus   = each.value.cpus

  networks_advanced {
    name         = var.network_name
    ipv4_address = each.value.ip_address
    aliases      = [each.key, each.value.hostname]
  }

  labels {
    label = "managed_by"
    value = "terraform"
  }

  labels {
    label = "node_role"
    value = each.value.role
  }

  labels {
    label = "project"
    value = "devops-server-monitoring"
  }
}
