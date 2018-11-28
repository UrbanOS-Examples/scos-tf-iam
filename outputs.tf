output "freeipa_server_ips" {
  description = "The ip address(es) of any freeipa replica servers"
  value       = ["${aws_instance.freeipa_master.private_ip}", "${formatlist("%v", "${aws_instance.freeipa_replica.*.private_ip}")}"]
}

output "keycloak_server_ip" {
  description = "The ip address of the keycloak host"
  value       = "${aws_instance.keycloak_server.*.private_ip}"
}

output "freeipa_admin_password_secret_id" {
  description = "The SecretsManager ID for the FreeIPA admin password"
  value       = "${aws_secretsmanager_secret_version.freeipa_admin_password.arn}"
}

output "bind_user_password_secret_id" {
  description = "The SecretsManager ID for the bind user password"
  value       = "${aws_secretsmanager_secret_version.bind_user_password.arn}"
}

output "bind_user_password" {
  description = "binduser password"
  value       = "${random_string.bind_user_password.result}"
}

output "reverse_dns_zone_id" {
  description = "The zone id of the reverse dns zone for the IAM stack"
  value       = "${aws_route53_zone.public_hosted_reverse_zone.zone_id}"
}
