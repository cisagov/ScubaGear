# ScubaGear in AWS GovCloud (Deployment Guide)

> **Scope:** This guide assists teams in deploying ScubaGear in AWS GovCloud (US) with least-privilege IAM configuration, optional Security Hub integration, and FedRAMP-aligned operational practices.  
> This document provides educational reference material and does **not** constitute official compliance or authorization guidance.

---

## 1. Prerequisites

- AWS GovCloud (US) account with appropriate access (role-based; avoid long-lived keys).
- Python 3.8 or later and Git installed on the workstation.
- Network egress to AWS APIs from the execution environment.
- Use **temporary roles** rather than permanent credentials.
- Windows example shown; macOS/Linux follow the same steps with shell syntax adjustments.

---

## 2. Installation (Windows Example)

```powershell
python -m venv .venv
. .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m scubagear --version
```

---

## 3. Running ScubaGear in GovCloud

```powershell
$Env:AWS_DEFAULT_REGION="us-gov-west-1"
python -m scubagear scan --output .\results\scan_$(Get-Date -Format "yyyyMMdd_HHmm").json
python -m scubagear report --input .\results\scan_*.json --format html --out .\results\report.html
```

---

## 4. Least-Privilege IAM Policy (Baseline Example)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "iam:Get*",
        "iam:List*",
        "config:Describe*",
        "config:Get*",
        "securityhub:Get*",
        "securityhub:List*",
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    }
  ]
}
```

> **Recommendation:** Narrow permissions to specific ARNs and use `Condition` elements (for example, `aws:RequestedRegion`) to enforce least privilege in production environments.

---

## 5. Optional — Send Findings to AWS Security Hub

```python
# example_securityhub.py
import boto3, json
sh = boto3.client("securityhub", region_name="us-gov-west-1")
with open("results/scan_latest.json") as f:
    findings = json.load(f)[:50]  # sample subset for testing
sh.batch_import_findings(Findings=findings)
```

> Ensure the IAM role includes `securityhub:BatchImportFindings` and that your findings follow the AWS Security Hub schema.

---

## 6. FedRAMP-Relevant Operational Practices

| FedRAMP Control                   | Example Application                                                  |
| --------------------------------- | -------------------------------------------------------------------- |
| **AC-2 – Account Management**     | Apply least-privilege access and lifecycle management for IAM roles. |
| **AU-6 – Audit Review**           | Retain JSON/HTML outputs; integrate with SIEM for audit visibility.  |
| **CM-6 – Configuration Settings** | Version-control ScubaGear configurations and runtime parameters.     |
| **RA-5 – Vulnerability Scanning** | Incorporate scan results into risk assessments and POA&M updates.    |

> This section highlights how ScubaGear data may support common FedRAMP controls. Organizations must validate mappings within their own authorization boundary and documentation (SSP, POA&M, etc.).

---

## 7. Troubleshooting

- **AuthFailed** – Verify that your session is active and the `AWS_DEFAULT_REGION` variable is set to a GovCloud region.
- **AccessDenied** – Confirm role permissions and resource scoping.
- **Missing Output** – Ensure output directories exist and have write permissions.

---

## 8. References

- [AWS GovCloud (US) User Guide](https://docs.aws.amazon.com/govcloud-us/index.html)
- [AWS Security Hub User Guide](https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html)
- [FedRAMP Baselines](https://www.fedramp.gov/baselines/)
