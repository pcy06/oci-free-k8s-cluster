data "oci_core_images" "ubuntu-20-04-arm" {
    compartment_id = var.compartment_ocid
    operating_system = "Canonical Ubuntu"
    filter {
        name   = "display_name"
        values = ["^Canonical-Ubuntu-20.04-aarch64-([\\.0-9-]+)$"]
        regex = true
    }
}

data "oci_core_images" "ubuntu-22-04-arm" {
    compartment_id = var.compartment_ocid
    operating_system = "Canonical Ubuntu"
    filter {
        name   = "display_name"
        values = ["^Canonical-Ubuntu-22.04-aarch64-([\\.0-9-]+)$"]
        regex = true
    }
}