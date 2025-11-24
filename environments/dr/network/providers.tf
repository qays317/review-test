terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}


