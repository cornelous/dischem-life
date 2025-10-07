TF_DIR=terraform
TFVARS=tfvars/dev.auto.tfvars

.PHONY: init plan apply destroy fmt validate

init:
	cd $(TF_DIR) && terraform init

plan:
	cd $(TF_DIR) && terraform plan -var-file=../$(TFVARS)

apply:
	cd $(TF_DIR) && terraform apply -var-file=../$(TFVARS) -auto-approve

destroy:
	cd $(TF_DIR) && terraform destroy -var-file=../$(TFVARS)

fmt:
	cd $(TF_DIR) && terraform fmt -recursive

validate:
	cd $(TF_DIR) && terraform validate
