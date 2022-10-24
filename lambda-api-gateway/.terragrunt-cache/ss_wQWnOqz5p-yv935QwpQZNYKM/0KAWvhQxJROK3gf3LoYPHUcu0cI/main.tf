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
resource "random_pet" "gruntlab_lambda_bucket_name" {
  prefix = "cts"
  length = 4
}

resource "aws_s3_bucket" "gruntlab_lambda_bucket" {
  bucket = random_pet.gruntlab_lambda_bucket_name.id
  force_destroy = true
}

resource "aws_s3_bucket_acl" "gruntlab_lambda_bucket_acl" {
  bucket = aws_s3_bucket.gruntlab_lambda_bucket.id
  acl    = "private"
}


resource "aws_s3_bucket_public_access_block" "gruntlab_bucket_access" {
  bucket = aws_s3_bucket.gruntlab_lambda_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_s3_bucket_versioning" "gruntlab_versioning_lambda_bucket" {
  bucket = aws_s3_bucket.gruntlab_lambda_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

####################
# lambda section
####################

resource "aws_lambda_function" "gruntlab_http_any_function" {
  function_name = "gruntlab-http-any-function"
  s3_bucket = aws_s3_bucket.gruntlab_lambda_bucket.id
  s3_key    = aws_s3_bucket_object.gruntlab_lambda_object.key

  runtime = "nodejs16.x"
  handler = "index.handler"
  role = aws_iam_role.gruntlab_lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "gruntlab_lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.gruntlab_http_any_function.function_name}"
  retention_in_days = 30
}

# managed policy
resource "aws_iam_role" "gruntlab_lambda_exec" {
  name = "gruntlab-lambda-exec"

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

resource "aws_iam_role_policy_attachment" "gruntlab_lambda_policy" {
  role       = aws_iam_role.gruntlab_lambda_exec.name
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
        Action : [
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
        Resource : [
          "*",
        ],
        Effect : "Allow"
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "gruntlab_attach_custom_policy" {
  role       = aws_iam_role.gruntlab_lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}

# s3 object
data "archive_file" "gruntlab_archive_file" {
  type        = "zip"
  source_dir  = "${path.module}/gruntlab-lambda"
  output_path = "${path.module}/gruntlab-lambda.zip"
}

resource "aws_s3_bucket_object" "gruntlab_lambda_object" {
  bucket = aws_s3_bucket.gruntlab_lambda_bucket.id
  key    = "gruntlab-lambda.zip"
  source = data.archive_file.gruntlab_archive_file.output_path
  etag   = filemd5(data.archive_file.gruntlab_archive_file.output_path)
}

####################
# API GATEWAY section
####################

resource "aws_apigatewayv2_api" "gruntlab_apigw_api" {
  name          = "gruntlab-apigw-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "gruntlab_apigw_stage" {
  api_id = aws_apigatewayv2_api.gruntlab_apigw_api.id
  name        = "gruntlab-apigw-stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.gruntlab_api_gw_log_group.arn
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
resource "aws_apigatewayv2_integration" "gruntlab_apigw_int" {
  api_id = aws_apigatewayv2_api.gruntlab_apigw_api.id
  integration_uri        = aws_lambda_function.gruntlab_http_any_function.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"

}

resource "aws_apigatewayv2_route" "any_items" {
  api_id    = aws_apigatewayv2_api.gruntlab_apigw_api.id
  route_key = "ANY /v1/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.gruntlab_apigw_int.id}"
  depends_on = [
    aws_apigatewayv2_integration.gruntlab_apigw_int
  ]
}


# GET_ITEMS_WITH_ID
# resource "aws_apigatewayv2_integration" "get_item_by_type" {
#   api_id                 = aws_apigatewayv2_api.lambda.id
#   integration_uri        = aws_lambda_function.gruntlab.invoke_arn
#   integration_type       = "AWS_PROXY"
#   integration_method     = "POST"
#   payload_format_version = "2.0"
# }

# resource "aws_apigatewayv2_route" "get_item_by_type" {
#   depends_on = [
#     aws_apigatewayv2_integration.get_item_by_type
#   ]
#   api_id    = aws_apigatewayv2_api.lambda.id
#   route_key = "GET /v1/{type}/{category}"
#   target    = "integrations/${aws_apigatewayv2_integration.get_item_by_type.id}"
# }

# # PUT_ITEMS
# resource "aws_apigatewayv2_integration" "put_items" {
#   api_id                 = aws_apigatewayv2_api.lambda.id
#   integration_uri        = aws_lambda_function.gruntlab.invoke_arn
#   integration_type       = "AWS_PROXY"
#   integration_method     = "POST"
#   payload_format_version = "2.0"

# }

# resource "aws_apigatewayv2_route" "put_items" {
#   api_id    = aws_apigatewayv2_api.lambda.id
#   route_key = "PUT /v1/{type}/{category}"
#   target    = "integrations/${aws_apigatewayv2_integration.put_items.id}"
# }

# # # DELETE_ITEMS_WITH_ID
# resource "aws_apigatewayv2_integration" "delete_items" {
#   api_id                 = aws_apigatewayv2_api.lambda.id
#   integration_uri        = aws_lambda_function.gruntlab.invoke_arn
#   integration_type       = "AWS_PROXY"
#   integration_method     = "POST"
#   payload_format_version = "2.0"
# }

# resource "aws_apigatewayv2_route" "delete_items" {
#   api_id    = aws_apigatewayv2_api.lambda.id
#   route_key = "DELETE /v1/{type}/{category}"
#   target    = "integrations/${aws_apigatewayv2_integration.delete_items.id}"
# }

# CLOUDWATCH
resource "aws_cloudwatch_log_group" "gruntlab_api_gw_log_group" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.gruntlab_apigw_api.name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "gruntlab_api_gw_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gruntlab_http_any_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gruntlab_apigw_api.execution_arn}/*/*"
}
