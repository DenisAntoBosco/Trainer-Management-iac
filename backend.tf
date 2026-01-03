terraform {
  backend "s3" {
    bucket = "neo-eus1-dev-s3-iac"
    key = "tfstatefile"
    region = "us-east-1"
  }
}
