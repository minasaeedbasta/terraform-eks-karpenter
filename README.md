# Modular EKS Terraform With Karpenter and Github Action Runners

This Terraform repository provides a modular approach to deploying an Amazon EKS (Elastic Kubernetes Service) cluster with Karpenter for node auto-scaling and GitHub Actions runners. The repository is structured into three main modules that need to be applied in a specific order:

1. **EKS Module**: Creates the EKS cluster and managed node groups
2. **Karpenter Module**: Sets up Karpenter for dynamic node provisioning
3. **Runners Module**: Deploys GitHub Actions runners

## Prerequisites

Before using this repository, ensure you have the following:

- AWS CLI installed and configured with appropriate credentials
- Terraform v1.0.0 or later installed
- kubectl installed for interacting with the Kubernetes cluster
- Helm v3 installed for deploying Kubernetes applications
- Access to an AWS VPC with appropriate subnets
- GitHub App credentials for the runners

## Repository Structure

```
terraform-eks-karpenter/
├── main.tf                 # Main Terraform configuration file
├── variables.tf            # Input variables for the root module
├── outputs.tf              # Output values from the root module
├── versions.tf             # Terraform and provider version constraints
├── modules/
│   ├── eks/                # EKS cluster module
│   ├── karpenter/          # Karpenter auto-scaling module
│   └── runners/            # GitHub Actions runners module
```

## Installation and Setup

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd terraform-eks-karpenter
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Create a `terraform.tfvars` file with your specific configuration values:
   ```hcl
   region                                  = "us-east-1"
   vpc_id                                  = "vpc-xxxxxxxxxxxxxxxxx"
   cluster_name                            = "my-eks-cluster"
   cluster_version                         = "1.32"
   instance_type                           = "t3.medium"
   karpenter_version                       = "1.1.2"
   default_nodepool_instance_type          = "t3.medium"
   runner_nodepool_instance_type           = "t3.medium"
   ssm_parameter_github_app_id             = "/github/app_id"
   ssm_parameter_github_app_installation_id = "/github/installation_id"
   ssm_parameter_github_app_private_key    = "/github/private_key"
   
   node_group_scaling = {
     desired_capacity = 2
     max_size         = 4
     min_size         = 2
   }
   
   tags = {
     Environment = "Production"
     Project     = "EKS-Cluster"
   }
   
   runner_parameters = {
     githubConfigUrl = "https://github.com/your-org/your-repo"
     minRunners      = 1
     maxRunners      = 10
     node-pool-name  = "github-runners"
     cpu             = "1"
     memory          = "2Gi"
   }
   
   apps = [
     {
       name      = "app1"
       namespace = "app1-ns"
       role_arn  = "arn:aws:iam::123456789012:role/app1-role"
     },
     {
       name      = "app2"
       namespace = "app2-ns"
       role_arn  = "arn:aws:iam::123456789012:role/app2-role"
     }
   ]
   
   cluster_admins = [
     {
       name     = "devops-team"
       role_arn = "arn:aws:iam::123456789012:role/devops-admin-role"
     }
   ]
   ```

## Deployment Process

The modules in this repository must be applied in a specific order due to dependencies between them:

### 0. Store GitHub App Credentials in Parameter Store

Before deploying any modules, you must manually store the GitHub App credentials in AWS Parameter Store as secure strings. This is a prerequisite for the runners module to work correctly.

```bash
# Store GitHub App ID
aws ssm put-parameter \
    --name "/github/app_id" \
    --value "YOUR_GITHUB_APP_ID" \
    --type "SecureString" \
    --overwrite

# Store GitHub App Installation ID
aws ssm put-parameter \
    --name "/github/installation_id" \
    --value "YOUR_GITHUB_APP_INSTALLATION_ID" \
    --type "SecureString" \
    --overwrite

# Store GitHub App Private Key
aws ssm put-parameter \
    --name "/github/private_key" \
    --value "YOUR_GITHUB_APP_PRIVATE_KEY" \
    --type "SecureString" \
    --overwrite
```

Make sure to replace:
- `/github/app_id` with your actual SSM parameter path for the GitHub App ID
- `/github/installation_id` with your actual SSM parameter path for the GitHub App Installation ID
- `/github/private_key` with your actual SSM parameter path for the GitHub App Private Key
- The corresponding values with your actual GitHub App credentials

These parameter paths should match the values you specify in your `terraform.tfvars` file for the variables:
- `ssm_parameter_github_app_id`
- `ssm_parameter_github_app_installation_id`
- `ssm_parameter_github_app_private_key`

### 1. Deploy the EKS Module First

```bash
terraform apply -target="module.eks"
```

This command will:
- Create the EKS cluster
- Set up the managed node groups
- Configure IAM roles and policies
- Set up the necessary AWS resources for Karpenter

Wait for the EKS cluster to be fully provisioned before proceeding to the next step.

### 2. Deploy the Karpenter Module

```bash
terraform apply -target="module.karpenter"
```

This command will:
- Install Karpenter in the EKS cluster
- Configure the EC2 node classes
- Set up the default node pool
- Set up the runners node pool

### 3. Deploy the Runners Module

```bash
terraform apply -target="module.runners"
```

This command will:
- Deploy GitHub Actions runners in the EKS cluster
- Configure the runners with the provided GitHub App credentials

> **Important**: The runners module will fail if the GitHub App credentials are not properly stored in Parameter Store before running this step. Make sure you've completed step 0 before proceeding to this step.

## Variable Explanations

### Core Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `region` | AWS region where resources will be deployed | string | "us-east-1" |
| `vpc_id` | ID of the VPC where the EKS cluster will be deployed | string | - |
| `cluster_name` | Name of the EKS cluster | string | "main" |
| `cluster_version` | Kubernetes version for the EKS cluster | string | "1.32" |
| `instance_type` | EC2 instance type for EKS worker nodes | string | "t3.medium" |
| `karpenter_version` | Version of Karpenter to use | string | "1.1.2" |
| `prefix` | Prefix for resource naming | string | "CIS" |
| `environment` | Environment name (e.g., Dev, Prod) | string | "Dev" |

### Scaling Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `node_group_scaling` | Scaling configuration for the EKS node group | map(number) | `{desired_capacity = 2, max_size = 2, min_size = 2}` |
| `default_nodepool_instance_type` | EC2 instance type for the default Karpenter node pool | string | "t3.medium" |
| `runner_nodepool_instance_type` | EC2 instance type for the runners node pool | string | "t3.medium" |

### Application Configuration

| Variable | Description | Type | Required |
|----------|-------------|------|----------|
| `apps` | List of applications with their namespaces and IAM roles | list(object) | Yes |
| `cluster_admins` | List of cluster administrators with their IAM roles | list(object) | No |

### GitHub Runners Configuration

| Variable | Description | Type | Required |
|----------|-------------|------|----------|
| `runner_parameters` | Configuration for GitHub Actions runners | object | Yes |
| `ssm_parameter_github_app_id` | SSM parameter path for GitHub App ID | string | Yes |
| `ssm_parameter_github_app_installation_id` | SSM parameter path for GitHub App Installation ID | string | Yes |
| `ssm_parameter_github_app_private_key` | SSM parameter path for GitHub App Private Key | string | Yes |

## Adding a New Application

When a new application needs to be added to the EKS cluster, the DevOps team should follow these steps:

1. Get the following information from the application team:
   - Application name
   - Desired Kubernetes namespace
   - IAM role ARN (provided by the organization's IAM team)

2. Add the new application to the `apps` variable in your `terraform.tfvars` file:
   ```hcl
   apps = [
     # Existing apps...
     {
       name      = "new-app-name"
       namespace = "new-app-namespace"
       role_arn  = "arn:aws:iam::123456789012:role/new-app-role"
     }
   ]
   ```

3. Apply the changes to update the EKS configuration:
   ```bash
   terraform apply -target="module.eks"
   ```

4. This will:
   - Create the new namespace if it doesn't exist
   - Configure the IAM role mapping for the application
   - Set up the necessary RBAC permissions

5. Verify the new application namespace and permissions:
   ```bash
   kubectl get namespace new-app-namespace
   kubectl describe configmap aws-auth -n kube-system
   ```

## Role Assumption for DevOps and Development Teams

### AWS CLI Role Assumption

Team members can assume their assigned IAM roles to access the EKS cluster or specific namespaces using the AWS CLI:

#### For DevOps Team (Cluster-wide Access)

```bash
# Assume the DevOps admin role
aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/devops-admin-role \
    --role-session-name EKSAdminSession

# Export the credentials
export AWS_ACCESS_KEY_ID="output_from_previous_command"
export AWS_SECRET_ACCESS_KEY="output_from_previous_command"
export AWS_SESSION_TOKEN="output_from_previous_command"

# Update kubeconfig
aws eks update-kubeconfig \
    --region us-east-1 \
    --name CIS-Dev-main-<suffix> \
    --role-arn arn:aws:iam::123456789012:role/devops-admin-role
```

#### For Application Teams (Namespace-specific Access)

```bash
# Assume the application-specific role
aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/app1-role \
    --role-session-name AppNamespaceSession

# Export the credentials
export AWS_ACCESS_KEY_ID="output_from_previous_command"
export AWS_SECRET_ACCESS_KEY="output_from_previous_command"
export AWS_SESSION_TOKEN="output_from_previous_command"

# Update kubeconfig
aws eks update-kubeconfig \
    --region us-east-1 \
    --name CIS-Dev-main-<suffix> \
    --role-arn arn:aws:iam::123456789012:role/app1-role
```

### AWS Console Role Switching

Team members can also use the AWS Console to switch roles:

1. Log in to the AWS Console with your IAM user credentials
2. Click on your username in the top-right corner
3. Select "Switch Role"
4. Enter the following information:
   - Account: 123456789012 (your AWS account number)
   - Role: devops-admin-role (for DevOps team) or app1-role (for app teams)
   - Display Name: EKS Admin (or any name you prefer)
5. Click "Switch Role"
6. You can now access the EKS console and other AWS services with the permissions of the assumed role

> **Note**: Replace `123456789012` with your actual AWS account number and role names with your actual IAM role names.

## Information for Application Developers

After the DevOps team creates a new application namespace and configures the necessary roles, they should provide the following information to the application development team:

### Essential Information for App Developers

1. **Cluster Information**:
   - Cluster name: `CIS-Dev-main-<suffix>`
   - Kubernetes version: `1.32`
   - AWS Region: `us-east-1` (or your configured region)

2. **Namespace Information**:
   - Namespace name: `app1-ns` (specific to their application)
   - Resource quotas and limits (if configured)

3. **Access Information**:
   - IAM Role ARN: `arn:aws:iam::123456789012:role/app1-role`
   - Instructions for assuming the role (see above)
   - Instructions for configuring kubectl with the role

4. **Deployment Guidelines**:
   - Any cluster-specific requirements for deployments
   - Node selector or affinity requirements (if any)
   - Resource request and limit recommendations
   - Network policy information

5. **Monitoring and Logging**:
   - How to access logs for their namespace
   - Monitoring dashboards available for their application
   - Alerting configuration instructions

### Example kubectl Configuration Instructions

Provide these instructions to app developers:

```bash
# Assume the application-specific role
aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/app1-role \
    --role-session-name AppNamespaceSession

# Export the credentials
export AWS_ACCESS_KEY_ID="output_from_previous_command"
export AWS_SECRET_ACCESS_KEY="output_from_previous_command"
export AWS_SESSION_TOKEN="output_from_previous_command"

# Update kubeconfig
aws eks update-kubeconfig \
    --region us-east-1 \
    --name CIS-Dev-main-<suffix> \
    --role-arn arn:aws:iam::123456789012:role/app1-role

# Verify access to the namespace
kubectl get pods -n app1-ns
```

### Example Deployment YAML

Provide a sample deployment YAML that follows best practices for the cluster:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: app1-ns
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: nginx:latest
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        ports:
        - containerPort: 80
```

## Troubleshooting

### Common Issues

1. **EKS Cluster Creation Fails**:
   - Verify that the VPC and subnets exist and are properly configured
   - Check IAM permissions for the Terraform executor

2. **Karpenter Installation Fails**:
   - Ensure the EKS cluster is fully provisioned before applying the Karpenter module
   - Verify that the EKS cluster has the necessary IAM roles for Karpenter

3. **Runners Deployment Fails**:
   - Check that the GitHub App credentials are correctly stored in SSM Parameter Store
   - Verify that the Karpenter node pool for runners is properly configured

### Getting Help

For additional assistance, please contact the DevOps team or refer to the internal documentation.
