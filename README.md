# 🏛️ Nieuwdam Cloud Platform

## Enterprise Azure Infrastructure & Identity Platform for a Fictional Belgian Municipality

> **Nieuwdam** is a long-term cloud engineering project that simulates the design, implementation and management of a modern Microsoft cloud environment for a fictional Belgian municipality.
>
> The platform is built using enterprise architecture principles, Microsoft cloud technologies and Infrastructure-as-Code methodologies, with a strong focus on automation, security, governance and maintainability.

---

<a name="table-of-contents"></a>
# 📚 Table of Contents

- [Project Vision](#-project-vision)
- [Current Project Status](#-current-project-status)
- [Environment Statistics](#-environment-statistics)
- [Platform Architecture](#-platform-architecture)
- [Identity Automation Framework](#-identity-automation-framework)
- [Core Features](#-core-features)
- [Security Considerations](#-security-considerations)
- [Repository Structure](#-repository-structure)
- [Screenshots](#-screenshots)
- [Documentation](#-documentation)
- [Roadmap](#-roadmap)
- [First Release](#-first-release)
- [About This Project](#-about-this-project)
- [License](#-license)

---

# 🎯 Project Vision

Many portfolio projects demonstrate isolated cloud components such as a virtual machine deployment or a simple user creation script.

**Nieuwdam takes a different approach.**

The objective is to design a complete enterprise-style cloud platform where identity, security, automation and infrastructure operate together as one coherent solution.

The project focuses on:

* Designing maintainable cloud architectures
* Automating repetitive administrative processes
* Applying enterprise identity lifecycle management
* Building validation and reporting capabilities
* Creating repeatable deployment workflows

The goal is not only to deploy technology, but to demonstrate the engineering decisions behind building and operating a secure cloud environment.

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 🏗️ Current Project Status

The project is actively under development.

The current implementation focuses on the **Microsoft Entra ID Identity Platform**, providing a complete identity lifecycle management framework including provisioning, security configuration, validation, reporting and controlled deprovisioning.

## Current Environment

| Component                        | Status        |
| -------------------------------- | ------------- |
| Microsoft Entra ID Integration   | ✅ Implemented |
| User Provisioning                | ✅ Implemented |
| Group Provisioning               | ✅ Implemented |
| Group Membership Management      | ✅ Implemented |
| Environment Validation           | ✅ Implemented |
| HTML Reporting                   | ✅ Implemented |
| CSV Reporting                    | ✅ Implemented |
| JSON Reporting                   | ✅ Implemented |
| Provision State Management       | ✅ Implemented |
| Controlled Deprovisioning        | ✅ Implemented |
| Central Logging                  | ✅ Implemented |
| Microsoft Graph Automation       | ✅ Implemented |
| Azure Infrastructure             | 🚧 Planned    |
| Terraform Infrastructure-as-Code | 🚧 Planned    |

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 📊 Environment Statistics

Current identity platform implementation:

| Component                     |             Count |
| ----------------------------- | ----------------: |
| Users Managed                 |               125 |
| Security Groups               |                90 |
| Group Membership Relations    |               676 |
| PowerShell Scripts            |                 8 |
| PowerShell Modules            |                 8 |
| Reporting Formats             | HTML / CSV / JSON |
| Deployment State              |              JSON |
| Logging                       |   Component Based |

The environment will continue to expand as additional Azure services are introduced.

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 🏛️ Platform Architecture

The Nieuwdam platform follows a modular enterprise architecture.

The current identity layer consists of:

* Configuration-driven deployment
* Microsoft Graph integration
* Modular PowerShell components
* Validation framework
* Reporting engine
* Deployment state tracking
* Controlled lifecycle management

## High-Level Architecture

```text
                 Configuration Files
                         │
                         ▼

              Deployment Orchestration
                         │
                         ▼

              PowerShell Automation Layer

        ┌───────────────┼────────────────┐
        ▼               ▼                ▼
 Graph Module    Provisioning      Security Module
                  Module

        │               │                │
        └───────────────┼────────────────┘
                        ▼

                 Microsoft Entra ID

                        │
                        ▼

              Validation Module

                        │
                        ▼

              Reporting Module

                        │
                        ▼

              State Management
```

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# ⚙️ Identity Automation Framework

The current implementation provides a complete identity lifecycle workflow.

```text
Deploy Environment
        │
        ▼
Provision Users
        │
        ▼
Provision Groups
        │
        ▼
Assign Group Memberships
        │
        ▼
Configure Security
        │
        ▼
Validate Environment
        │
        ▼
Generate Reports
        │
        ▼
Save Deployment State
        │
        ▼
Controlled Deprovisioning
```

Each stage can run independently or as part of the complete deployment process.

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 🔧 Core Features

## Identity Management

* Microsoft Entra ID automation
* User lifecycle management
* Security group provisioning
* Group membership assignment
* Controlled deprovisioning

## Automation Framework

* Modular PowerShell architecture
* Microsoft Graph integration
* Configuration-driven deployment
* Idempotent execution
* Dry-run support
* Deployment state tracking

## Validation & Reporting

* Environment validation framework
* HTML dashboard reports
* CSV exports
* JSON reports
* Detailed execution logging

## Enterprise Design Principles

* Separation of configuration and code
* Least privilege approach
* Repeatable deployments
* Audit-friendly logging
* Modular expansion model

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 🔐 Security Considerations

Security is implemented as an independent architectural capability within the platform design.

Implemented principles:

* No credentials stored in source control
* Secrets excluded through `.gitignore`
* Configuration separated from implementation
* Microsoft Graph integrated automation
* Least privilege permission model
* Validation before deployment
* Controlled removal workflows
* Audit-friendly logging

Sensitive environment data is intentionally excluded from the public repository.

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 📂 Repository Structure

```text
nieuwdam-portal/

├── .github/
│   └── workflows/
│
├── assets/
│   ├── diagrams/
│   └── images/
│
├── config/
│   └── examples/
│
├── docs/
│   ├── 01-project-overview.md
│   ├── 02-architecture.md
│   ├── screenshots/
│   └── testing/
│
├── modules/
│   ├── Configuration/
│   ├── Graph/
│   ├── Helpers/
│   ├── Logging/
│   ├── Provisioning/
│   ├── Reporting/
│   ├── Security/
│   └── Validation/
│
├── scripts/   
│   ├── deploy-environment.ps1
│   ├── 01-provision-users.ps1
│   ├── 02-provision-groups.ps1
│   ├── 03-provision-group-memberships.ps1
│   ├── 04-validate-environment.ps1
│   ├── 05-save-provision-state.ps1
│   ├── 06-deprovision-environment.ps1
│   └── 07-configure-security.ps1
│
├── README.md
│
└── terraform/
```

The repository is structured around maintainability, scalability and future Azure expansion.

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 📸 Screenshots

Screenshots will be added as the platform documentation evolves.

Planned examples include:

## Deployment Execution

Example provisioning workflow and logging output.

```
docs/screenshots/provisioning-success.png
```

## Validation Reports

Generated validation dashboards and compliance output.

```
docs/screenshots/validation-report.png
```

## Microsoft Entra Environment

Examples of:

* Users
* Groups
* Membership assignments
* Identity configuration

```
docs/screenshots/entra-environment.png
```

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 📚 Documentation

Detailed documentation is available inside the `docs/` directory.

Current documentation includes:

* Project overview
* Architecture documentation
* Testing documentation and future test results
* Screenshots

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 🛣️ Roadmap

The platform will continue evolving towards a complete Azure enterprise environment.

Planned milestones:

## Infrastructure

* Terraform Infrastructure-as-Code
* Azure Landing Zone
* Virtual Networks
* Network Security Groups
* Azure Storage
* Azure Key Vault

## Security & Governance

* Azure Policy
* RBAC implementation
* Microsoft Defender
* Security monitoring
* Compliance reporting

## Operations

* Azure Monitor integration
* Backup strategy
* Cost management
* Operational dashboards

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 🚀 First Release

Current release focus:

**Nieuwdam Identity Platform v0.1**

Includes:

✅ Microsoft Graph integration
✅ Identity provisioning framework
✅ Security configuration framework
✅ Modular PowerShell architecture
✅ Validation engine
✅ Reporting framework
✅ Deployment state management
✅ Documentation structure

[⬆️ Back to Table of Contents](#-table-of-contents)

---

# 👨‍💻 About This Project

Nieuwdam is a personal cloud engineering project created to develop practical experience with Microsoft Azure, Microsoft Entra ID, automation and enterprise architecture.

Rather than focusing only on individual certification exercises, this project demonstrates how cloud services can be combined into a complete, maintainable and secure platform.

The project continues to evolve as new technologies, architectures and engineering practices are introduced.

---

# 📜 License

This project is licensed under the Apache License 2.0.

See the [LICENSE](LICENSE) file for details.

[⬆️ Back to Table of Contents](#-table-of-contents)