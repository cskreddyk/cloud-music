resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name
  vpc_security_group_ids = [aws_security_group.jenkins.id]

  associate_public_ip_address = false

  user_data = file("${path.module}/userdata.sh")

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }


  tags = {
    Name = "${var.project_name}-jenkins"
    Role = "CI"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy.ecr
  ]
}
