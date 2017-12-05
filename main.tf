variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "windows_admin_password" {}

variable "swarm_version" {}

variable "jenkins_username" {}
variable "jenkins_password" {}

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
  region     = "eu-central-1"
}

# provider "vsphere" {
#   user           = "x"
#   password       = "x"
#   vsphere_server = "x"
# 	allow_unverified_ssl = true
# }
# 
# data "vsphere_datacenter" "dc" {
#   name = "MacStadium - D"
# }
# 
# data "vsphere_datastore" "datastore" {
#   name          = "Pure3-1"
#   datacenter_id = "${data.vsphere_datacenter.dc.id}"
# }
# 
# data "vsphere_resource_pool" "pool" {
#   name          = "MacPro_Cluster/Resources"
#   datacenter_id = "${data.vsphere_datacenter.dc.id}"
# }
# 
# data "vsphere_network" "network" {
#   name          = "Inside-1"
#   datacenter_id = "${data.vsphere_datacenter.dc.id}"
# }
# 
# data "vsphere_virtual_machine" "template" {
#   name          = "macOS3"
#   datacenter_id = "${data.vsphere_datacenter.dc.id}"
# }
# 
# resource "vsphere_virtual_machine" "vm" {
#   name             = "terraform-test"
#   resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
#   datastore_id     = "${data.vsphere_datastore.datastore.id}"
# 
#   num_cpus = 2
#   memory   = 1024
# 	guest_id = "darwin15_64Guest"
# 
# 	wait_for_guest_net_timeout = 0
# 
# 	# scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
# 
#   network_interface {
#     network_id = "${data.vsphere_network.network.id}"
#     adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
#   }
# 
#   disk {
#     name = "terraform-test.vmdk"
#     size = 20
#   }
# 
# 
#   clone {
#     template_uuid = "${data.vsphere_virtual_machine.template.id}"
#   }
# }

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

resource "aws_security_group" "jenkins_master" {
  name        = "jenkins_master"
  description = "Allow inbound ssh traffic/everything outbound"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Workers
  ingress {
    from_port   = 50000
    to_port     = 50000
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
    jenkins_master              = "http://${aws_instance.jenkins_master.0.public_ip}:8080"
    jenkins_username            = "${var.jenkins_username}"
    jenkins_password            = "${var.jenkins_password}"
    jenkins_worker_tunnel       = "${aws_instance.jenkins_master.0.public_ip}:50000"
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
      "git config --global core.autocrlf input",
      "wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${var.swarm_version}/swarm-client-${var.swarm_version}.jar",
      "nssm install swarm java -jar C:\\Users\\Administrator\\swarm-client-${var.swarm_version}.jar -master http://${aws_instance.jenkins_master.0.public_ip}:8080 -password ${var.jenkins_password} -username ${var.jenkins_username} -tunnel ${aws_instance.jenkins_master.0.public_ip}:50000 -labels ${var.windows_jenkins_worker_labels} -name ${var.windows_jenkins_worker_name} -fsroot ${var.windows_jenkins_worker_fsroot} -mode exclusive -executors 1",
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

resource "aws_instance" "jenkins_master" {
  ami                         = "ami-df8406b0"
  instance_type               = "m4.xlarge"
  associate_public_ip_address = true
  key_name                    = "victor-ssh-key"
  count                       = "1"
  security_groups             = ["${aws_security_group.jenkins_master.name}"]

  connection {
    type = "ssh"
    user = "ubuntu"
  }

  # Install dependencies + jenkins
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install --yes wget htop default-jre build-essential make",
      "curl https://get.docker.com | sh",
      "sudo usermod -aG docker ubuntu",
      "wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -",
      "echo deb https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list",
      "sudo apt update",
      "sudo apt install --yes jenkins",
      "sudo systemctl stop jenkins",
      "sudo rm -rf /var/lib/jenkins",
      "sudo git clone -b cross-platform-workers https://github.com/ipfs/jenkins.git /var/lib/jenkins",
      "sudo chmod -R 777 /var/lib/jenkins",
    ]
  }

  # Copy jenkins configuration
  provisioner "file" {
    source      = "jenkins.default"
    destination = "/home/ubuntu/jenkins.default"
  }

	# Get secrets
	provisioner "local-exec" {
		command = "./get-secrets.sh"
	}

	# Copy over secrets
  provisioner "file" {
    source      = "jenkins-secrets"
    destination = "/home/ubuntu/secrets"
  }

	# Apply secrets
  provisioner "remote-exec" {
    inline = [
      "cd /var/lib/jenkins && git apply /home/ubuntu/secrets/plain_config_production.patch",,
			"cp /home/ubuntu/secrets/plain_credentials.xml /var/lib/jenkins/config/credentials.xml",
      "sudo systemctl restart jenkins",
			"echo started",
    ]
  }

  # Start jenkins
  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/ubuntu/jenkins.default /etc/default/jenkins",
      "sudo systemctl start jenkins",
    ]
  }

  root_block_device {
    volume_size = "30"
  }
}

output "jenkins_masters" {
  value = "${aws_instance.jenkins_master.*.public_ip}"
}

output "windows_ips" {
  value = "${aws_instance.windows.*.public_ip}"
}

output "linux_ips" {
  value = "${aws_instance.linux.*.public_ip}"
}
