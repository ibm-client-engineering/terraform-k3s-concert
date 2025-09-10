
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.3"
    }
    # pfsense = {
    #   source = "marshallford/pfsense"
    #   version = "0.20.0"
    # }
  }

  required_version = ">= 1.2.0"
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

resource "random_password" "k3s_token" {
  length  = 55
  special = false
}

locals {
  # build the private registry URL
  ssh_key = "../${path.module}/id_rsa"
  inventory = "../${path.module}/inventory.ini"
  private_registry = var.private_registry_repo != "" ? "${var.private_registry_host}:${var.private_registry_port}/${var.private_registry_repo}" : "${var.private_registry_host}:${var.private_registry_port}"

  total_nodes = var.k3s_server_count + var.k3s_agent_count

  # these are the minimums for base and extended deployment
  cpu_pool    = var.mode == "base" ? 136 : 162
  mem_pool_gb = var.mode == "base" ? 322 : 380

  # calculate cpus and memory needed per node
  num_cpus = max(16, ceil(local.cpu_pool / local.total_nodes))
  memory   = max(20480, ceil(local.mem_pool_gb / local.total_nodes) * 1024)
}

# provider "pfsense" {
#   url      = "https://${var.pfsense_host}" 
#   username = var.pfsense_username
#   password = var.pfsense_password
#   tls_skip_verify = true
# }

# Render our ansible inventory file
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = templatefile("${path.module}/templates/inventory.ini.tpl", {
    server_ips = local.server_ips
    agent_ips  = local.agent_ips
    mailcow_ip = var.mailcow_ip
    nfs_server_ip = var.nfs_server_ip
    use_mailcow = var.use_mailcow
    use_nfs = var.use_nfs
    remote_user = var.remote_user
    ssh_key = local.ssh_key
  })
}

# Render a sub file to use for ansible. This will have our entitlement key as well as our RHSM creds
resource "local_file" "ansible_subs" {
  filename = "${path.module}/ansible/rhel_sub.yaml"
  content  = templatefile("${path.module}/templates/rhel_sub.yaml.tpl", {
    rhsm_user       = var.rhsm_username
    rhsm_pass       = var.rhsm_password
    ibm_entitlement_key = var.ibm_entitlement_key
  })
}

# Render our ansible.cfg file
resource "local_file" "ansible_cfg" {
  filename = "${path.module}/ansible.cfg"
  content  = templatefile("${path.module}/templates/ansible.cfg.tpl", {
    remote_user = var.remote_user
    ssh_key     = "../${path.module}/id_rsa"
    ssh_key = local.ssh_key
    inventory  = local.inventory
  })
}

resource "ansible_playbook" "k3s_concert" {
  count        = var.kickoff_ansible ? 1 : 0
  name = "localhost"
  playbook     = "${path.module}/ansible/playbook.yaml"
  replayable = true
  extra_vars = {
    rhsm_user           = var.rhsm_username
    rhsm_pass           = var.rhsm_password
    ibm_entitlement_key  = var.ibm_entitlement_key
  }
  depends_on = [local_file.ansible_cfg, local_file.ansible_inventory, local_file.ansible_subs]
}
