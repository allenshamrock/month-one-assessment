output "ssh_private_key_path" {
  description = "Path to the SSH private key for accessing instances"
  value       = local_file.private_key_file.filename
}

output "ssh__bastion_command" {
  description = "SSH command to access the bastion host"
  value       = "ssh -i ${local_file.private_key_file.filename} ec2-user@${aws_instance.bastion_host.public_ip}"
}

output "ssh_to_server_1_through_bastion" {
  description = "SSH command to access web server 1 through the bastion host"
  value       = "ssh -i ${local_file.private_key_file.filename} -J ec2-user@${aws_eip.bastion_eip.public_ip} ec2-user@${aws_instance.web_server_1.private_ip}"
}

output "ssh_to_server_2_through_bastion" {
  description = "SSH command to access web server 2 through the bastion host"
  value       = "ssh -i ${local_file.private_key_file.filename} -J ec2-user@${aws_eip.bastion_eip.public_ip} ec2-user@${aws_instance.web_server_2.private_ip}"
}

output "ssh_to_db_server_through_bastion" {
  description = "SSH command to access the database server through the bastion host"
  value       = "ssh -i ${local_file.private_key_file.filename} -J ec2-user@${aws_eip.bastion_eip.public_ip} ec2-user@${aws_instance.db_server.private_ip}"
}
