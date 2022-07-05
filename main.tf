provider "aws" {
  region = var.region
}
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  force_destroy = var.bucket_force_destroy
  versioning {
    enabled = var.bucket_versioning
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.bucket_encryption_algorithm
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls   = var.bucket_public_access_block_public_acls
  block_public_policy = var.bucket_public_access_block_public_policy
  ignore_public_acls = var.bucket_public_access_ignore_public_acls
  restrict_public_buckets =  var.bucket_public_access_restrict_public_buckets
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = var.dynamodb_table_billing_mode
  hash_key     = var.dynamodb_table_hash_key
  attribute {
    name = var.dynamodb_table_attribute_name
    type = var.dynamodb_table_attribute_type
  }
}