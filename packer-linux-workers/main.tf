variable "swarm_version" {}

variable "jenkins_username" {}
variable "jenkins_password" {}
variable "jenkins_master_domain" {}

variable "linux_ami" {}
variable "linux_type" {}
variable "linux_count" {}
variable "linux_jenkins_worker_labels" {}
variable "linux_jenkins_worker_name" {}
variable "linux_jenkins_worker_fsroot" {}

resource "aws_security_group" "jenkins_linux" {
  name        = "jenkins_linux"
  description = "Allow inbound ssh traffic/everything outbound"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # IPFS swarm
  ingress {
    from_port   = 4001
    to_port     = 4001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All allowed outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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
  security_groups             = ["${aws_security_group.jenkins_linux.name}"]
  # TODO make this come from a variable
  ami                         = "${var.linux_ami}"
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
      "sudo mv /home/ubuntu/swarm.service /etc/systemd/system/swarm.service"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl start swarm",
      "sudo systemctl start node_exporter",
      "sudo systemctl start ipfs",
      "echo all services started"
    ]
  }

  root_block_device {
    volume_size = "100"
  }
}

output "ips" {
  value = "${aws_instance.linux.*.public_ip}"
}
