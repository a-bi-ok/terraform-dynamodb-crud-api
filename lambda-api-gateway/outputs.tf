# Output value definitions

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store function code."

  value = aws_s3_bucket.gruntlab_lambda_bucket.id
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.gruntlab_http_any_function.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."
  value = aws_apigatewayv2_stage.gruntlab_apigw_stage.invoke_url
}

