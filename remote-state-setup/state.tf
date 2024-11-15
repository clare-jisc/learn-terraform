# 2nd step AFTER the resources below are created is to update with the remote backend settings
# terraform {
#   backend "s3" {
#     bucket         = "clare-sdg-training-tf-remote-state"
#     key            = "global/s3/terraform.tfstate"
#     region         = "eu-west-2"
#     dynamodb_table = "clare-sdg-training-tf-remote-state-lock-table"
#     encrypt       = true
#   }
# }
# Step 3 - remove/comment out the backend block from the state.tf file

# 1st step - This configuration is used to create an S3 bucket to store the terraform remote state file
# and a DynamoDB table to store the remote state lock

# Configure the Terraform AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "eu-west-2"
  profile = "sdg-training-sso"
}

# Create an S3 bucket to store the remote state
# Step 4 - change lifecycle prevent_destroy to false from initial true
resource "aws_s3_bucket" "tf_remote_state_bucket" {
  bucket = "clare-sdg-training-tf-remote-state"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "tf_remote_state_bucket_versioning" {
  bucket = aws_s3_bucket.tf_remote_state_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_remote_state_bucket_ss_encryption_config" {
  bucket = aws_s3_bucket.tf_remote_state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable public access block on the S3 bucket
resource "aws_s3_bucket_public_access_block" "tf_remote_state_bucket_public_access_block" {
  bucket = aws_s3_bucket.tf_remote_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create a DynamoDB table to store the remote state lock
resource "aws_dynamodb_table" "tf_remote_state_lock_table" {
  name           = "clare-sdg-training-tf-remote-state-lock-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

