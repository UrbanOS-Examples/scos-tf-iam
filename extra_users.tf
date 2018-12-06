resource "null_resource" "add_user_script" {
  provisioner "file" {
    source      = "${path.module}/files/freeipa/add_user.sh"
    destination = "/home/fedora/add_user.sh"

    connection {
      type = "ssh"
      host = "${aws_instance.freeipa_master.private_ip}"
      user = "fedora"
    }
  }

  triggers {
    add_user_script = "${sha256(file("${path.module}/files/freeipa/add_user.sh"))}"
  }
}

resource "null_resource" "extra_users" {
  count = "${var.extra_users_count}"

  depends_on = ["null_resource.add_user_script"]

  provisioner "remote-exec" {
    inline = [
      <<EOF
sudo bash /home/fedora/add_user.sh \
  --username ${lookup(var.extra_users[count.index], "name")} \
  --password ${lookup(var.extra_users[count.index], "password")} \
  --first-name ${lookup(var.extra_users[count.index], "first_name")} \
  --last-name ${lookup(var.extra_users[count.index], "last_name")} \
  --realm-name ${var.realm_name} \
  --admin-password ${random_string.freeipa_admin_password.result}
EOF
    ]

    connection {
      type = "ssh"
      host = "${aws_instance.freeipa_master.private_ip}"
      user = "fedora"
    }
  }

  triggers {
    add_user_script = "${sha256(file("${path.module}/files/freeipa/add_user.sh"))}"
    user_password_hash = "${sha256("${lookup(var.extra_users[count.index], "name")}:${lookup(var.extra_users[count.index], "password")}")}"
  }
}