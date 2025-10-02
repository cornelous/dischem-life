provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Project     = "devops-assessment"
      Environment = var.env
      Owner       = var.owner
      ManagedBy   = "terraform"
    }
  }
}
