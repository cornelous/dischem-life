# Using local backend for now. For team use, uncomment and fill in your S3 bucket:
# terraform {
#   backend "s3" {
#     bucket         = "YOUR-TF-STATE-BUCKET"
#     key            = "devops-assessment/terraform.tfstate"
#     region         = "af-south-1"
#     dynamodb_table = "YOUR-TF-LOCK-TABLE"  # for state locking
#     encrypt        = true
#   }
# }
