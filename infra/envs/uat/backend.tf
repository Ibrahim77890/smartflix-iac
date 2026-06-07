terraform {
  backend "gcs" {
    prefix = "envs/uat"
  }
}
