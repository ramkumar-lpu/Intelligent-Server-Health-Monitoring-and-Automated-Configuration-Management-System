variable "image_id" {
  description = "Local Docker image ID to run on managed nodes."
  type        = string
}

variable "network_name" {
  description = "Existing Docker network name for container attachment."
  type        = string
}

variable "nodes" {
  description = "Map of managed node specifications keyed by container name."
  type = map(object({
    ip_address = string
    role       = string
    memory_mb  = number
    cpus       = string
    hostname   = string
  }))
}
