variable "project" {
  description = "Default project for single‑VPC mode"
  type        = string
  default     = null
}

variable "vpc_name" {
  description = "Default VPC name for single‑VPC mode"
  type        = string
  default     = null
}

variable "routing_mode" {
  description = "Default routing mode for single‑VPC mode"
  type        = string
  default     = "GLOBAL"
}

variable "region" {
  description = "Default region for single‑VPC mode"
  type        = string
  default     = null
}

# Multi‑VPC support
variable "vpcs" {
  description = "Map of VPCs (key = vpc_name)"
  type = map(object({
    project      = string
    routing_mode = string
    region       = string
  }))
  default = {}
}

# ✅ FIXED: Proper types for multi‑VPC
variable "subnets" {
  description = "Subnets per VPC: subnets[vpc_name][subnet_name] = config"
  type = map(map(object({
    cidr             = string
    region           = optional(string)
    private_access   = optional(bool, true)
    enable_secondary = optional(bool, true)
    pod_cidr_range   = optional(string)
    svc_cidr_range   = optional(string)
  })))
  default = {}
}

variable "enable_proxy_subnets" {
  type    = bool
  default = false
}

variable "proxy_subnets" {
  description = "Proxy subnets per VPC"
  type = map(map(object({
    cidr    = string
    region  = string
    purpose = string
  })))
  default = {}
}

variable "private_service_ranges" {
  description = "Private service ranges per VPC"
  type = map(object({
    enabled = bool
    psa = list(object({
      name                           = string
      ip_address                     = string
      private_services_prefix_length = number
    }))
  }))
  default = {}
}

variable "firewall_rules" {
  description = "Firewall rules per VPC"
  type = map(object({
    enabled = bool
    rules = list(object({
      name        = string
      direction   = string
      priority    = optional(number, 1000)
      ranges      = list(string)
      target_tags = list(string)
      protocol    = string
      ports       = list(string)
    }))
  }))
  default = {}
}

variable "peerings" {
  description = "VPC network peerings (global)"
  type = object({
    enabled = bool
    connections = list(object({
      name                                = string
      network_self                        = string
      peer_network                        = string
      export_routes                       = optional(bool, true)
      import_routes                       = optional(bool, true)
      update_strategy                     = string
      stack_type                          = string
      import_subnet_routes_with_public_ip = bool
    }))
  })
  default = {
    enabled     = false
    connections = []
  }
}
