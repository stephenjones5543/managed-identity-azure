#help to access k8s cluster
provider "helm" {
    kubernetes {
        config_path = kube_config_raw
    }
}

resource "helm_release" "pod_identity" {
  name = var.pod_identity_name
  chart = var.pod_identity_chart
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  timeout = 1200

}