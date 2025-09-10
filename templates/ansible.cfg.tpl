[defaults]
stdout_callback = defaults
display_skipped_hosts = false
ansible_user = ${remote_user}
ansible_ssh_private_key_file = ${ssh_key}
ansible_python_interpreter = /usr/bin/python3
inventory = ${inventory}

[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa