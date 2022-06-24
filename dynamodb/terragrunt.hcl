terraform {
  source = "../dynamodb"
}

include {
    path = "../terragrunt-include/terragrunt.hcl"
}

# dependencies {
#     paths = ["../vpc-sg"]
# }
