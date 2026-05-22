terraform {
  backend "s3" {
    bucket = "skillpulse-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
