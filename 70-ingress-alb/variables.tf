variable "project_name" {
    default = "roboshop"
}

variable "environment" {
    default = "dev"
}

variable "common_tags" {
    default = {
        Project = "roboshop"
        Environment = "dev"
        Terraform = "true"
    }
}

variable "domain_name" {
    default = "trinath.online"
}

variable "zone_id" {
  default = "Z04937802OYFAGU4M6BTX"
}