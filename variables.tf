variable "tenancy_ocid" {
    description = "The OCID of the tenancy."
    type = string
}

variable "user_ocid" {
    description = "The OCID of the user."
    type = string
}

variable "fingerprint" {
    description = "The fingerprint of the public key used for authentication."
    type = string
}

variable "private_key_path" {
    description = "The path to the private key used for authentication."
    type = string
}

variable "region" {
    description = "The region to create resources."
    type = string
    default = "ap-osaka-1"
}

variable "compartment_ocid" {
    description = "The OCID of the compartment."
    type = string
}

variable "ssh_key_export_path" {
    description = "The path to export the SSH key."
    type = string
    default = "outputs/ssh-key.pem"
}