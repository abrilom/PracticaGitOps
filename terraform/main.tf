terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "abril-s3"
    key = "terraform.tfstate"
    region = "us-west-2"
    encrypt = true
    
  }
}
