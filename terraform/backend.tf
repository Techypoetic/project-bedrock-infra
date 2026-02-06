terraform {
  backend "s3" {
    bucket         = "project-bedrock-terraform-state-alt-soe-025-1162"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "project-bedrock-state-lock"
    encrypt        = true
  }
}
