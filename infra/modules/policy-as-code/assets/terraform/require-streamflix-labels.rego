package streamflix.terraform

required_labels := {"env", "owner", "cost_center", "managed_by", "project"}

deny[msg] {
  labels := input.resource.change.after.labels
  some required
  required := required_labels[_]
  not labels[required]
  msg := sprintf("Missing required label %s.", [required])
}
