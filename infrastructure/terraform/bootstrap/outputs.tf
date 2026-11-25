output "state_bucket_name" {
  description = "Terraform remote state bucket"
  value       = aws_s3_bucket.tfstate.id
}

output "state_bucket_region" {
  value = "ap-northeast-1"
}
