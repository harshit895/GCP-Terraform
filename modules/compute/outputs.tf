output "instance_self_links" {
  value = { for k, inst in google_compute_instance.vm : k => inst.self_link }
}

output "instance_private_ips" {
  value = { for k, inst in google_compute_instance.vm : k => inst.network_interface[0].network_ip }
}
