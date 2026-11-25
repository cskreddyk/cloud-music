output "repository_urls" {
  description = "CloudMusic ECR repository URLs"

  value = {
    for name, repo in aws_ecr_repository.cloudmusic :
    name => repo.repository_url
  }
}

output "repository_count" {
  value = length(aws_ecr_repository.cloudmusic)
}
