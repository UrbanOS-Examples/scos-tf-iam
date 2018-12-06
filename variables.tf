locals {
    iam_instance_type = "t3.medium"
    iam_instance_ami  = "ami-055ddd16f0e2c2e5d"
    tcp_ports         = "53,80,88,389,443,464,636,749,7389,9443,9444,9445"
    udp_ports         = "53,88,123,464,749"
}

variable "freeipa_replica_count" {
  description = "The number of FreeIPA replica servers to support the master"
  default     = 1
}

variable "freeipa_version" {
  description = "The pinned version of the freeipa server"
  default     = "4.7.0-3.fc28"
}

variable "vpc_id" {
  description = "The output id of the vpc to host the stack"
}

variable "vpc_cidr" {
  description = "The cidr block of the parent VPC."
}

variable "subnet_ids" {
  type        = "list"
  description = "The output id of the subnet to host the stack"
}

variable "ssh_key" {
  description = "The ssh key to inject into the deployed ec2 instances"
}

variable "management_cidr" {
  description = "The cidr of the hub management vpc to allow access to the environment"
}

variable "realm_cidr" {
  description = "The cidr of the network segment that will be managed by the iam stack"
}

variable "iam_hostname_prefix" {
  description = "The name prefix of the iam server"
  default     = "iam"
}

variable "zone_id" {
  description = "The output id of the primary dns zone."
}

variable "zone_name" {
  description = "The name of the primary dns zone."
}

variable "realm_name" {
  description = "The kerberos realm of the KDCs"
}

variable "deploy_keycloak" {
  description = "Enable or disable the keycloak OAuth server"
  default     = false
}

variable "keycloak_version" {
  description = "The version of Keycloak to download and install"
  default     = "4.5.0"
}

variable "alb_certificate" {
  description = "The certificate to attach to the keycloak load balancer"
  default     = ""
}

variable "recovery_window_in_days" {
  description = "How long to allow secrets to be recovered if they are deleted"
}

variable "extra_users" {
  type        = "list"
  description = "List of maps of extra users to add to freeipa"
  default     = []
}

variable "extra_users_count" {
  description = "The number of extra users to be added"
  default     = 0
}