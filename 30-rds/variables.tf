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

variable "zone_id" {
  default = "Z04937802OYFAGU4M6BTX"
}

variable "domain_name" {
    default = "trianth.online"
}