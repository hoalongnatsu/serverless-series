provider "aws" {
  region = "us-west-2"
}

locals {
  names = ["list", "get", "create", "update", "delete"]
}

resource "aws_lambda_function" "function" {
  for_each      = toset(local.names)
  function_name = "books_${each.value}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main"
  runtime       = "go1.x"

  filename         = "source/${each.value}.zip"
  source_code_hash = filebase64sha256("source/${each.value}.zip")
}

resource "aws_api_gateway_rest_api" "books" {
  name = "books-api"
}

resource "aws_api_gateway_resource" "books" {
  rest_api_id = aws_api_gateway_rest_api.books.id
  parent_id   = aws_api_gateway_rest_api.books.root_resource_id
  path_part   = "books"
}

resource "aws_api_gateway_method" "books" {
  rest_api_id   = aws_api_gateway_rest_api.books.id
  resource_id   = aws_api_gateway_resource.books.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "books" {
  depends_on = [
    aws_lambda_function.function
  ]

  for_each    = toset(["list", "create", "update", "delete"])
  rest_api_id = aws_api_gateway_rest_api.books.id
  resource_id = aws_api_gateway_resource.books.id
  http_method = aws_api_gateway_method.books.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function[each.value].invoke_arn
}

resource "aws_api_gateway_resource" "books_proxy" {
  rest_api_id = aws_api_gateway_rest_api.books.id
  parent_id   = aws_api_gateway_resource.books.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "books_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.books.id
  resource_id   = aws_api_gateway_resource.books_proxy.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "books_proxy" {
  rest_api_id = aws_api_gateway_rest_api.books.id
  resource_id = aws_api_gateway_resource.books_proxy.id
  http_method = aws_api_gateway_method.books_proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function["get"].invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.books,
    aws_api_gateway_integration.books_proxy,
  ]

  rest_api_id = aws_api_gateway_rest_api.books.id
  stage_name  = "staging"
}

resource "aws_lambda_permission" "apigw" {
  for_each      = toset(local.names)
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[each.value].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.books.execution_arn}/*/*"
}

output "base_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}
