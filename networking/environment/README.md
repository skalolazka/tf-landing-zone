# Environment resources creation

Should be run after the hub creation and with the specific file for the environment variables ([How to run Terraform with a variables file](https://www.terraform.io/docs/cli/commands/plan.html#var-file-filename)).

For example:
```
terraform apply -var-file dev.tfvars
```

Please consult the networking/hub folder to be sure to match values.