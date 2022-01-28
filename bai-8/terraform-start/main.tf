provider "aws" {
  region = "us-west-2"
}

locals {
  s3_origin_id = "access-identity-serverless-series-spa"
}

output "base_url" {
  value = {
    api = aws_api_gateway_deployment.deployment.invoke_url
    web = aws_s3_bucket.serverless_series_spa.website_endpoint
  }
}
