terraform {
  required_version = "~> 1.0"

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0, < 6"

      configuration_aliases = [aws, aws.route53]
    }
  }
}
