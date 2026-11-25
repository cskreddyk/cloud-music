output "jenkins_instance_id" {
  value = module.jenkins.instance_id
}

output "jenkins_private_ip" {
  value = module.jenkins.private_ip
}

output "jenkins_security_group_id" {
  value = module.jenkins.security_group_id
}

output "jenkins_iam_role_arn" {
  value = module.jenkins.iam_role_arn
}
