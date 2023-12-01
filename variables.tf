#variable "aws_pg_db_name" {
#  type        = string
#  default = "admindb"
#}
#
#variable "aws_pg_allocated_storage" {
#  type        = number
#  default = 20
#}
#
#variable "aws_pg_engine" {
#    type = string
#    default = "postgres"
#}
#
#variable "aws_pg_engine_version" {
#    type = string
#    default = "14.4"
#}
#
#variable "aws_pg_instance_class" {
#    type = string
#    default = "db.t3.micro"
#}
#
#variable "aws_pg_username"{
#    type = string
#    default = "demouser"
#}
#
#variable "aws_pg_password" {
#  type = string
#  default= "Democloud123"
#} # remover

variable "aws_region" {
  default = "us-east-1"
}

variable "vpc-cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  type = map(number)
  default = {
    public  = 2,
    private = 2,
  }
}

variable "settings" {
  type = map(any)
  default = {
    "database" = {
      allocated_storage   = 10,
      engine              = "mysql",
      engine_version      = "8.0.33"
      instance_class      = "db.t2.micro"
      db_name             = "ProjetoCloudRDS"
      skip_final_snapshot = true
    },
    "django_app" = {
      count         = 2,
      instance_type = "t2.micro"
    }
  }
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
  ]
}

variable "private_subnet_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24",
  ]
}

variable "my_ip" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
