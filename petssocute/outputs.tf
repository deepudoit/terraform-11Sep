output "db_passsord" {
  value = module.database.db_config.password
}

output "lb_dns_name" {
  value = module.autoscaling.lb_dns_name
}