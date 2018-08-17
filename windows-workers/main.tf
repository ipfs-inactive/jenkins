variable "swarm_version" {}

variable "jenkins_username" {}
variable "jenkins_password" {}

variable "windows_admin_password" {}

variable "windows_ami" {}
variable "windows_type" {}
variable "windows_count" {}
variable "windows_jenkins_worker_labels" {}
variable "windows_jenkins_worker_name" {}
variable "windows_jenkins_worker_fsroot" {}

variable "jenkins_master_domain" {}

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

  # Prometheus
  ingress {
    from_port   = 9182
    to_port     = 9182
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

resource "aws_instance" "windows" {
  security_groups             = ["${aws_security_group.jenkins_windows.name}"]
  ami                         = "${var.windows_ami}"
  instance_type               = "${var.windows_type}"
  associate_public_ip_address = true
  key_name                    = "victor-ssh-key"
  count                       = "${terraform.workspace == "default" ? var.windows_count : 1}"

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

  provisioner "remote-exec" {
    inline = [
      "@\"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command \"iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))\" && SET \"PATH=%PATH%;%ALLUSERSPROFILE%\\chocolatey\\bin\"",
      "choco install -y wget jre8 git nssm googlechrome python2 python3 vcredist2015 make nodejs microsoft-visual-cpp-build-tools rktools.2003",
      "npm install --verbose --global --production windows-build-tools",
      "git config --global core.autocrlf input",
      "wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${var.swarm_version}/swarm-client-${var.swarm_version}.jar",
      "nssm install swarm java -jar C:\\Users\\Administrator\\swarm-client-${var.swarm_version}.jar -master http://${var.jenkins_master_domain}:8080 -password ${var.jenkins_password} -username ${var.jenkins_username} -tunnel ${var.jenkins_master_domain}:50000 -labels ${var.windows_jenkins_worker_labels} -name ${var.windows_jenkins_worker_name} -fsroot ${var.windows_jenkins_worker_fsroot} -mode exclusive -executors 1",
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

output "ips" {
  value = "${aws_instance.windows.*.public_ip}"
}
