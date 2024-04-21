data "local_file" "init-master" {
  filename = "scripts/master.sh"
}

data "local_file" "init-worker" {
    filename = "scripts/worker.sh"

    depends_on = [ 
        oci_core_instance.k8s-master
    ]
}