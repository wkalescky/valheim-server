variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "cf_zone_id" {
  description = "Cloudflare zone ID for DNS registration"
  type        = string
}

variable "cf_domain" {
  description = "Base domain for per-world DNS records (e.g. costcovalheim.net → dedicated.costcovalheim.net)"
  type        = string
}
