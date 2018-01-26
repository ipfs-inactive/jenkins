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

  # All allowed outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "jenkins_worker_service" {
  template = "${file("swarm.service")}"

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
  ami                         = "${var.linux_ami}"
  instance_type               = "${var.linux_type}"
  associate_public_ip_address = true
  key_name                    = "victor-ssh-key"
  count                       = "${terraform.workspace == "default" ? var.linux_count : 1}"
  tags { Name = "worker-linux" }

  connection {
    type = "ssh"
    user = "ubuntu"
  }

  provisioner "file" {
    source     = "./ipfs.service"
    destination = "/tmp/ipfs.service"
  }

  provisioner "file" {
    content     = "${data.template_file.jenkins_worker_service.rendered}"
    destination = "/tmp/swarm.service"
  }

  provisioner "remote-exec" {
    inline = [
      "wget https://dist.ipfs.io/go-ipfs/v0.4.13/go-ipfs_v0.4.13_linux-amd64.tar.gz",
      "tar xfv go-ipfs_v0.4.13_linux-amd64.tar.gz",
      "cd go-ipfs && sudo ./install.sh",
      "sudo mv /tmp/ipfs.service /etc/systemd/system/ipfs.service",
      "sudo systemctl start ipfs"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -",
      "echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list",
      "sudo apt update",
      "sudo apt install --yes wget htop default-jre google-chrome-stable xvfb python python3 build-essential make rpm",
      "curl https://get.docker.com | sh",
      "sudo usermod -aG docker ubuntu",
      "cd /tmp && wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${var.swarm_version}/swarm-client-${var.swarm_version}.jar",
      "sudo mv /tmp/swarm.service /etc/systemd/system/swarm.service",
      "sudo systemctl start swarm",
      "echo service started",
    ]
  }

  root_block_device {
    volume_size = "100"
  }
}

output "ips" {
  value = "${aws_instance.linux.*.public_ip}"
}
