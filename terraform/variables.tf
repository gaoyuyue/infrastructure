variable "location" {
  type        = string
  description = "The Azure location where all resources in this project should be created"
}

variable "github_pat" {
  type        = string
  description = "The Github Personal Access Token"
}