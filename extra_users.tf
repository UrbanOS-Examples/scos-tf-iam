resource "null_resource" "add_user_script" {
  provisioner "file" {
    source      = "${path.module}/files/freeipa/add_user.sh"
    destination = "/home/fedora/add_user.sh"

    connection {
      type = "ssh"
      host = aws_instance.freeipa_master.private_ip
      user = "fedora"
    }
  }

  triggers = {
    add_user_script = filesha256("${path.module}/files/freeipa/add_user.sh")
  }
}

resource "null_resource" "extra_users" {
  count = var.extra_users_count

  depends_on = [null_resource.add_user_script]

  provisioner "remote-exec" {
    inline = [
      <<EOF
sudo bash /home/fedora/add_user.sh \
  --username ${var.extra_users[count.index]["username"]} \
  --password ${var.extra_users[count.index]["password"]} \
  --first-name ${var.extra_users[count.index]["first_name"]} \
  --last-name ${var.extra_users[count.index]["last_name"]} \
  ${var.extra_users[count.index]["groups"] != "" ? "--groups ${var.extra_users[count.index]["groups"]}" : ""} \
  --realm-name ${var.realm_name} \
  --admin-password ${random_string.freeipa_admin_password.result}
EOF
      ,
    ]

    connection {
      type = "ssh"
      host = aws_instance.freeipa_master.private_ip
      user = "fedora"
    }
  }

  triggers = {
    add_user_script = filesha256("${path.module}/files/freeipa/add_user.sh")
    user_password_hash = sha256(
      "${var.extra_users[count.index]["username"]}:${var.extra_users[count.index]["password"]}",
    )
  }
}

