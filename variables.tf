variable "region" {
    type = string 
    default = "us-east-1"
}

#----- AWS S3 Bucket section BEGIN ------
variable "bucket_name" {
    type = string
    default = "docker-project-bucket"
}
variable "bucket_force_destroy" {
    type = bool
    default = true
}
variable "bucket_versioning" {
    type = bool
    default = true
}
variable "bucket_encryption_algorithm" {
    type = string
    default = "AES256"
}
#----- AWS S3 Bucket section END ------

#----- AWS S3 Bucket Public Access Policy Block section BEGIN ------

variable "bucket_public_access_block_public_acls" {
    type = bool
    default = true
}
variable "bucket_public_access_block_public_policy" {
    type = bool
    default = true
}
variable "bucket_public_access_ignore_public_acls" {
    type = bool
    default = true
}
variable "bucket_public_access_restrict_public_buckets" {
    type = bool
    default = true
}

#----- AWS S3 Bucket Public Access Policy Block section END ------

#----- AWS DynamoDB Table section BEGIN ------
variable "dynamodb_table_name" {
    type = string
    default = "docker-project-locks"
}
variable "dynamodb_table_billing_mode" {
    type = string
    default = "PAY_PER_REQUEST"
}
variable "dynamodb_table_hash_key" {
    type = string
    default = "LockID"
}
variable "dynamodb_table_attribute_name" {
    type = string
    default = "LockID"
}
variable "dynamodb_table_attribute_type" {
    type = string
    default = "S"
}
#----- AWS DynamoDB Table section END ------