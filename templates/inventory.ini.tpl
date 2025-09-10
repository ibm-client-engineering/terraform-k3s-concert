[loadbalancer]
haproxy ansible_host=192.168.252.9 ansible_user=${remote_user}


[servers]
%{ for name, ip in server_ips ~}
${name} ansible_host=${ip} ansible_user=${remote_user} primary=${name == keys(server_ips)[0]}
%{ endfor }

[nfs]
%{ if use_nfs ~}
nfs-server ansible_host=${nfs_server_ip} ansible_user=${remote_user}
%{ endif ~}

[mail]
%{ if use_mailcow ~}
mailcow ansible_host=${mailcow_ip} ansible_user=${remote_user}
%{ endif ~}

[agents]
%{ for name, ip in agent_ips ~}
${name} ansible_host=${ip} ansible_user=${remote_user}
%{ endfor }

[all:vars]
ansible_ssh_user=${remote_user}
ansible_ssh_private_key_file=${ssh_key}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[k3s_cluster:children]
servers
agents