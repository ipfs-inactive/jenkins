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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMOBeiZnugxLNgt4sJZPMVzrW3sMpkB2PFv9V4ESW5FZEJPsV0Q09XAfFQL8RxWB0UFMZk43lqImfXoxpLrMyAOa2/sco/2r0uEGtLscYAg6HwCuaXnZeuMwByYIrUSfmZPd7mGo1GYqP5gVfuaKkAVnIplXK5khQL4Ix+aJADDmUdWrBWVeP4KlqfDWM7DCcc8nF9+8C8Wu6uE5a8Zn2c25laML472F3havXysj8lp+VRz2KOSSpVYLOifYajbQH2GaxuynLOny6+vOIVO1LQf5Do+RgWT70sWUdb9S+kjwqlijFUTTvzXuA5cSHReS8h9wtcSRra4qlWpcGr0O0BET1o7CWJXbmmBhtsj+yjR0rR5Xt5/tqEVrHCImdL+ggDmn4wQbRDCRTO6EcnZNiPgdRuve73gguzAFKCINMId3L/ttqOnjn8Bjis046ypKwvSvkan75tJ3/ZpMYSCop51ULdPG8UvdJjH6x75e94S8iH7UYU5c1gFXE+ciukkyyje2ldoaD3zZLUFAWc7XZSZ6iQCvEQCZx32suqgbBzQ4jgoLuxBY7Lpe2sedYGbixBGALgd7jbzG+3NwQeNFOcifbJ/ncPdtpIuYYsKzWtxcJSeOiWqzZWaSkHIqP4TGOgd9GNgedmg/AeeubgDqkN+wI5wy/DynZb0jdtzOZfSQ== victor@niue"
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
      "wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -",
      "echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list",
      "sudo apt update",
      "sudo apt install --yes wget htop default-jre google-chrome-stable xvfb python python3 build-essential make",
      "curl https://get.docker.com | sh",
      "sudo usermod -aG docker ubuntu",
      "cd /tmp && wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${var.swarm_version}/swarm-client-${var.swarm_version}.jar",
      "sudo mv /tmp/swarm.service /etc/systemd/system/swarm.service",
      "sudo systemctl start swarm",
      "echo service started"
    ]
  }

  root_block_device {
    volume_size = "100"
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
      "@\"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command \"iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))\" && SET \"PATH=%PATH%;%ALLUSERSPROFILE%\\chocolatey\\bin\"",
      "choco install -y wget jre8 git nssm googlechrome python2 python3 vcredist2015 make nodejs microsoft-visual-cpp-build-tools ",
      "npm install --verbose --global --production windows-build-tools",
      "wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${var.swarm_version}/swarm-client-${var.swarm_version}.jar",
      "nssm install swarm java -jar C:\\Users\\Administrator\\swarm-client-${var.swarm_version}.jar -master ${var.jenkins_master} -password ${var.jenkins_password} -username ${var.jenkins_username} -tunnel ${var.jenkins_worker_tunnel} -labels ${var.windows_jenkins_worker_labels} -name ${var.windows_jenkins_worker_name} -fsroot ${var.windows_jenkins_worker_fsroot}",
      "nssm start swarm",
    ]
  }

  root_block_device {
    volume_size = "100"
  }

  user_data = <<EOF
<powershell>
  winrm --% quickconfig -q & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"}
  netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
  # Set Administrator password
  $admin = [adsi]("WinNT://./administrator, user")
  $admin.psbase.invoke("SetPassword", "${var.windows_admin_password}")
  Set-MpPreference -DisableRealtimeMonitoring $true
</powershell>
EOF
}

output "windows_ips" {
  value = "${aws_instance.windows.*.public_ip}"
}

output "linux_ips" {
  value = "${aws_instance.linux.*.public_ip}"
}
