variable "swarm_version" {}

variable "jenkins_username" {}
variable "jenkins_password" {}
variable "jenkins_master_domain" {}

variable "linux_type" {}
variable "linux_count" {}
variable "linux_jenkins_worker_labels" {}
variable "linux_jenkins_worker_name" {}
variable "linux_jenkins_worker_fsroot" {}

data "template_file" "jenkins_worker_service" {
  template = "${file("services/swarm/swarm.service")}"

  vars {
    swarm_version               = "${var.swarm_version}"
    jenkins_master              = "http://${var.jenkins_master_domain}:8080"
    jenkins_username            = "${var.jenkins_username}"
    jenkins_password            = "${var.jenkins_password}"
    jenkins_worker_tunnel       = "${var.jenkins_master_domain}:50000"
    linux_jenkins_worker_labels = "${var.linux_jenkins_worker_labels}"
    linux_jenkins_worker_name   = "${var.linux_jenkins_worker_name}"
    linux_jenkins_worker_fsroot = "${var.linux_jenkins_worker_fsroot}"
  }
}

resource "aws_instance" "linux" {
  # TODO make this come from the generated security group
  security_groups             = ["jenkins_linux"]
  # TODO make this come from a variable
  ami                         = "ami-0276b129e8cd261c5"
  instance_type               = "${var.linux_type}"
  associate_public_ip_address = true
  key_name                    = "victor-ssh-key"
  count                       = "${terraform.workspace == "default" ? var.linux_count : 1}"

  tags {
    Name = "worker-linux"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
  }

  # Keep this here as it contains bunch of secrets
  provisioner "file" {
    content     = "${data.template_file.jenkins_worker_service.rendered}"
    destination = "/home/ubuntu/swarm.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ubuntu/swarm.service /etc/systemd/system/swarm.service",
      "sudo systemctl start swarm",
      "echo service started",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl start node_exporter"
    ]
  }

  root_block_device {
    volume_size = "100"
  }
}

output "ips" {
  value = "${aws_instance.linux.*.public_ip}"
}
