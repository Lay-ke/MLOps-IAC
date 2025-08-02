# Key Pair Module

This module creates EC2 key pairs for SSH access to instances.

## Recommended Workflow

### **Step 1: Generate SSH Key Pair Locally**
```bash
# Generate your SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/my-key-pair

# This creates:
# ~/.ssh/my-key-pair (private key - keep secure!)
# ~/.ssh/my-key-pair.pub (public key - safe to share)
```

### **Step 2: Create Key Pair in AWS**
```bash
# Option A: Using AWS CLI
aws ec2 import-key-pair \
  --key-name "my-key-pair" \
  --public-key-material fileb://~/.ssh/my-key-pair.pub

# Option B: Using AWS Console
# 1. Go to EC2 → Key Pairs
# 2. Click "Create key pair"
# 3. Choose "Import key pair"
# 4. Paste your public key content
```

### **Step 3: Use Existing Key Pair (Recommended)**
```hcl
# Don't create a key pair, use an existing one
module "key_pair" {
  source = "./modules/key-pair"
  
  create_key_pair = false
  key_name        = "my-key-pair"  # Your existing key pair name
  tags = {
    Environment = "production"
  }
}
```

## Alternative: Let Terraform Create Key Pair

### **Step 1: Generate SSH Key Pair Locally**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/my-key-pair
```

### **Step 2: Create New Key Pair with Terraform**
```hcl
# Create a new key pair
module "key_pair" {
  source = "./modules/key-pair"
  
  create_key_pair = true
  key_name        = "my-new-key-pair"
  public_key      = file("~/.ssh/my-key-pair.pub")  # Read from local file
  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_key_pair | Whether to create a new key pair in AWS (set to false to use existing key pair) | `bool` | `false` | no |
| key_name | Name of the key pair (existing or to be created) | `string` | n/a | yes |
| public_key | Public key content from your local SSH key file (e.g., ~/.ssh/id_rsa.pub). Required only if create_key_pair = true | `string` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key_pair_name | Name of the created key pair |
| key_pair_id | ID of the created key pair |
| key_pair_arn | ARN of the created key pair |

## Security Best Practices

1. **Use existing key pairs** when possible - they're typically managed outside of Terraform
2. **Store private keys securely** - never commit them to version control
3. **Use key rotation** - regularly update your SSH keys
4. **Limit key pair scope** - use different keys for different environments
5. **Keep private keys local** - never upload private keys to AWS or Terraform

## Example with EC2 Module

```hcl
# Option 1: Use existing key pair (Recommended)
module "ec2" {
  source = "./modules/ec2"
  
  key_name = "my-existing-key-pair"  # Your existing key pair name
  # ... other EC2 configuration
}

# Option 2: Create key pair and use with EC2
module "key_pair" {
  source = "./modules/key-pair"
  
  create_key_pair = true
  key_name        = "my-key-pair"
  public_key      = file("~/.ssh/id_rsa.pub")
}

module "ec2" {
  source = "./modules/ec2"
  
  key_name = module.key_pair.key_pair_name
  # ... other EC2 configuration
}
``` 