# Testing & Pre-Checkin Notes — GovCloud Deployment Docs Contribution

## 1) Pre-Checkin Checklist

- [ ] Markdown format passes (`mdformat`) on Windows.
- [ ] All external links resolve (GovCloud guide, Security Hub, FedRAMP baselines).
- [ ] No secrets/credentials in commands or screenshots.
- [ ] File added under `docs/` and linked from README (or docs index).
- [ ] Commit uses sign-off (`-s`) and conventional style: `docs: ...`.

### Run locally (Windows PowerShell)

```powershell
pip install mdformat
mdformat docs/govcloud-deployment.md docs/requirements.md
```

## 2) Manual Test Cases (Workstation Smoke Tests)

**Environment:** Windows 11, Python 3.11, PowerShell 5.1, GovCloud account.

**TC-01 Version Check**

- Steps: Create venv, install, run `python -m scubagear --version`.
- Expected: Version string prints (e.g., `ScubaGear x.y.z`).

**TC-02 GovCloud Scan**

- Steps:
  ```powershell
  $Env:AWS_DEFAULT_REGION="us-gov-west-1"
  python -m scubagear scan --output .\results\scan_$(Get-Date -Format "yyyyMMdd_HHmm").json
  ```
- Expected: A JSON results file appears under `.\results\`.

**TC-03 Report Generation**

- Steps:
  ```powershell
  python -m scubagear report --input .\results\scan_*.json --format html --out .\results\report.html
  ```
- Expected: `report.html` generated; opens in browser.

**TC-04 (Optional) Security Hub Ingestion**

- Pre: IAM allows `securityhub:BatchImportFindings`.
- Steps: Run `example_securityhub.py` from the guide with a small subset.
- Expected: API call succeeds (HTTP 200 in CloudTrail/SecurityHub metrics or no exception).

## 3) Troubleshooting Log (fill during testing)

- [ ] Auth issues → confirm role session + region env var.
- [ ] AccessDenied → scope policy to required services/resources; retry TC-02.
- [ ] Missing output → verify `results/` write permissions; retry TC-03.

## 4) Evidence for Assignment Submission

Attach or link the following screenshots:

- A. `git remote -v` (origin + upstream).
- B. Issue you opened (“GovCloud/FedRAMP deployment documentation”).
- C. Branch name in terminal: `docs/issue-1845-govcloud-docs`.
- D. `git status` showing changed docs.
- E. PR page (Conversation tab) + Files changed diff.
- F. Terminal outputs for TC-01..TC-03.
- G. (Optional) Security Hub ingestion success or no-error run.

## 5) Deployment Note

- This is a docs-only contribution. “Deployment” consists of PR approval and merge to `main`, after which the documentation is available in the repository.
