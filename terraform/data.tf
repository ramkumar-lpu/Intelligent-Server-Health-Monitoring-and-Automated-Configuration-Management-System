data "docker_network" "infra_net" {
  name = var.network_name
}

data "docker_image" "managed_node" {
  name = var.managed_node_image
}
