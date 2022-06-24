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
  hash_key       = "Id"
  range_key      = "Item"

  attribute {
    name = "Id"
    type = "S"
  }

  attribute {
    name = "Item"
    type = "S"
  }

  attribute {
    name = "Price"
    type = "N"
  }

  # ttl {
  #   attribute_name = "TimeToExist"
  #   enabled        = false
  # }

  global_secondary_index {
    name               = "ItemIndex"
    hash_key           = "Item"
    range_key          = "Price"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["Id"]
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "development"
  }
}
