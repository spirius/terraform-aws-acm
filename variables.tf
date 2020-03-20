variable "domains" {
  description = "List of domains and zones IDs."

  type = list(object({
    domain  = string
    zone_id = string
  }))
}

variable "tags" {
  description = "Tags"
  default     = {}
  type        = map(string)
}

variable "validation_record_ttl" {
  description = "Route53 validation record TTL."
  default     = 3600
}
