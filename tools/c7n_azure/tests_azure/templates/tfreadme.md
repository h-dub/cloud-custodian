Terraform ports of the arm templates can be found in named subdirectories

2 variables are currently needed. You can put them in a file named terraform.tfvars for terraform to autoload, or use commandline switches to send them in.

location = "westus2"
suffix   = "fafbee1d5b39"


To deploy a resource:
* az login to set creds
* "terraform plan" - show what changes terraform would apply
* "terraform apply" - create resources / apply changes
* "terraform destroy" - destroy resources