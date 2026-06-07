terraform {
  backend "gcs" {
    prefix = "envs/stg"
  }
}
