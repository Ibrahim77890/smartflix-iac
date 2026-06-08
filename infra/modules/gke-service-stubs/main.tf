resource "kubernetes_namespace_v1" "namespaces" {
  for_each = var.services

  metadata {
    name = each.key
    labels = {
      app = each.key
      env = var.environment
    }
  }
}

resource "kubernetes_service_account_v1" "service_accounts" {
  for_each = var.services

  metadata {
    name      = each.value.kubernetes_service_account
    namespace = kubernetes_namespace_v1.namespaces[each.key].metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = var.gcp_service_account_emails[each.value.gcp_service_account_key]
    }
  }
}

resource "kubernetes_config_map_v1" "catalog_stub" {
  count = contains(keys(var.services), "catalog") ? 1 : 0

  metadata {
    name      = "catalog-static-content"
    namespace = kubernetes_namespace_v1.namespaces["catalog"].metadata[0].name
  }

  data = {
    "index.json" = jsonencode({
      environment = var.environment
      catalog = [
        {
          id    = "movie-001"
          title = "Terraforming the Streams"
        },
        {
          id    = "series-042"
          title = "Autopilot Nights"
        }
      ]
    })
  }
}

resource "kubernetes_deployment_v1" "catalog" {
  count = contains(keys(var.services), "catalog") ? 1 : 0

  metadata {
    name      = "catalog-service"
    namespace = kubernetes_namespace_v1.namespaces["catalog"].metadata[0].name
    labels = {
      app = "catalog-service"
    }
  }

  spec {
    replicas = var.services["catalog"].replicas

    selector {
      match_labels = {
        app = "catalog-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "catalog-service"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.service_accounts["catalog"].metadata[0].name

        container {
          name  = "nginx"
          image = var.services["catalog"].image

          port {
            container_port = 80
          }

          resources {
            limits = var.services["catalog"].limits
          }

          volume_mount {
            name       = "catalog-content"
            mount_path = "/usr/share/nginx/html/index.json"
            sub_path   = "index.json"
          }
        }

        volume {
          name = "catalog-content"

          config_map {
            name = kubernetes_config_map_v1.catalog_stub[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "catalog" {
  count = contains(keys(var.services), "catalog") ? 1 : 0

  metadata {
    name      = "catalog-service"
    namespace = kubernetes_namespace_v1.namespaces["catalog"].metadata[0].name
  }

  spec {
    selector = {
      app = "catalog-service"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "stream" {
  count = contains(keys(var.services), "stream") ? 1 : 0

  metadata {
    name      = "stream-service"
    namespace = kubernetes_namespace_v1.namespaces["stream"].metadata[0].name
    labels = {
      app = "stream-service"
    }
  }

  spec {
    replicas = var.services["stream"].replicas

    selector {
      match_labels = {
        app = "stream-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "stream-service"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.service_accounts["stream"].metadata[0].name

        container {
          name  = "grafana"
          image = var.services["stream"].image

          env {
            name  = "GF_AUTH_ANONYMOUS_ENABLED"
            value = "true"
          }

          env {
            name  = "GF_AUTH_DISABLE_LOGIN_FORM"
            value = "true"
          }

          port {
            container_port = 3000
          }

          resources {
            limits = var.services["stream"].limits
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "stream" {
  count = contains(keys(var.services), "stream") ? 1 : 0

  metadata {
    name      = "stream-service"
    namespace = kubernetes_namespace_v1.namespaces["stream"].metadata[0].name
  }

  spec {
    selector = {
      app = "stream-service"
    }

    port {
      port        = 3000
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "recommendation" {
  count = contains(keys(var.services), "recommendation") ? 1 : 0

  metadata {
    name      = "recommendation-service"
    namespace = kubernetes_namespace_v1.namespaces["recommendation"].metadata[0].name
    labels = {
      app = "recommendation-service"
    }
  }

  spec {
    replicas = var.services["recommendation"].replicas

    selector {
      match_labels = {
        app = "recommendation-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "recommendation-service"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.service_accounts["recommendation"].metadata[0].name

        container {
          name  = "recommendation"
          image = var.services["recommendation"].image
          args  = ["-text=${var.services["recommendation"].response_text}", "-listen=:5678"]

          port {
            container_port = 5678
          }

          resources {
            limits = var.services["recommendation"].limits
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "recommendation" {
  count = contains(keys(var.services), "recommendation") ? 1 : 0

  metadata {
    name      = "recommendation-service"
    namespace = kubernetes_namespace_v1.namespaces["recommendation"].metadata[0].name
  }

  spec {
    selector = {
      app = "recommendation-service"
    }

    port {
      port        = 5678
      target_port = 5678
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "auth_placeholder" {
  count = var.deploy_keycloak ? 0 : 1

  metadata {
    name      = "auth-service"
    namespace = kubernetes_namespace_v1.namespaces["auth"].metadata[0].name
    labels = {
      app = "auth-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "auth-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "auth-service"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.service_accounts["auth"].metadata[0].name

        container {
          name  = "auth-placeholder"
          image = "nginx:alpine"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "auth_placeholder" {
  count = var.deploy_keycloak ? 0 : 1

  metadata {
    name      = "auth-service"
    namespace = kubernetes_namespace_v1.namespaces["auth"].metadata[0].name
  }

  spec {
    selector = {
      app = "auth-service"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "helm_release" "keycloak" {
  count      = var.deploy_keycloak ? 1 : 0
  name       = "auth-service"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"
  version    = var.keycloak_chart_version
  namespace  = kubernetes_namespace_v1.namespaces["auth"].metadata[0].name

  set {
    name  = "auth.adminUser"
    value = var.keycloak_admin_user
  }

  set_sensitive {
    name  = "auth.adminPassword"
    value = var.keycloak_admin_password
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.service_accounts["auth"].metadata[0].name
  }
}
