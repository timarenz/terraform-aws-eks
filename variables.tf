variable "environment_name" {
  type = string
}

variable "owner_name" {
  type = string
}

variable "ttl" {
  type    = number
  default = 48
}

variable "name" {
  type = string
}


variable "kubernetes_version" {
  type    = string
  default = null
}


variable "private_subnet_ids" {
  type = list(string)
}

variable "public_access_cidr_blocks" {
  description = "Public IP addresses that allowed to access the Kubernetes API endpoint via the internet. Make sure node-groups are allowed to access this as well if restricted."
  type        = list(string)

}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "worker_count" {
  type    = number
  default = 2
}
