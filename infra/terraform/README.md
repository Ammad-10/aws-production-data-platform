# Phase 2: Terraform infrastructure

Run all commands from the `infra/terraform` folder (or use full paths). Works in **PowerShell** and **Command Prompt**.

---

## IAM: give user Dune_2 access (admin steps)

As **admin**, give Dune_2 permission to run Terraform, use ECR, S3, EKS, etc.:

**Step 1 – Create a managed policy**

1. In AWS Console go to **IAM** → **Policies** (left menu) → **Create policy**.
2. Open the **JSON** tab, delete the default text, and paste the full contents of **`iam-policy-<your-project>-managed.json`** (in this folder). It includes EC2, EKS, EMR, IAM, S3, Glue, ECR.
3. Click **Next** → set **Policy name** to e.g. `TerraformDeploy` → **Create policy**.

**Step 2 – Attach the policy to Dune_2**

1. IAM → **Users** → open user **Dune_2**.
2. **Add permissions** → **Attach policies directly**.
3. Search for `TerraformDeploy` (or the name you used), tick it → **Add permissions**.

Dune_2 can then run `terraform plan/apply`, create ECR repos, and use the rest of the stack. To change what they can do later, edit the policy (Policies → TerraformDeploy → Edit).

---

## IAM: permissions for Terraform (user Dune_2)

AWS limits **inline** policies per user to **2048 non-whitespace characters total**. Use one of the following.

**Option A – Managed policy (recommended; ~380 chars, under 2048)**

You must **create a new policy** first, then **attach** it. Do **not** use “Create inline policy” on the user.

1. IAM → **Policies** (left menu) → **Create policy**.
2. **JSON** tab → delete the default text → paste the contents of **`iam-policy-<your-project>-managed.json`**.
3. **Next** → Policy name: `TerraformDeploy` → **Create policy**.
4. IAM → **Users** → **Dune_2** → **Add permissions** → **Attach policies directly** → search `TerraformDeploy` → check it → **Add permissions**.

**Option B – Inline only (if you must stay inline and have little space left)**

1. IAM → Users → Dune_2 → Add permissions → **Create inline policy** → JSON tab.
2. Paste the contents of **`iam-policy-<your-project>-inline-minimal.json`** (~380 chars; fixes `ec2:DescribeAvailabilityZones` so plan can run).
3. Save. Run `terraform plan`. For **apply** you will need more permissions; use Option A or add more inline (if under 2048 total).

---

## When to run Terraform

You **do not** run plan/apply after every phase. Run them like this:

| After you complete | What to run |
|--------------------|-------------|
| **Phase 2** (all Terraform modules and backend config) | `terraform init`, then `terraform plan` and `terraform apply` **once** — this creates VPC, EKS, S3, Glue, IAM. |
| **Phase 3** (Helm values, etc.) | No Terraform. Use `helm deploy` and `kubectl` **after** Terraform apply has created the EKS cluster. |
| **Phase 6** (full deploy) | Either run `scripts/deploy.sh` (which runs Terraform apply + Helm) or run Terraform only when you change `.tf` files. |

So: finish Phase 2 (code + backend), then run **init → plan → apply** once. Later, run apply again only when you change infrastructure.

---

## 2.1 Remote backend (first time)

**1. Create S3 bucket and DynamoDB table** (bucket: `<your-state-bucket>`, table: `<your-state-lock-table>`):

**PowerShell:**

```powershell
cd "<repo-root>\infra\terraform"

aws s3 mb s3://<your-state-bucket> --region us-east-1
aws s3api put-bucket-versioning --bucket <your-state-bucket> --versioning-configuration Status=Enabled

aws dynamodb create-table --table-name <your-state-lock-table> --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
```

**2. Copy backend config** (already set for <your-state-bucket> / <your-state-lock-table>):

**PowerShell:**

```powershell
Copy-Item env\backend-dev.hcl.example -Destination env\backend-dev.hcl
```

**Command Prompt (cmd):**

```cmd
copy env\backend-dev.hcl.example env\backend-dev.hcl
```

**3. Init Terraform with backend:**

```powershell
terraform init "-backend-config=env/backend-dev.hcl"
```

To use **local state** instead: comment out the `backend "s3" { ... }` block in `versions.tf`, then run `terraform init`.

---

## Apply fixes (region, EKS version, EMR)

- **Region:** Set to **ap-southeast-2** in `env/dev.tfvars` (S3 was expecting this region). If your Terraform state bucket is in another region, keep that region in `env/backend-dev.hcl` for `region` only.
- **EKS:** Cluster version set to **1.29** and node groups use **ami_type = "AL2_x86_64"** so the correct AMI is used.
- **EMR on EKS:** Set **use_emr_on_eks = false** in `env/dev.tfvars` to avoid the subscription error. Set back to `true` after enabling EMR on EKS in your account.

If you had a **partial apply in us-east-1**, clean up before re-applying in ap-southeast-2: temporarily set `aws_region = "us-east-1"` in `env/dev.tfvars`, run `terraform destroy -var-file="env/dev.tfvars" -auto-approve`, then set `aws_region = "ap-southeast-2"` again and run apply.

---

## Apply (then move to Phase 3)

Config is validated and planned (34 resources, us-east-1, no EMR). Run **one** of these from `infra/terraform`:

**Option A – Apply the saved plan (recommended):**
```powershell
terraform apply "tfplan"
```

**Option B – Plan and apply in one go:**
```powershell
terraform apply -var-file="env/dev.tfvars" -auto-approve
```

After you see **Apply complete!**, go to Phase 3:
```powershell
aws eks update-kubeconfig --region us-east-1 --name data-platform-dev
kubectl get nodes
```

---

## 2.9 Run (plan & apply)

**PowerShell or Command Prompt** (from `infra/terraform`):

```powershell
cd "<repo-root>\infra\terraform"

terraform plan -var-file="env/dev.tfvars"
terraform apply -var-file="env/dev.tfvars"
```

**First run with remote backend (full sequence):**

```powershell
cd "<repo-root>\infra\terraform"

terraform init "-backend-config=env/backend-dev.hcl"
terraform plan -var-file="env/dev.tfvars"
terraform apply -var-file="env/dev.tfvars"
```
