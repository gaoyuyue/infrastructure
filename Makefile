#SHELL := /bin/bash

encrypt:
	gpg --symmetric --cipher-algo AES256 .github/scripts/set_secrets.sh
decrypt:
	gpg --quiet --batch --yes --decrypt --passphrase="$(LARGE_SECRET_PASSPHRASE)" --output .github/scripts/set_secrets.sh .github/scripts/set_secrets.sh.gpg
	sh .github/scripts/set_secrets.sh
create_sp:
	az ad sp create-for-rbac --role="Contributor"
setup:
	az group create --name tf4rg --location eastus2
	az storage account create -n tf4sa -g tf4rg -l eastus2 --sku Standard_LRS
	az storage container create -n tfstate --account-name tf4sa
plan:
	terraform plan -var-file main.tfvars -no-color
apply: 
	terraform apply -var-file main.tfvars -auto-approve -no-color
destroy: 
	terraform destroy -var-file main.tfvars -auto-approve -no-color