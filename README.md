# AWS ACM Certificate Terraform module

Terraform module which creates AWS ACM Certificate and validation Route53 records.

In some environments the route53 records might be in other AWS account, therfore module
requires `providers` attribute to be defined for certificate and for route53 records separately.

## Usage

### Route53 zone of records belongs to the same AWS account

```hcl
module "acm" {
  source  = "spirius/aws/acm"
  version = "~> 2.0"

  providers = {
    aws         = aws
    aws.route53 = aws
  }

  domains = [
    {
      domain = "example.com"
      zone_id = "XXX"
    },
    {
      domain = "*.example.com"
      zone_id = "XXX"
    },
    {
      domain = "otherdomain.com"
      zone_id = "YYY"
    }
  ]
}
```

### Route53 zone of records belongs to the another AWS account

```hcl
provider "aws" {
  alias = "second"
}

module "acm" {
  source  = "spirius/aws/acm"
  version = "~> 2.0"

  providers = {
    aws         = aws
    aws.route53 = aws.second
  }

  domains = [
    {
      domain = "example.com"
      zone_id = "XXX"
    }
  ]
}
```
