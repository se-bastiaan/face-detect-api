variable "prefix" {
  type = string
}

variable "bucket" {
  type = string
}

variable "package_name" {
  type = string
}

variable "install_dependencies" {
  type    = bool
  default = false
}

variable "tags" {
  type = map(string)
}