# Terraform AWS Multi-Environment Deployment with Terraform Cloud

This guide will walk you through setting up multiple environments (`dev`, `qa`, `prod`) using Terraform Cloud and deploying your AWS infrastructure across these environments. We'll create workspaces, configure AWS credentials in Terraform Cloud, and deploy the infrastructure step by step.

## Architecture Diagram

<img src="https://github.com/gitkailash/aws-wordpress-terraform-setup/blob/master/Terraform-multi-env-deployment.jpg" alt="Architecture Diagram"/>

---

## Project Overview

This project demonstrates how to use Terraform Cloud for deploying AWS infrastructure across different environments: `dev`, `qa`, and `prod`. Each environment is isolated using Terraform workspaces, allowing for cleaner infrastructure management and safe deployments across different stages of development.

You will:
1. Create Terraform Cloud workspaces for different environments.
2. Set up AWS credentials for secure resource provisioning.
3. Use Terraform CLI and Terraform Cloud to manage infrastructure across multiple environments.

---

## Prerequisites

Before you begin, ensure you have the following:

1. [Terraform CLI](https://www.terraform.io/downloads.html) installed on your local machine.
2. A [Terraform Cloud](https://app.terraform.io) account.
3. AWS credentials (Access Key, Secret Access Key) with the necessary permissions to create AWS resources.
4. Basic knowledge of Terraform and AWS resource provisioning.

---

## Steps to Implement

### Step 1: Create Workspaces in Terraform Cloud

Log in to your [Terraform Cloud](https://app.terraform.io) account and create three separate workspaces:

1. `dev`
2. `qa`
3. `prod`

### How to Create Workspaces:
1. Go to your organization.
2. Navigate to the "Workspaces" tab.
3. Click on **Create a new workspace**.
4. Name the workspaces `dev`, `qa`, and `prod`.

---

### Step 2: Add AWS Credentials as Variables in Terraform Cloud

For each workspace (`dev`, `qa`, `prod`), add your AWS credentials.

1. Go to the workspace.
2. Click on **Variables**.
3. Add the following environment variables under the "Environment Variables" section:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

Be sure to check the **Sensitive** checkbox when adding secret values to protect sensitive information.

---

### Step 3: Set Up Terraform Cloud Token Locally

1. Log in to your Terraform Cloud account via the CLI by running:
    ```bash
    terraform login
    ```

2. Enter your Terraform Cloud token when prompted. You can find this token in your Terraform Cloud account under **User Settings > Tokens**.

3. **Set your environment variable for the workspace**. Start with `dev`:
    ```bash
    export TF_WORKSPACE=dev
    ```

---

### Step 4: Initialize and Apply Terraform Configuration

#### Initialize Terraform:
Run the following commands to initialize the configuration for the `dev` environment:

```bash
terraform init
```
#### Validate the infrastructure:
Validate the infrastructure in the `dev` workspace:

```bash
terraform validate
```

#### Plan and Apply:
Generate a plan and deploy the infrastructure in the `dev` workspace:

```bash
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

#### Check Application:
After a successful deployment, check the application by inspecting the output for the ALB DNS name:

```
alb_dns_name: "app-loadbalancer-16052524787.us-east-1.elb.amazonaws.com"
```

---

### Step 5: Switch to Another Workspace and Deploy

After deploying the `dev` environment, switch to `qa` and `prod` workspaces and repeat the process.

#### Switch to `qa` Workspace:
```bash
export TF_WORKSPACE=qa
```

#### Do same for other QA and PROD environment:
  - `Goto: Step 4`
  - `Repeat it`

## Step 6: Destroy the Infrastructure

To clean up and destroy the resources in each environment, follow the steps below:

#### Destroy in `dev`:
```bash
export TF_WORKSPACE=dev
terraform destroy -auto-approve
```

#### Destroy in `qa`:
```bash
export TF_WORKSPACE=qa
terraform destroy -auto-approve
```

#### Destroy in `prod`:
```bash
export TF_WORKSPACE=prod
terraform destroy -auto-approve
```

---

## Troubleshooting

### 1. Workspace Issues
- **Error: Missing workspace mapping strategy**: If you encounter an error related to workspaces, ensure that you've correctly set the `TF_WORKSPACE` environment variable before running any Terraform commands.

### 2. AWS Credential Errors
- **Error: Invalid AWS credentials**: Verify that the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correctly set in the Terraform Cloud workspace's environment variables section.

### 3. Terraform Cloud Authentication
- **Error: Terraform Cloud login failed**: Ensure that you've logged into Terraform Cloud using the CLI (`terraform login`) and have the correct API token configured.

---

## Don’t Forget to Delete Everything After Testing

Oh, and let’s not forget the golden rule of cloud cost management—make sure to delete all your AWS resources after testing. Unless, of course, you absolutely adore seeing unexpected charges on your bill 💸. After all, who doesn’t love a little surprise at the end of the month, right? 🎉 

Just remember, the cloud is not your personal storage locker; every resource comes with a price tag. Your wallet will thank you for the clean-up! So, go ahead and run those commands to destroy everything like it’s your job:

#### Destroy Resources in All Environments:
```bash
export TF_WORKSPACE=dev && terraform destroy -auto-approve
export TF_WORKSPACE=qa && terraform destroy -auto-approve
export TF_WORKSPACE=prod && terraform destroy -auto-approve
```

And once the infrastructure is all gone, feel free to manually delete those Terraform workspaces from Terraform Cloud—because who wouldn’t want to double-check that everything is truly obliterated? Happy deleting! 🧹

--- 

## Conclusion

By following this guide, you've successfully deployed and managed AWS resources across multiple environments using Terraform Cloud. You’ve also learned how to handle workspaces, manage AWS credentials, and automate infrastructure provisioning with Terraform.
```
