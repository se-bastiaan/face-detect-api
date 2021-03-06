variable "name" {
  type = string
}

variable "bucket" {
  type = string
}

variable "prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "api_gateway_arn" {
  type = string
}

variable "attach_policy_statements" {
  type    = bool
  default = false
}

variable "policy_statements" {
  type    = any
  default = {}
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
  default     = []
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 256
}
