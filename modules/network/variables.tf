variable "project" {
  type        = string
  description = "Name of the VPC"
}

variable "routing_mode" {
  type    = string
  default = "GLOBAL"
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr           = string
    private_access = optional(bool, true)

    # NEW FIELDS
    enable_secondary = optional(bool, false)
    pod_cidr_range   = optional(string)
    svc_cidr_range   = optional(string)
  }))
}


variable "region" {
  type    = string
  default = null
}

variable "nat_logging" {
  type    = bool
  default = false
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "firewall_rules" {
  description = "EOF Combined firewall rule configuration"
  type = object({
    enabled = bool
    rules = optional(list(object({
      name        = string
      direction   = string
      ranges      = list(string)
      target_tags = list(string)
      ports       = list(string)
      protocol    = string
      priority    = optional(number, 1000)
    })), [])
  })
}

variable "peerings" {
  description = "Peering configuration object"
  type = object({
    enabled = bool
    connections = optional(list(object({
      name                                = string
      network_self                        = string
      peer_network                        = string
      stack_type                          = string
      update_strategy                     = string
      import_subnet_routes_with_public_ip = optional(bool, true)
      export_routes                       = optional(bool, true)
      import_routes                       = optional(bool, true)
    })), [])
  })
}

variable "enable_psa" {
  type    = bool
  default = true
}

variable "private_service_ranges" {
  description = "Configuration for Private Service Access ranges"
  type = object({
    enabled = bool
    psa = list(object({
      name                           = string
      ip_address                     = string
      private_services_prefix_length = number
    }))
  })

  default = {
    enabled = false
    psa     = []
  }
}

variable "enable_proxy_subnets" {
  type        = bool
  default     = false
  description = "Enable creation of proxy-only subnets for internal load balancing"
}

variable "proxy_subnets" {
  type = map(object({
    cidr    = string
    region  = string
    purpose = string
  }))
  default     = {}
  description = "Map of proxy-only subnets for regional load balancing"
}
