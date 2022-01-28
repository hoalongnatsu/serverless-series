resource "aws_api_gateway_rest_api" "books" {
  name = "books-api"

  binary_media_types = [
    "multipart/form-data",
    "*/*"
  ]
}

resource "aws_api_gateway_resource" "books" {
  rest_api_id = aws_api_gateway_rest_api.books.id
  parent_id   = aws_api_gateway_rest_api.books.root_resource_id
  path_part   = "books"
}

resource "aws_api_gateway_method" "books_list" {
  rest_api_id   = aws_api_gateway_rest_api.books.id
  resource_id   = aws_api_gateway_resource.books.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "books_list" {
  rest_api_id = aws_api_gateway_rest_api.books.id
  resource_id = aws_api_gateway_resource.books.id
  http_method = aws_api_gateway_method.books_list.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function_list.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.books_list,
  ]

  rest_api_id = aws_api_gateway_rest_api.books.id
  stage_name  = "staging"
}