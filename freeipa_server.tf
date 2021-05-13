resource "aws_instance" "freeipa_master" {
  instance_type          = local.iam_instance_type
  ami                    = local.iam_instance_ami
  vpc_security_group_ids = [aws_security_group.freeipa_server_sg.id]
  subnet_id              = element(var.subnet_ids, "0")
  key_name               = var.ssh_key

  tags = {
    Role = "iam-server"
    Name = "${var.iam_hostname_prefix}-master"
  }

  provisioner "file" {
    source      = "${path.module}/files/freeipa/setup_master.sh"
    destination = "/tmp/setup_master.sh"

    connection {
      type = "ssh"
      host = self.private_ip
      user = "fedora"
    }
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
sudo bash /tmp/setup_master.sh \
  --hostname ${var.iam_hostname_prefix}-master \
  --hosted-zone ${var.zone_name} \
  --realm-name ${var.realm_name} \
  --admin-password ${random_string.freeipa_admin_password.result} \
  --freeipa-version ${var.freeipa_version}
EOF
      ,
    ]

    connection {
      type = "ssh"
      host = self.private_ip
      user = "fedora"
    }
  }
  root_block_device {
    volume_size = 6
    encrypted   = var.encrypt_volumes
  }
}

resource "random_string" "freeipa_admin_password" {
  length  = 40
  special = false
}

resource "aws_secretsmanager_secret" "freeipa_admin_password" {
  name                    = "${terraform.workspace}-freeipa-admin-password"
  recovery_window_in_days = var.recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "freeipa_admin_password" {
  secret_id     = aws_secretsmanager_secret.freeipa_admin_password.id
  secret_string = random_string.freeipa_admin_password.result
}

