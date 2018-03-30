variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}

# TODO experiment in progress for getting automated
# setup of macOS workers, not currently working
provider "vsphere" {
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"
  vsphere_server       = "${var.vsphere_server}"
  allow_unverified_ssl = true
}

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
  name          = "BaseMacOS2"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  name             = "terraform-test"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 2
  memory   = 1024
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label = "disk0"
    size  = 20
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      network_interface {}
    }
  }
}

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

