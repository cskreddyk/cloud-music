module "jenkins" {
  source = "../modules/jenkins"

  project_name     = var.project_name
  ami_id           = var.ami_id
  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size

  vpc_id    = data.terraform_remote_state.network.outputs.vpc_id
  subnet_id = data.terraform_remote_state.network.outputs.private_subnet_ids[0]

  ecr_repository_arns = [
    for repo in data.aws_ecr_repository.cloudmusic : repo.arn
  ]
}
