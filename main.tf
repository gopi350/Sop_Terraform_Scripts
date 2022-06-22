//organization: Sonata software Limited
//developed by: Devops-team
//code : all resources integration
//created on : 29-05-2022



//creating a network with the name VPC

resource "google_compute_network" "net" {
  name = "vpc"
auto_create_subnetworks = false
}

//creating a subnet with name "subnet" and range "10.0.0.0/16"

resource "google_compute_subnetwork" "subnet" {
  name          = "subnetwork"
  network       = google_compute_network.net.id
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
}

//creating a firewall with name "vpc_firewall" allowing 80,22,1000-2000 ports

resource "google_compute_firewall" "net" {
  name    = "vpc-firewall"
network = google_compute_network.net.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "1000-2000"]
  }

  source_tags = ["web"]
}

//creating the cloud router "myrouter" and assinging ASN number

resource "google_compute_router" "router" {
  name    = "my-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.net.id

  bgp {
    asn = 64514
  }
}

//creating NAT service in a router

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

//****************************************************
//********************* VPC_PEERING*******************
//****************************************************

resource "google_compute_network_peering_routes_config" "peering_primary_routes" {
  peering = google_compute_network_peering.peering_primary.name
  network = google_compute_network.network_primary.name

  import_custom_routes = true
  export_custom_routes = true
}

//enabling the peering between "primary-network" and "secondary-network" like (1&2)

resource "google_compute_network_peering" "peering_primary" {
  name         = "primary-peering"
  network      = google_compute_network.network_primary.id
  peer_network = google_compute_network.network_secondary.id

  import_custom_routes = true
  export_custom_routes = true
}

//enabling the peering between  "secondary-network" and "primary-network" like (2&1)
resource "google_compute_network_peering" "peering_secondary" {
  name         = "secondary-peering"
  network      = google_compute_network.network_secondary.id
  peer_network = google_compute_network.network_primary.id
}

//creating a vpc network with name "primary-network"

resource "google_compute_network" "network_primary" {
  name                    = "primary-network"
  auto_create_subnetworks = "false"
}

//creating a vpc network with name "secondary-network"

resource "google_compute_network" "network_secondary" {
  name                    = "secondary-network"
  auto_create_subnetworks = "false"
}

//creating VM_INSTANCE 
//***************************************************
//********* VM_INSTANCE******************************
//***************************************************

resource "google_compute_instance""terraform-instance"{
    
    provider= google-beta    // if u want to create image vm should be created in google-beta only 
    name="debian-9"
    zone="us-central1-a"
    machine_type = "f1-micro"
    //creating network tag as [web]
    tags=["web"]

    //creating debian flavoured os
    boot_disk {
      initialize_params {
          image="debian-cloud/debian-9"
      }
    }

    network_interface {
      subnetwork = google_compute_subnetwork.subnet.id
      access_config {
             // empherimal-ip
      }
    }




}

//***************************************************
//******************* MACHINE_IMAGE *****************
//***************************************************

// This resource is in beta, and should be used with the terraform-provider-google-beta provider.
resource "google_compute_machine_image" "image" {
  provider = google-beta
  name            = "first-machine-image"
  source_instance = google_compute_instance.terraform-instance.self_link
}
//**********************************************
//****************** PERSISTANT_DISK ***********
//**********************************************

// it will craete the 30GB blank peesistant disk
resource "google_compute_disk" "persistant-disk1" {
  name  = "debian9-disk1"
  type  = "pd-ssd"
  zone  = "us-central1-a"
  image = "debian-9-stretch-v20200805"
  size =30
  physical_block_size_bytes = 4096
}

//********************************************
//**************** PD_SNAPSHOT ***************
//********************************************

resource "google_compute_snapshot" "pd-snapshot" {
  name        = "my-snapshot"
  source_disk = google_compute_disk.persistant-disk1.id
  zone        = "us-central1-a"
  storage_locations = ["us-central1"]
}


//*******************************************
//************** CLOUD_STORAGE **************
//*******************************************


// creating the bucket in regional storage calss 

resource "google_storage_bucket" "bucket"  {
  name          = "gcp_bucket_0522"
  storage_class = "STANDARD"
  location      = "us-central1"
  force_destroy = true

  uniform_bucket_level_access = true
}


//****************************************
//************* SQL_DATABASE**************
//****************************************

resource "google_sql_database" "database" {
  name     = var.sql_db_name
  instance = google_sql_database_instance.instance.name
}

# See versions at https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#database_version
resource "google_sql_database_instance" "instance" {
  name             = var.sql_db_instance_name
  region           = "us-central1"
  database_version = "MYSQL_8_0"
  settings {
    tier = "db-f1-micro"
  }

  deletion_protection  = "false"
} 
//*************************************************
// ****************** REDIS_INSTANCE **************
//*************************************************

resource "google_redis_instance" "cache" {
  name           = "ha-memory-cache"
  tier           = "STANDARD_HA"
  memory_size_gb = 1

  location_id             = "us-central1-a"
  alternative_location_id = "us-central1-f"

  redis_version     = "REDIS_4_0"
  display_name      = "Terraform Test Instance"
  reserved_ip_range = "192.168.0.0/29"

  maintenance_policy {
    weekly_maintenance_window {
      day = "TUESDAY"
      start_time {
        hours = 0
        minutes = 30
        seconds = 0
        nanos = 0
      }
    }
  }
}
//**********************************************************
//*********************** IAM_ROLE**************************
//**********************************************************

resource "google_project_iam_custom_role" "my-custom-role" {
  provider = google-beta
  role_id     = "myCustomRole"
  title       = "My Custom Role"
  description = "A description"
  permissions = ["iam.roles.list", "iam.roles.create", "iam.roles.delete"]
}

//*********************************************************
//******************** IAM_MEMBER *************************
//*********************************************************


resource "google_project_iam_member" "project" {
  provider = google-beta


  project = "tokyo-dynamo-349216"
  role    = "roles/editor"
  member  = "user:gopikrishnadbda17@gmail.com"
}

//*********************************************************
//****************** CDN **********************************
//*********************************************************


resource "google_compute_backend_bucket" "image_backend" {
  name        = "sonata-backend-bucket"
  description = "Contains beautiful images"
  bucket_name = google_storage_bucket.image_bucket.name
  enable_cdn  = true
}

resource "google_storage_bucket" "image_bucket" {
  name     = "sonata-store-bucket"
  location = "us-central1"
}


//********************************************************
//******************** BIG_QUERY ******************************
//********************************************************
resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = "example_dataset"
  friendly_name               = "test"
  description                 = "This is a test description"
  location                    = "asia-south1"
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }

}
//***********************************************************
//******************* BIG_TABLE_INSTANCE ********************
//***********************************************************


resource "google_bigtable_instance" "instance" {
  name = "tf-instance"
   deletion_protection=false

  cluster {
    cluster_id   = "tf-instance-cluster"
    zone         = "us-central1-a"
    num_nodes    = 3
    storage_type = "HDD"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_bigtable_table" "table" {
  name          = "tf-table"
  instance_name = google_bigtable_instance.instance.name
  split_keys    = ["a", "b", "c"]

  lifecycle {
    prevent_destroy = false
  }
}