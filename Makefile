#SHELL := /bin/bash

environments_path:=.github/environments
encrypt:
	gpg --symmetric --cipher-algo AES256 "$(environments_path)/terraform.env"
decrypt:
	gpg --quiet --batch --yes --decrypt --passphrase="$(LARGE_SECRET_PASSPHRASE)" --output "$(environments_path)/terraform.env" "$(environments_path)/terraform.env.gpg"
create_sp:
	az ad sp create-for-rbac --role="Owner"
setup:
	az group create --name tf4rg --location eastus2
	az storage account create -n tf4sa -g tf4rg -l eastus2 --sku Standard_LRS
	az storage container create -n tfstate --account-name tf4sa

terraform_path:=terraform
tf_fmt:
	cd $(terraform_path) && terraform fmt -check
tf_validate:
	cd $(terraform_path) && terraform validate -no-color
tf_init:
	cd $(terraform_path) && terraform init -backend-config=backend.hcl
tf_plan:
	cd $(terraform_path) && terraform plan -var-file main.tfvars -no-color
tf_apply: 
	cd $(terraform_path) && terraform apply -var-file main.tfvars -auto-approve -no-color
tf_destroy: 
	cd $(terraform_path) && terraform destroy -var-file main.tfvars -auto-approve -no-color