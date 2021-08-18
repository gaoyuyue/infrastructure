#SHELL := /bin/bash

secrets_path:=.github/secrets
encrypt:
	gpg --symmetric --cipher-algo AES256 "$(secrets_path)/sp.secret"
decrypt:
	gpg --quiet --batch --yes --decrypt --passphrase="$(LARGE_SECRET_PASSPHRASE)" --output "$(secrets_path)/sp.secret" "$(secrets_path)/sp.secret.gpg"
create_sp:
	az ad sp create-for-rbac --role="Owner"
setup:
	az group create --name tf4rg --location eastus2
	az storage account create -n tf4sa -g tf4rg -l eastus2 --sku Standard_LRS
	az storage container create -n tfstate --account-name tf4sa

aks_path:=terraform/aks
tf_aks_fmt:
	cd $(aks_path) && terraform fmt -check
tf_aks_validate:
	cd $(aks_path) && terraform validate -no-color
tf_aks_init:
	cd $(aks_path) && terraform init -backend-config=backend.hcl
tf_aks_plan:
	cd $(aks_path) && terraform plan -var-file main.tfvars -no-color
tf_aks_apply: 
	cd $(aks_path) && terraform apply -var-file main.tfvars -auto-approve -no-color
tf_aks_destroy: 
	cd $(aks_path) && terraform destroy -var-file main.tfvars -auto-approve -no-color