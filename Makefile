.PHONY: all plan apply destroy

# the most important line in any shell script
SHELL := $(SHELL) -e

# use to print variable contents from the command line, eg: 'make print-SHELL'
print-%: ; @echo $*=$($*)


all: plan apply

plan:
	terraform get -update
	terraform plan -var-file terraform.tfvars -out terraform.tfplan

apply:
	terraform apply -var-file terraform.tfvars

destroy:
	terraform plan -destroy -var-file terraform.tfvars -out terraform.tfplan
	terraform apply terraform.tfplan

clean:
	rm -f terraform.tfplan
	rm -f terraform.tfstate
	@rm -f graph.png

test:
	./scripts/testPlan

graph:
	terraform graph | dot -T png > graph.png
