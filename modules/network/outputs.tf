output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_ids" {
  value = { for i, j in google_compute_subnetwork.subnets : i => j.id }
}

output "psc_connection" {
  value = google_service_networking_connection.private_vpc_connection
}

output "vpc_self_link" {
  value = google_compute_network.vpc.self_link
}

output "subnets" {
  value = {
    for name, subnet in google_compute_subnetwork.subnets :
    name => {
      self_link = subnet.self_link
      name      = subnet.name
      region    = subnet.region

      pod_range = try(subnet.secondary_ip_range[0].range_name, null)
      svc_range = try(subnet.secondary_ip_range[1].range_name, null)
    }
  }
}
