output "web_ami_id" { value = aws_ami_from_instance.web.id }
output "app_ami_id" { value = aws_ami_from_instance.app.id }
output "ec2_instance_profile_name" { value = aws_iam_instance_profile.ec2_profile.name }