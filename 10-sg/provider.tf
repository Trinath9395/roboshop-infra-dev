terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.11.0"
    }
  }

  backend "s3" {
  bucket = "82-remote-state-pr-prod"
  key = "expense-dev-infra-pr"
  region = "us-east-1"
  use_lockfile = false
 }

}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}