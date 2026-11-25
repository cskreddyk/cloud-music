provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "CloudMusic"
      ManagedBy = "Terraform"
      Purpose   = "DevSecOps"
    }
  }
}
