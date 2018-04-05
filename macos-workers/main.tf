variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}

variable "jenkins_username" {}
variable "jenkins_password" {}

variable "macos_count" {}

data "vsphere_datacenter" "dc" {
  name = "MacStadium - D"
}

data "vsphere_datastore" "datastore" {
  name          = "Pure3-1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "MacPro_Cluster/Resources"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "Inside-1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "BaseMacOS3"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "template_file" "swarm_launchd" {
  template = "${file("${path.module}/com.jenkins.swarm.plist")}"

  vars {
    username = "${var.jenkins_username}"
    password = "${var.jenkins_password}"
  }
}

resource "vsphere_virtual_machine" "vm" {
  name             = "macos-${count.index}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  count            = "${var.macos_count}"

  num_cpus                   = 2
  memory                     = "${1024 * 10}"
  guest_id                   = "${data.vsphere_virtual_machine.template.guest_id}"
  wait_for_guest_net_timeout = -1
  firmware                   = "efi"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label = "disk0"

    # TODO this currently doesn't work correctly, VMs always get
    # 100GB disk + what's specified here.
    size = 20
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
  }

  provisioner "local-exec" {
    command = "govc vm.ip -v4 -a macos-${count.index} > ${path.module}/host-ip-${count.index}"

    environment {
      GOVC_INSECURE = 1
      GOVC_URL      = "${var.vsphere_server}"
      GOVC_USERNAME = "${var.vsphere_user}"
      GOVC_PASSWORD = "${var.vsphere_password}"
    }
  }

  connection {
    # TODO these files have to exists before running `terraform apply`
    # `touch host-ip-{0,1,2,3,4,5,6}` creates them for you
    # Ref: https://github.com/hashicorp/terraform/issues/6460
    host = "${file(format("%s%v", "${path.module}/host-ip-", count.index))}"

    type = "ssh"
    user = "user"
  }

  provisioner "file" {
    content     = "${data.template_file.swarm_launchd.rendered}"
    destination = "/Users/user/Library/LaunchAgents/com.jenkins.swarm.plist"
  }

  provisioner "remote-exec" {
    inline = [
      "launchctl load /Users/user/Library/LaunchAGents/com.jenkins.swarm.plist",
      "launchctl start com.jenkins.swarm",
    ]
  }
}

output "ips" {
  value = "${vsphere_virtual_machine.vm.*.guest_ip_addresses}"
}
