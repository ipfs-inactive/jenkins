variable "swarm_version" {}

variable "jenkins_username" {}
variable "jenkins_password" {}

variable "windows_admin_password" {}

variable "windows_type" {}
variable "windows_jenkins_worker_labels" {}
variable "windows_jenkins_worker_name" {}
variable "windows_jenkins_worker_fsroot" {}

variable "jenkins_master_domain" {}

resource "aws_instance" "windows" {
  security_groups             = ["jenkins_windows"]
  ami                         = "ami-0ec85d6b6e45db087"
  instance_type               = "${var.windows_type}"
  associate_public_ip_address = true
  key_name                    = "victor-ssh-key"
  count                       = "10"

  tags {
    Name = "worker-windows"
  }

  connection {
    type = "winrm"
    user = "Administrator"

    password = "${var.windows_admin_password}"

    # set from default of 5m to 10m to avoid winrm timeout
    timeout = "30m"
  }

  provisioner "file" {
    source = "packer-windows-workers/resize.diskpart"
    destination = "C:\\Users\\Administrator\\resize.diskpart"
  }

  provisioner "remote-exec" {
    inline = [
      "diskpart /s C:\\Users\\Administrator\\resize.diskpart",
      "nssm install swarm java -jar C:\\Users\\Administrator\\swarm-client-${var.swarm_version}.jar -master http://${var.jenkins_master_domain}:8080 -password ${var.jenkins_password} -username ${var.jenkins_username} -tunnel ${var.jenkins_master_domain}:50000 -labels ${var.windows_jenkins_worker_labels} -name ${var.windows_jenkins_worker_name} -fsroot ${var.windows_jenkins_worker_fsroot} -mode exclusive -executors 1",
      "nssm start swarm",
    ]
  }

  root_block_device {
    volume_size = "100"
  }
}

output "ips" {
  value = "${aws_instance.windows.*.public_ip}"
}
