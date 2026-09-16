variable "required_tag_key" {
  description = "Tag key every EC2 instance must carry; instances without it get stopped"
  type        = string
  default     = "Project"
}

variable "dry_run" {
  description = "When true, the enforcer only logs what it would stop"
  type        = bool
  default     = true
}

variable "snapshot_retention_days" {
  description = "Snapshots older than this many days are deleted"
  type        = number
  default     = 7
}

variable "report_email" {
  description = "Recipient of the daily cost report"
  type        = string
  default     = "hello@adedayoafolabi.com"
}