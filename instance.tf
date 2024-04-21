resource "oci_core_instance" "k8s-master" {
	availability_config {
		recovery_action = "RESTORE_INSTANCE"
	}
	availability_domain = data.oci_identity_availability_domains.ad.availability_domains.0.name
	compartment_id = var.compartment_ocid
	create_vnic_details {
		assign_ipv6ip = "false"
		assign_private_dns_record = "true"
        private_ip = "10.0.1.10"
		assign_public_ip = "true"
		display_name = "k8s-master"
		subnet_id = oci_core_subnet.k8s-public.id
	}
	display_name = "k8s-master"
	shape = "VM.Standard.A1.Flex"
	shape_config {
		memory_in_gbs = "12"
		ocpus = "2"
	}
	source_details {
		boot_volume_size_in_gbs = "100"
		boot_volume_vpus_per_gb = "10"
		source_id = data.oci_core_images.ubuntu-20-04-arm.images.0.id
		source_type = "image"
	}

    provisioner "local-exec" {
        command = "chmod +x ./scripts/local.sh && ./scripts/local.sh"
    
        interpreter = ["bash", "-c"]
        environment = {
            SSH_KEY_PATH = "./${var.ssh_key_export_path}",
            MASTER_PUBLIC_IP = self.public_ip,
        }
    }

    metadata = {
        ssh_authorized_keys = tls_private_key.ssh-key.public_key_openssh
        user_data = "${base64encode(data.local_file.init-master.content)}"
    }
}

resource "oci_core_instance" "k8s-worker" {
	availability_config {
		recovery_action = "RESTORE_INSTANCE"
	}
	availability_domain = data.oci_identity_availability_domains.ad.availability_domains.0.name
	compartment_id = var.compartment_ocid
	create_vnic_details {
		assign_ipv6ip = "false"
		assign_private_dns_record = "true"
        assign_public_ip = "false"
        private_ip = "10.0.2.10"
		display_name = "k8s-worker"
		subnet_id = oci_core_subnet.k8s-private.0.id
	}
	display_name = "k8s-worker"
	shape = "VM.Standard.A1.Flex"
	shape_config {
		memory_in_gbs = "6"
		ocpus = "1"
	}
	source_details {
		boot_volume_size_in_gbs = "50"
		boot_volume_vpus_per_gb = "10"
		source_id = data.oci_core_images.ubuntu-20-04-arm.images.0.id
		source_type = "image"
	}

    metadata = {
        ssh_authorized_keys = tls_private_key.ssh-key.public_key_openssh
        user_data = "${base64encode(data.local_file.init-worker.content)}"
    }
}