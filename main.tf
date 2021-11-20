terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.86.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.6.1"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

resource "random_pet" "prefix" {
  
}

# Create azure resource group
resource "azurerm_resource_group" "erget" {
  name                  = "erget"
  location              = "eastus"
}

resource "azurerm_kubernetes_cluster" "erget" {
  name                  = "${random_pet.prefix.id}-aks"
  location              = azurerm_resource_group.erget.location
  resource_group_name   = azurerm_resource_group.erget.name
  dns_prefix            = "ergetaks"

  default_node_pool {
    name                = "ergi"
    node_count          = 2
    vm_size             = "Standard_D2_v2"
    os_disk_size_gb     = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled             = true
  } 

  tags = {
    environment         = "AKS"
  }
}

provider "kubernetes" {
  config_path           = "~/.kube/config"
}

resource "kubernetes_namespace" "testenv" {
  metadata {
    name                = "testenv"
  }
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name                = "quiz-backend-update"
  }
  spec {
    replicas            = 2
    selector {
      match_labels = {
        app             = "quiz-backend-update"
      }
    }
    template {
      metadata {
          labels = {
            app = "quiz-backend-update"
          }
      }
      spec {
        container {
          image         = "kontetsu/backend-update:v1"
          image_pull_policy = "Always"
          name          = "quiz-backend-update"
          port {
            container_port = 8080
            name = "http"
            protocol = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backendservice" {
  metadata {
    name = "quiz-backend-update"
  }
  spec {
    port {
      port = 8080
      protocol = "TCP"
      target_port = 8080
    }
    selector = {
      app = "quiz-backend-update"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name = "frontend"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "frontend"
      }
    }
    template {
      metadata {
        labels = {
            app = "frontend"
        }
      }
      spec {
        container {
          image = "kontetsu/frontend-update:v1"
          image_pull_policy = "Always"
          name = "frontend"
          port {
            container_port = 80
            protocol = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name = "frontend"
  }
  spec {
    port {
      port = 80
      protocol = "TCP"
      target_port = 80
    }
    selector = {
      app  = "frontend"
    }
    type = "ClusterIP"
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.15.2"
  namespace  = "hello-world-namespace"
  timeout    = 300

  values = [<<EOF
controller:
  admissionWebhooks:
    enabled: false
  electionID: ingress-controller-leader-internal
  ingressClass: nginx-hello-world-namespace
  podLabels:
    app: ingress-nginx
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
  scope:
    enabled: true
rbac:
  scope: true
EOF
  ]
}


resource "kubernetes_ingress" "ingress" {
  metadata {
      labels = {
        app = "ingress-nginx"
      }
    name = "ingress-front-back-update"
    namespace = "testenv"
    annotations = {
        "kubernetes.io/ingress.class": "testenv"
    }
  }
  spec {
    rule {
      http {
        path {
          path = "/?(.*)"
          backend {
            service_name = "frontend"
            service_port = 80
          }
        }
        path {
          path = "/api/quiz/select?(.*)"
          backend {
            service_name = "quiz-backend-update"
            service_port = 8080
          }
        }
      }
    }
  }
}

