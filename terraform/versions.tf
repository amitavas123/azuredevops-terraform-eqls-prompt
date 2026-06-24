terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend configuration for remote state (configured via backend config during init)
  # Example: terraform init -backend-config="key=terraform.tfstate"
  backend "azurerm" {
    # These values should be provided via backend-config flags or environment variables:
    # ARM_STORAGE_ACCOUNT_NAME, ARM_STORAGE_ACCOUNT_KEY, or ARM_SAS_TOKEN
    # container_name = "tfstate"
    # key            = "terraform.tfstate"
  }
}
