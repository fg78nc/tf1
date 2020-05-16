locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type = string
}

variable "server_port" {
  description = "Port of the web server"
  type = number
  default = 8080
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket used for the database's remote state storage"
  type = string
  default = "terraform-state-bucket-fg78nc-2"
}

variable "db_remote_state_key" {
  description = "The name of the key in the S3 bucket used for the database's remote state storage"
  type = string
  default = "stage/services/data-stores/mysql/terraform.tfstate"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "min_size" {
  type = number
  default = 1
}

variable "max_size" {
  type = number
  default = 2
}