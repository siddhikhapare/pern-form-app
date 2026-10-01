
## Folder Structure

```

├── main.tf                 # Root module: wires all child modules together
├── variables.tf            # Root input variables
├── outputs.tf              # Root outputs
├── provider.tf             # Default AWS provider + us-east-1 alias (CloudFront ACM)
├── backend.tf              # Remote state (S3) configuration
├── terraform.tfvars        # Environment values (do NOT commit secrets)
│
├── vpc/                    # VPC, public / private-app / private-db subnets, IGW, NAT, routes
├── security-group/         # Bastion, external ALB, internal ALB, web, app, RDS SGs
├── bastion-host/           # Bastion EC2 in public subnet (SSH entry point)
├── LB/                     # External ALB (public) + Internal ALB (private) + target groups
├── rds/                    # RDS subnet group + DB instance
├── ami/                    # Builds base instances and bakes custom Web / App AMIs, IAM instance profile
├── web-asg/                # Web launch template + ASG + alarms/notifications
├── app-asg/                # App launch template + ASG (injects DB config) + alarms
└── cdn/                    # CloudFront distribution + Route 53 records
```

### Module dependency graph
```
vpc
  → security_group
      → rds        (parallel with ...)
      → LB + bastion   (parallel, both only need security_group + vpc)
          → ami    (needs alb.internal_alb_dns_name)
              → web_asg   (needs ami + alb)
              → app_asg   (needs ami + alb + rds)
                  → cdn   (needs alb — actually just needs alb, not app_asg)
```

## Remote State: Why S3?

### The problem with local state
By default Terraform stores state in `terraform.tfstate` on your laptop. That breaks down quickly:

- **No sharing** – teammates or CI can't see what already exists, so they try to recreate it.
- **No locking** – two `terraform apply` runs at once can corrupt state.
- **No history / recovery** – if the state file is deleted, Terraform loses track of the existing AWS resources, leaving them unmanaged. With S3 versioning, a previous state version can be restored.

### State locking

A lock is taken before any operation that writes state (`plan`/`apply`/`destroy`) and released afterwards. If someone else holds it, Terraform stops with `Error acquiring the state lock` instead of corrupting state.

### Recommended `backend.tf`

```hcl
terraform {
  backend "s3" {
    bucket       = "<your-bucket-created-in-console>"
    key          = "formapp/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true      
  }
}
```

### Bucket checklist (created via console)
- [x] **Versioning** enabled
- [x] **Default encryption** enabled (SSE-S3 or SSE-KMS)
- [x] **Block all public access** on
- [x] Region matches `region` in the backend block (`ap-south-1`)
- [x] IAM user/role has `s3:ListBucket` on the bucket and `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on the state key and the `.tflock` key


## Commands 

### 1. Initialize Terraform

Initialize Terraform and connect to the S3 backend:

```bash
terraform init
```

### 2. Check formatting and validity

Format the Terraform configuration and validate it:

```bash
terraform fmt -recursive
terraform validate
```

### 3. Review the plan

Create and review the Terraform execution plan:

```bash
terraform plan -out=tfplan
```

### 4. Apply the configuration

Apply the previously generated plan:

```bash
terraform apply tfplan
```

### 5. Inspect Terraform state and outputs

List the resources currently tracked in the Terraform state:

```bash
terraform state list
```

Display the Terraform outputs:

```bash
terraform output
```

### 6. Visualize the dependency graph

Generate a PNG image of the Terraform resource dependency graph:

```bash
terraform graph | dot -Tpng > graph.png
```

### 7. Tear down the infrastructure

> **Warning:** This destroys the infrastructure managed by Terraform. RDS deletion protection may prevent the RDS instance from being deleted. Check snapshot of it.

```bash
terraform destroy
```

Building a new environment step by step. For example, create module.vpc first, because other parts need things that don't exist yet.
Fixing a problem in production. For example, change one security group or retry a failed apply, when the full plan has other changes you don't want to apply right now.

```
1.terraform plan  -target=module.vpc -out=vpc.tfplan
2. terraform apply vpc.tfplan
```
Several modules at once:
```
terraform apply -target=module.vpc -target=module.security_group
```

single resource inside a module:
```
terraform apply -target=module.rds.aws_db_instance.main
```

Destroy one module:
```
terraform destroy -target=module.cdn
```






