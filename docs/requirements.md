# Requirements & Use-Cases — GovCloud Deployment Docs Contribution

## 1) Goals

- Provide a clear, minimal **AWS GovCloud (US)** deployment guide for ScubaGear.
- Offer a **baseline least-privilege IAM** example that teams can harden.
- Show an **optional Security Hub ingestion** pattern.
- Clarify **FedRAMP-aligned operational practices** without making compliance claims.

## 2) User Stories

- **US-01** — _As a federal contractor engineer_, I want a concise GovCloud deployment guide, so I can run ScubaGear within our authorization boundary.
- **US-02** — _As a security analyst_, I want a sample Security Hub ingestion, so I can centralize findings in our tooling.
- **US-03** — _As a compliance lead_, I want FedRAMP-relevant practices called out, so I can map outputs into our SSP/POA&M.

## 3) Use Case (UC-01: Run ScubaGear in GovCloud)

**Primary Actor:** Engineer  
**Preconditions:** Role-based access in `us-gov-west-1` or `us-gov-east-1`; Python + Git installed; network egress allowed.  
**Main Flow:**

1. Set GovCloud region environment variable.
2. Create venv; install requirements; verify `python -m scubagear --version`.
3. Run `scan` to produce JSON results.
4. Generate HTML report from results.
5. Archive outputs to controlled storage.
   **Alternate Flows:**

- **AF-01 AccessDenied:** Adjust IAM baseline (scope ARNs/Conditions) → re-run step 3.
- **AF-02 No Output:** Fix path/permissions → re-run report generation.

## 4) Information & Relationships (ER-style, textual)

- **Run** produces **Output** _(JSON, HTML)_.
- **Output** may be transformed into **SecurityHubFinding** entries.
- **Role** grants **Permission** to perform AWS actions (governed by policy).
- **Configuration** (env vars/flags) constrains **Run** behavior and storage paths.

## 5) Non-Functional Requirements (NFRs)

- **NFR-01 Clarity:** Commands are copy-pasteable for Windows; Linux/macOS notes referenced as needed.
- **NFR-02 Security:** Examples avoid long-lived credentials; recommend roles and least privilege.
- **NFR-03 Portability:** Guide uses GovCloud nomenclature; no commercial region assumptions.
- **NFR-04 Compliance Tone:** Reference material only; not an authorization package.

## 6) Acceptance Criteria

- **AC-01:** A newcomer can install, run a scan, and generate a report in GovCloud following the guide.
- **AC-02:** IAM baseline example is valid JSON policy and mentions scoping ARNs/Conditions.
- **AC-03:** Security Hub sample includes required API call and region note.
- **AC-04:** FedRAMP section lists control tie-ins and includes a non-claim disclaimer.
- **AC-05:** README (or docs index) links to the guide; all links resolve.

## 7) Out of Scope

- Authorization packages, SSP/POA&M authoring, or environment-specific accreditation content.
