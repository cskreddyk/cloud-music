data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "cloudmusic/network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "cloudmusic/ecr/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_ecr_repository" "cloudmusic" {
  for_each = data.terraform_remote_state.ecr.outputs.repository_urls

  name = join("/", slice(split("/", each.value), 1, length(split("/", each.value))))
}
