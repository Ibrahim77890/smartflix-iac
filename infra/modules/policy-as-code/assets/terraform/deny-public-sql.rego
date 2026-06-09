package streamflix.terraform

deny[msg] {
  input.resource.type == "google_sql_database_instance"
  input.resource.change.after.settings.ip_configuration.ipv4_enabled == true
  msg := "Cloud SQL public IPv4 must remain disabled."
}
