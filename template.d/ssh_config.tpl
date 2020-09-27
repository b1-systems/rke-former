Host bastion
  HostName ${ip_address}
  User ${ssh_login_user}
  IdentityFile ${ssh_identity_file}
  IdentitiesOnly yes
  ForwardAgent yes
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
%{for hostname, ip in hosts ~}
Host ${hostname}
  Hostname ${ip}
  User ${ssh_login_user}
  IdentityFile ${ssh_identity_file}
  IdentitiesOnly yes
  ForwardAgent yes
  ProxyJump bastion
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
%{endfor}
