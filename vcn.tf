resource "oci_core_vcn" "k8s-vcn" {
	cidr_blocks = ["10.0.0.0/16"]
	compartment_id = var.compartment_ocid
	display_name = "k8s-vcn"
	is_ipv6enabled = "false"
}

resource "oci_core_internet_gateway" "k8s-igw" {
    compartment_id = var.compartment_ocid
    display_name = "k8s-igw"
    vcn_id = oci_core_vcn.k8s-vcn.id
}

resource "oci_core_nat_gateway" "k8s-nat" {
    compartment_id = var.compartment_ocid
    display_name = "k8s-nat"
    vcn_id = oci_core_vcn.k8s-vcn.id
}

resource "oci_core_route_table" "k8s-pub-rt" {
    compartment_id = var.compartment_ocid
    display_name = "k8s-pub-rt"
    vcn_id = oci_core_vcn.k8s-vcn.id

    route_rules {
        network_entity_id = oci_core_internet_gateway.k8s-igw.id
        destination_type = "CIDR_BLOCK"
        destination = "0.0.0.0/0"
        description = "Route to the internet gateway"
    }
}

resource "oci_core_route_table" "k8s-priv-rt" {
    compartment_id = var.compartment_ocid
    display_name = "k8s-priv-rt"
    vcn_id = oci_core_vcn.k8s-vcn.id

    route_rules {
        network_entity_id = oci_core_nat_gateway.k8s-nat.id
        destination_type = "CIDR_BLOCK"
        destination = "0.0.0.0/0"
        description = "Route to the NAT gateway"
    }
}

resource "oci_core_security_list" "k8s-pub-sec-list" {
    compartment_id = var.compartment_ocid
    display_name = "k8s-pub-sec-list"
    vcn_id = oci_core_vcn.k8s-vcn.id

    egress_security_rules {
        destination = "0.0.0.0/0"
        protocol = "all"
        description = "Allow all traffic to the internet"
    }

    ingress_security_rules {
        source = "0.0.0.0/0"
        protocol = 6
        tcp_options {
            max = 22
            min = 22
        }
        description = "Allow SSH traffic"
    }

    ingress_security_rules {
        source = "0.0.0.0/0"
        protocol = 6
        tcp_options {
            max = 80
            min = 80
        }
        description = "Allow HTTP traffic"
    }

    ingress_security_rules {
        source = "0.0.0.0/0"
        protocol = 6
        tcp_options {
            max = 443
            min = 443
        }
        description = "Allow HTTPS traffic"
    }

    ingress_security_rules {
        source = "10.0.0.0/16"
        protocol = "all"
        description = "Allow all traffic from the VCN"
    }
}

resource "oci_core_security_list" "k8s-priv-sec-list" {
    compartment_id = var.compartment_ocid
    display_name = "k8s-priv-sec-list"
    vcn_id = oci_core_vcn.k8s-vcn.id

    egress_security_rules {
        destination = "0.0.0.0/0"
        protocol = "all"
        description = "Allow all traffic to the internet"
    }

    ingress_security_rules {
        source = "10.0.0.0/16"
        protocol = "all"
        description = "Allow all traffic from the VCN"
    }
}


resource "oci_core_subnet" "k8s-public" {
    cidr_block = "10.0.1.0/24"
    compartment_id = var.compartment_ocid
    display_name = "k8s-public"
    vcn_id = oci_core_vcn.k8s-vcn.id
    route_table_id = oci_core_route_table.k8s-pub-rt.id
    security_list_ids = [oci_core_security_list.k8s-pub-sec-list.id]
}

resource "oci_core_subnet" "k8s-private" {
    count = 2
    cidr_block = "10.0.${count.index + 2}.0/24"
    compartment_id = var.compartment_ocid
    display_name = "k8s-private0${count.index + 1}"
    vcn_id = oci_core_vcn.k8s-vcn.id
    prohibit_public_ip_on_vnic = true
    route_table_id = oci_core_route_table.k8s-priv-rt.id
    security_list_ids = [oci_core_security_list.k8s-priv-sec-list.id]
}