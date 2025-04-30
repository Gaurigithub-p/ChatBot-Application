
terraform {
  backend "s3" {
    bucket = "chatbot-bucket9152" # Replace with your actual S3 bucket name
    key    = "project/infra/terraform.tfstate"
    region = "ap-south-1"
  }
}
