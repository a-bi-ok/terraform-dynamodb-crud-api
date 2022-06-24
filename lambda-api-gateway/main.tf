terraform {
  backend "s3" {}
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.19.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}


provider "aws" {
  region = var.aws_region
}

####################
# s3 section
####################
resource "random_pet" "lambda_bucket_name" {
  prefix = "test-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
  acl           = "private"
  force_destroy = true
}


####################
# lambda section
####################

resource "aws_lambda_function" "gruntlab" {
  function_name = "http-crud-function"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_bucket_object.lambda_gruntlab.key

  runtime = "nodejs14.x"
  handler = "index.handler"

  # source_code_hash = data.archive_file.lambda_gruntlab.output_base64sha256
  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "gruntlab" {
  name = "/aws/lambda/${aws_lambda_function.gruntlab.function_name}"

  retention_in_days = 30
}

# managed policy

resource "aws_iam_role" "lambda_exec" {
  name = "gruntlab_serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#custom policy

resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = "LambdaDynamodbExecution"
  path        = "/"
  description = "Lambda dynamodb access policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action: [
                "dynamodb:GetItem",
                "dynamodb:DeleteItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:UpdateItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:BatchGetItem",
                "dynamodb:DescribeTable",
                "dynamodb:ConditionCheckItem"
            ],
            Resource: [
                "*",
            ],
            Effect: "Allow"
        }
      
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach-custom-policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}

# s3 object
data "archive_file" "lambda_gruntlab" {
  type = "zip"

  source_dir  = "${path.module}/gruntlab-lambda"
  output_path = "${path.module}/gruntlab-lambda.zip"
}

resource "aws_s3_bucket_object" "lambda_gruntlab" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "gruntlab-lambda.zip"
  source = data.archive_file.lambda_gruntlab.output_path
  etag = filemd5(data.archive_file.lambda_gruntlab.output_path)
}

####################
# API GATEWAY section
####################

resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

# --INTEGRATIONS--
# GET_ITEMS
resource "aws_apigatewayv2_integration" "get_items" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.gruntlab.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "get_items" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /items"
  target    = "integrations/${aws_apigatewayv2_integration.get_items.id}"
}

# GET_ITEMS_WITH_ID
resource "aws_apigatewayv2_integration" "get_items_with_id" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.gruntlab.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "get_items_with_id" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.get_items_with_id.id}"
}

# PUT_ITEMS

resource "aws_apigatewayv2_integration" "put_items" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.gruntlab.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "put_items" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "PUT /items"
  target    = "integrations/${aws_apigatewayv2_integration.put_items.id}"
}

# # DELETE_ITEMS_WITH_ID
resource "aws_apigatewayv2_integration" "delete_items" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.gruntlab.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "delete_items" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "DELETE /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_items.id}"
}

# CLOUDWATCH
resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gruntlab.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

