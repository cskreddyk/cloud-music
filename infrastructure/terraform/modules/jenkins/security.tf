resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Private Jenkins server with SSM access"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-jenkins-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "jenkins" {
  security_group_id = aws_security_group.jenkins.id
  description       = "Outbound access through NAT Gateway"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
