variable "docker_host" {
  description = "Docker daemon socket URI."
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "network_name" {
  description = "Existing Compose-managed Docker network to attach managed nodes to."
  type        = string
  default     = "devops-infra-net"
}

variable "managed_node_image" {
  description = "Pre-built local Docker image tag for managed nodes."
  type        = string
  default     = "custom-ubuntu24-managed-node:monitoring-v2.1"
}

variable "domain_suffix" {
  description = "Internal DNS domain suffix used for container hostnames and Puppet certnames."
  type        = string
  default     = "infra.internal"
}

variable "nodes" {
  description = "Map of Terraform-managed nodes (node-02 through node-10) keyed by stable container name."
  type = map(object({
    ip_address = string
    role       = string
    memory_mb  = number
    cpus       = string
  }))

  default = {
    "node-02" = {
      ip_address = "10.240.0.102"
      role       = "nginx-web"
      memory_mb  = 256
      cpus       = "0.5"
    }
    "node-03" = {
      ip_address = "10.240.0.103"
      role       = "postgresql-db"
      memory_mb  = 512
      cpus       = "1.0"
    }
    "node-04" = {
      ip_address = "10.240.0.104"
      role       = "postgresql-db"
      memory_mb  = 512
      cpus       = "1.0"
    }
    "node-05" = {
      ip_address = "10.240.0.105"
      role       = "nodejs-app"
      memory_mb  = 384
      cpus       = "0.75"
    }
    "node-06" = {
      ip_address = "10.240.0.106"
      role       = "nodejs-app"
      memory_mb  = 384
      cpus       = "0.75"
    }
    "node-07" = {
      ip_address = "10.240.0.107"
      role       = "redis-cache"
      memory_mb  = 256
      cpus       = "0.5"
    }
    "node-08" = {
      ip_address = "10.240.0.108"
      role       = "redis-cache"
      memory_mb  = 256
      cpus       = "0.5"
    }
    "node-09" = {
      ip_address = "10.240.0.109"
      role       = "background-worker"
      memory_mb  = 256
      cpus       = "0.5"
    }
    "node-10" = {
      ip_address = "10.240.0.110"
      role       = "backup-node"
      memory_mb  = 256
      cpus       = "0.5"
    }
  }

  validation {
    condition     = length(var.nodes) == 9 && !contains(keys(var.nodes), "node-01")
    error_message = "Terraform must manage exactly 9 nodes (node-02 through node-10); node-01 remains Compose-managed."
  }

  validation {
    condition = alltrue([
      for k, v in var.nodes : can(regex("^10\\.240\\.0\\.(10[2-9]|110)$", v.ip_address))
    ])
    error_message = "Node IP addresses must stay within the reserved 10.240.0.102-10.240.0.110 range."
  }
}
