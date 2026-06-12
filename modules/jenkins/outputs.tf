output "public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "security_group_id" {
  value = aws_security_group.jenkins_sg.id
}

output "jenkins_role_arn" {

  value = aws_iam_role.jenkins_role.arn
}

output "jenkins_instance_role_name" {

  value = aws_iam_role.jenkins_role.name
}