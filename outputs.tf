output "key-private-pem" {
  value = tls_private_key.ssh-key.private_key_pem
  sensitive = true
}

output "key-public-openssh" {
  value = tls_private_key.ssh-key.public_key_openssh
}