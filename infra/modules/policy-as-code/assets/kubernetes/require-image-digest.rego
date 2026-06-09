package streamflix.kubernetes

deny[msg] {
  input.kind == "Pod"
  container := input.spec.containers[_]
  not contains(container.image, "@sha256:")
  msg := sprintf("Container %s must use a digest-pinned image.", [container.name])
}
