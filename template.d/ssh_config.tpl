Host bastion
  HostName ${ip_address}
  User ${ssh_login_user}
  IdentityFile ${ssh_identity_file}
  IdentitiesOnly yes
  ForwardAgent yes
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
