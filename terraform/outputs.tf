output "network_name" {
  description = "Attached shared Docker network name."
  value       = data.docker_network.infra_net.name
}

output "managed_node_image" {
  description = "Local Docker image tag and resolved ID used for managed nodes."
  value = {
    tag = var.managed_node_image
    id  = data.docker_image.managed_node.id
  }
}

output "managed_nodes" {
  description = "Inventory of Terraform-provisioned managed nodes (node-02 through node-10)."
  value       = module.managed_nodes.nodes
}
