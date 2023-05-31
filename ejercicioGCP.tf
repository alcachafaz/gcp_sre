# main.tf

# Configuración del proveedor de GCP
provider "google" {
  credentials = file("<ruta_archivo_credenciales>")
  project     = "<nombre_proyecto>"
  region      = "us-central1"
}

# Creación de la red y subred por defecto
resource "google_compute_network" "default_network" {
  name                    = "default-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default_subnetwork" {
  name          = "default-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.default_network.self_link
  region        = "us-central1"
}

# Creación del Cloud Load Balancer
resource "google_compute_global_forwarding_rule" "load_balancer" {
  name       = "load-balancer"
  target     = google_compute_backend_service.backend_service.self_link
  port_range = "80"
}

resource "google_compute_backend_service" "backend_service" {
  name        = "backend-service"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.instance_group.self_link
  }
}

# Creación de Cloud DNS
resource "google_dns_managed_zone" "dns_zone" {
  name        = "dns-zone"
  dns_name    = "example.com."
  description = "Managed DNS Zone"
}

resource "google_dns_record_set" "dns_record" {
  name         = "www"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.dns_zone.name
  rrdatas      = ["<dirección_ip_load_balancer>"]
}

# Creación del Bastion con imagen Debian y SSH public key
resource "google_compute_instance" "bastion" {
  name         = "bastion-host"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  tags         = ["bastion"]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }
  
  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {
      nat_ip = google_compute_address.bastion_ip.address
    }
  }
  
  metadata = {
    ssh-keys = "your-public-key"
  }
}

# Creación firewall bastion
resource "google_compute_firewall" "bastion_firewall" {
  name        = "bastion-firewall"
  network     = google_compute_network.vpc.self_link
  target_tags = ["bastion"]
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["your-ip-range"]
}


# Creación del GKE Cluster
resource "google_container_cluster" "gke_cluster" {
  name     = "gke-cluster"
  location = "us-central1-a"
  initial_node_count = 3

  # Configuración adicional para el cluster GKE
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  node_config {
    preemptible  = true
    machine_type = "n1-standard-2"
    disk_size_gb = 10

    # Etiquetas adicionales para los nodos
    labels = {
      environment = "production"
      project     = "my-project"
    }

    # Configuración de red para los nodos
    network_tags = ["gke-node"]

    # Configuración adicional de seguridad
    service_account = "my-service-account@my-project.iam.gserviceaccount.com"
    oauth_scopes    = ["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/cloud-platform"]
  }
}

# Creación del Container Registry
resource "google_container_registry_repository" "container_repository" {
  name = "container-repository"
}

# Creación de Cloud SQL (PostgreSQL)
resource "google_sql_database_instance" "cloudsql_instance" {
  name             = "cloudsql-instance"
  database_version = "POSTGRES_13"
  region           = "us-central1"
 
}



