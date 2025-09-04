locals {
  nfs-server_metadata = templatefile("${path.module}/cloudinit/nfs-server-metadata.yaml", {
    base_domain = "${var.base_domain}"
  })
}

data "cloudinit_config" "nfs-server_userdata" {
  gzip          = false
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloudinit/nfs-server-userdata.yaml", {
      base_domain = "${var.base_domain}"
      public_key  = tls_private_key.deployer.public_key_openssh
    })
  }
}

resource "vsphere_virtual_machine" "nfs-server" {
  count            = var.use_nfs ? 1 : 0
  name             = "nfs-server"
  resource_pool_id = data.vsphere_resource_pool.target_pool.id
  datastore_id     = data.vsphere_datastore.this.id

  folder = var.vsphere_folder

  num_cpus  = 2
  memory    = 2048
  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  cdrom {
    client_device = true
  }

  network_interface {
    network_id = data.vsphere_network.this.id
  }

  wait_for_guest_net_timeout = 30

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  disk {
    label            = "disk1"
    size             = 500 # Size in GB
    unit_number      = 1
    eagerly_scrub    = false
    thin_provisioned = true
  }

  firmware                = "efi" # Ensure this matches your Packer template's firmware type
  efi_secure_boot_enabled = false # Disable Secure Boot during cloning

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  extra_config = {
    "guestinfo.metadata"          = base64encode(local.nfs-server_metadata)
    "guestinfo.metadata.encoding" = "base64"
    "guestinfo.userdata"          = data.cloudinit_config.nfs-server_userdata.rendered
    "guestinfo.userdata.encoding" = "base64"
  }

  lifecycle {
    prevent_destroy = false
  }
}
