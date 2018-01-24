variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "dnsimple_token" {}
variable "dnsimple_account" {}
variable "dnsimple_domain" {}
variable "dnsimple_subdomain" {}

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

variable "jenkins_master_auth_client_id" {}
variable "jenkins_master_auth_client_secret" {}
variable "jenkins_master_immutablejenkins_auth_token" {}
variable "jenkins_master_github_webhook_secret" {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

provider "dnsimple" {
  token = "${var.dnsimple_token}"
  account = "${var.dnsimple_account}"
}

# TODO experiment in progress for getting automated
# setup of macOS workers, not currently working
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

  # http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # https
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins
  # TODO should not be needed anymore
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Workers
  # TODO move workers to use internal network
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

module "linux-workers" {
  source = "./linux-workers"
  swarm_version = "${var.swarm_version}"
  jenkins_username = "${var.jenkins_username}"
  jenkins_password = "${var.jenkins_password}"
  linux_ami = "${var.linux_ami}"
  linux_type = "${var.linux_type}"
  linux_count = "${var.linux_count}"
  linux_jenkins_worker_labels = "${var.linux_jenkins_worker_labels}"
  linux_jenkins_worker_name = "${var.linux_jenkins_worker_name}"
  linux_jenkins_worker_fsroot = "${var.linux_jenkins_worker_fsroot}"
  jenkins_master_ip = "${aws_instance.jenkins_master.0.public_ip}"
}

resource "aws_instance" "windows" {
  security_groups             = ["${aws_security_group.jenkins_windows.name}"]
  ami                         = "${var.windows_ami}"
  instance_type               = "${var.windows_type}"
  associate_public_ip_address = true
  key_name                    = "victor-ssh-key"
  count                       = "${terraform.workspace == "default" ? var.windows_count : 1}"
  tags { Name = "worker-windows" }

  connection {
    type = "winrm"
    user = "Administrator"

    password = "${var.windows_admin_password}"

    # set from default of 5m to 10m to avoid winrm timeout
    timeout = "30m"
  }

  provisioner "remote-exec" {
    inline = [
      "@\"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command \"iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))\" && SET \"PATH=%PATH%;%ALLUSERSPROFILE%\\chocolatey\\bin\"",
      "choco install -y wget jre8 git nssm googlechrome python2 python3 vcredist2015 make nodejs microsoft-visual-cpp-build-tools rktools.2003",
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

resource "dnsimple_record" "jenkins_domain" {
  domain = "${var.dnsimple_domain}"
  name   = "${terraform.workspace == "default" ? var.dnsimple_subdomain : join(".", list(terraform.workspace, var.dnsimple_subdomain))}"
  value  = "${aws_instance.jenkins_master.0.public_ip}"
  type   = "A"
  ttl    = 1
}

resource "aws_instance" "jenkins_master" {
  ami                         = "${var.linux_ami}"
  instance_type               = "m4.xlarge"
  associate_public_ip_address = true
  key_name                    = "victor-ssh-key"
  count                       = "1"
  security_groups             = ["${aws_security_group.jenkins_master.name}"]
  tags { Name = "jenkins-master" }

  connection {
    type = "ssh"
    user = "ubuntu"
  }

  provisioner "file" {
    source      = "config"
    destination = "/home/ubuntu/jenkins"
  }

  # Install dependencies + jenkins
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install --yes wget htop default-jre build-essential make python-minimal",
      "curl https://get.docker.com | sh",
      "sudo usermod -aG docker ubuntu",
      # Prevent jenkins to start by itself
      "echo exit 101 | sudo tee /usr/sbin/policy-rc.d",
      "sudo chmod +x /usr/sbin/policy-rc.d",
      "wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -",
      "echo deb https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list",
      "sudo apt update",
      "sudo apt install --yes jenkins",
      "sudo rm -rf /var/lib/jenkins",
      "sudo mv /home/ubuntu/jenkins /var/lib/jenkins",
      "sudo chown -R jenkins /var/lib/jenkins"
    ]
  }

  # Setup caddy
  provisioner "file" {
    source      = "Caddyfile"
    destination = "/home/ubuntu/Caddyfile"
  }
  provisioner "file" {
    source      = "caddy.service"
    destination = "/tmp/caddy.service"
  }
  provisioner "remote-exec" {
    inline = [
      "curl https://getcaddy.com | bash -s personal",
      "sudo mv /tmp/caddy.service /etc/systemd/system/caddy.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl start caddy",
      "echo caddy running"
    ]
  }

  # Copy jenkins configuration
  provisioner "file" {
    source      = "jenkins.default"
    destination = "/home/ubuntu/jenkins.default"
  }

  provisioner "file" {
    content     = "${var.jenkins_master_auth_client_id}"
    destination = "/tmp/clientid"
  }

  provisioner "file" {
    content     = "${var.jenkins_master_auth_client_secret}"
    destination = "/tmp/clientsecret"
  }

  provisioner "file" {
    content     = "${var.jenkins_master_immutablejenkins_auth_token}"
    destination = "/tmp/userauthtoken"
  }

  provisioner "file" {
    content     = "${var.jenkins_master_github_webhook_secret}"
    destination = "/tmp/githubwebhooksecret"
  }

  # Start jenkins
  provisioner "remote-exec" {
    inline = [
      "sudo chown jenkins /tmp/clientid",
      "sudo chown jenkins /tmp/clientsecret",
      "sudo chown jenkins /tmp/userauthtoken",
      "sudo chown jenkins /tmp/githubwebhooksecret",
      "sudo cp /home/ubuntu/jenkins.default /etc/default/jenkins",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart jenkins",
      "echo applied default file",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo applying security configuration",
      "sleep 20 && sudo bash /var/lib/jenkins/setup-auth.sh",
    ]
  }

  root_block_device {
    volume_size = "1000"
  }
}

output "jenkins_masters" {
  value = "${aws_instance.jenkins_master.*.public_ip}"
}

output "linux_ips" {
  value = "${module.linux-workers.ips}"
}

output "windows_ips" {
  value = "${aws_instance.windows.*.public_ip}"
}
