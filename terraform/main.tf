module "managed_nodes" {
  source = "./modules/managed_nodes"

  image_id     = data.docker_image.managed_node.id
  network_name = data.docker_network.infra_net.name
  nodes        = local.managed_nodes
}
