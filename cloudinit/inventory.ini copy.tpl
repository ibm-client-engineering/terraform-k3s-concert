[kube_control_plane]
%{ for name, ip in master_nodes ~}
${name} ansible_host=${ip} ansible_user=core
%{ endfor }

[etcd:children]
kube_control_plane

[kube_node]
%{ for name, ip in worker_nodes ~}
${name} ansible_host=${ip} ansible_user=core
%{ endfor }

[all:vars]
ansible_ssh_user=core
ansible_ssh_private_key_file=/home/${username}/.ssh/id_rsa

[k8s_cluster:children]
kube_control_plane
kube_node