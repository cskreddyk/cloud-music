variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudmusic"
}

variable "services" {
  description = "CloudMusic container repositories"
  type        = set(string)

  default = [
    "frontend",
    "api-gateway",
    "auth-service",
    "user-service",
    "catalog-service",
    "streaming-service",
    "playlist-service",
    "search-service",
    "recommendation-service",
    "favourites-service",
    "history-service",
    "notification-service",
    "admin-service"
  ]
}
