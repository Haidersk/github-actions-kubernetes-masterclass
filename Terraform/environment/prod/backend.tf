terraform {
  backend "s3" {
    bucket = "skillpulse-tfstate-haider-886492071842"
    key    = "prod/terraform.tfstate"
    region = "ap-south-1"
  }
}
