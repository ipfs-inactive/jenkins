variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "windows_admin_password" {}

variable "swarm_version" {}

variable "jenkins_master" {}
variable "jenkins_username" {}
variable "jenkins_password" {}
variable "jenkins_worker_tunnel" {}

variable "linux_ami" {}
variable "linux_type" {}
variable "linux_count" {}
variable "linux_jenkins_worker_labels" {}
variable "linux_jenkins_worker_name" {}
variable "linux_jenkins_worker_fsroot" {}

variable "windows_ami" {}
variable "windows_type" {}
variable "windows_count" {}
variable "windows_jenkins_worker_labels" {}
variable "windows_jenkins_worker_name" {}
variable "windows_jenkins_worker_fsroot" {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

resource "aws_key_pair" "victor-ssh" {
  # TODO should add more peoples keys as well
  key_name   = "victor-ssh-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrlu15krG+ihFgYpkjkBwYxjVpgh2VUGAbtVSlzA0CgZ957GyCGz7kUzMcxA00Hbnhx+PbLwIy7Q0kRz32yon5mpnyUHqRlriq44kHeqQUgQTGW3+HWK+f81BWCTQp+9zFwgpFREAeh6qAWHx+aTO6oXxGLWVclZ5eT/G29ShOm39TCt3WUaQy6IZyQbuVz3F/KROCQUz43XwJxQfGLQHCLldm8Pii3dO37p15RpyPx6LdzdhFsCvKqSdnWv/webdLi8VgpGTa1oXaTUH3zsnjr+UdkHA1ombxgUT5wROb+6v1XxVtt2plw9XQCD1KqHGSJVNMPWBN6VvGZiP0JdsTc78tOVECJYIvgBshtOCilXGejyQYxxNdunFocMFw3nidFPXyQq2mIffDEt2gRlLoVK9bfcHQCVtu0+9q4NrcMpdpBOfdEPGDVwv2kLc92J6TvIuf4u4Thcw8Mwa/ykWamlRuM7Ti8hiIPQca02YJUOAjQ65+5HU9TDO3tlei2PuehVRDncEMKV4w03pq4bXxOPXOHFnC06LFOYR2YJWLoJHK46UhJWhFDFhJp14Zs6ILaBbDXVSM/7b9f9ZHtY8EL4u7wlZ6Qzlh2tthW6M4x7aof6cvG7YNRgbyF6RuoCOIzb13tkLzjfqG05msEEwnSsCb1DuYFGA6kRR/qujXqQ== victor@tokelau"
}

resource "aws_security_group" "jenkins_windows" {
  name        = "jenkins_windows"
  description = "Allow inbound WinRM/RDP and everything outbound"

  # WinRM
  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDP
  ingress {
    from_port   = 3389
    to_port     = 3389
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
    jenkins_master              = "${var.jenkins_master}"
    jenkins_username            = "${var.jenkins_username}"
    jenkins_password            = "${var.jenkins_password}"
    jenkins_worker_tunnel       = "${var.jenkins_worker_tunnel}"
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
  count                       = "${var.linux_count}"

  connection {
    type = "ssh"
    user = "ubuntu"
  }

  provisioner "file" {
    content     = "${data.template_file.jenkins_worker_service.rendered}"
    destination = "/tmp/swarm.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install --yes wget htop default-jre",

      # TODO should be copied over instead of downloaded
      "cd /tmp && wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${var.swarm_version}/swarm-client-${var.swarm_version}.jar",

      "sudo mv /tmp/swarm.service /etc/systemd/system/swarm.service",
      "sudo systemctl start swarm",
    ]
  }
}

resource "aws_instance" "windows" {
  security_groups             = ["${aws_security_group.jenkins_windows.name}"]
  ami                         = "${var.windows_ami}"
  instance_type               = "${var.windows_type}"
  associate_public_ip_address = true
  key_name                    = "victor-ssh-key"
  count                       = "${var.windows_count}"

  connection {
    type = "winrm"
    user = "Administrator"

    password = "${var.windows_admin_password}"

    # set from default of 5m to 10m to avoid winrm timeout
    timeout = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      # For some reason, has to call this again for wget to be in $PATH...
      "choco install -y wget",

      "wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${var.swarm_version}/swarm-client-${var.swarm_version}.jar",
      "SLEEP 10",
      "nssm install swarm java -jar C:\\Users\\Administrator\\swarm-client-${var.swarm_version}.jar -master ${var.jenkins_master} -password ${var.jenkins_password} -username ${var.jenkins_username} -tunnel ${var.jenkins_worker_tunnel} -labels ${var.windows_jenkins_worker_labels} -mode exclusive -name ${var.windows_jenkins_worker_name} -fsroot ${var.windows_jenkins_worker_fsroot}",
      "nssm start swarm",
    ]
  }

  user_data = <<EOF
<powershell>
  winrm --% quickconfig -q & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"}
  netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
  # Set Administrator password
  $admin = [adsi]("WinNT://./administrator, user")
  $admin.psbase.invoke("SetPassword", "${var.windows_admin_password}")

	# Install Java and run slave
# TODO should be copied over instead of downloaded
	Set-ExecutionPolicy Bypass; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	refreshenv
	choco install -y jre8 git wget nssm
	refreshenv
# TODO should be copied over instead of downloaded
	wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${var.swarm_version}/swarm-client-${var.swarm_version}.jar -OutFile swarm.jar
</powershell>
EOF
}

output "windows_ips" {
  value = "${aws_instance.windows.*.public_ip}"
}

output "linux_ips" {
  value = "${aws_instance.linux.*.public_ip}"
}
