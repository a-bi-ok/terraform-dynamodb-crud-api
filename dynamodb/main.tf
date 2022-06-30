terraform {
  backend "s3" {
  }


}

provider "aws" {
  region     = var.aws_region
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


resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "http-crud-tutorial-items"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"
  range_key      = "item"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "item"
    type = "S"
  }

  attribute {
    name = "price"
    type = "N"
  }

  # ttl {
  #   attribute_name = "TimeToExist"
  #   enabled        = false
  # }

  global_secondary_index {
    name               = "ItemIndex"
    hash_key           = "item"
    range_key          = "price"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["id"]
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "development"
  }
}
