output "freeipa_server_ips" {
  description = "The ip address(es) of any freeipa replica servers"
  value       = ["${aws_instance.freeipa_master.private_ip}", "${formatlist("%v", "${aws_instance.freeipa_replica.*.private_ip}")}"]
}

output "keycloak_server_ip" {
  description = "The ip address of the keycloak host"
  value       = "${aws_instance.keycloak_server.*.private_ip}"
}
