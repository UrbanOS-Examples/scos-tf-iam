output "freeipa_server_ips" {
  description = "The ip address(es) of any freeipa replica servers"
  value       = [aws_instance.freeipa_master.private_ip, formatlist("%v", aws_instance.freeipa_replica.*.private_ip)]
}

output "keycloak_server_ip" {
  description = "The ip address of the keycloak host"
  value       = aws_instance.keycloak_server.*.private_ip
}

output "freeipa_admin_password_secret_id" {
  description = "The SecretsManager ID for the FreeIPA admin password"
  value       = aws_secretsmanager_secret_version.freeipa_admin_password.arn
}

output "reverse_dns_zone_id" {
  description = "The zone id of the reverse dns zone for the IAM stack"
  value       = aws_route53_zone.public_hosted_reverse_zone.zone_id
}

output "freeipa_master_instance_id" {
  description = "The instance id the iam-master ec2 instance"
  value       = aws_instance.freeipa_master.id
}

output "freeipa_replica_instance_ids" {
  description = "The instance id the iam-master ec2 instance"
  value       = [aws_instance.freeipa_replica.*.id]
}

