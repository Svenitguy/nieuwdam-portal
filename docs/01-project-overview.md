# Nieuwdam Cloud Platform - Project Overview

# Table of Contents

- [Introduction](#introduction)
- [Business Scenario](#business-scenario)
- [Project Objectives](#project-objectives)
- [Platform Scope](#platform-scope)
- [Security Automation Framework](#security-automation-framework)
- [Solution Overview](#solution-overview)
- [Architecture Principles](#architecture-principles)
- [Automation Framework](#automation-framework)
- [Engineering Principles](#engineering-principles)
- [Validation Approach](#validation-approach)
- [Technology Stack](#technology-stack)
- [Current Environment Statistics](#current-environment-statistics)
- [Repository Structure](#repository-structure)
- [Security Philosophy](#security-philosophy)
- [Future Roadmap](#future-roadmap)
- [Target Audience](#target-audience)
- [Conclusion](#conclusion)
- [License](#license)

## Introduction

**Nieuwdam Cloud Platform** is a long-term cloud engineering project that simulates the design, deployment and operation of a modern Microsoft cloud environment for a fictional Belgian municipality.

The project is developed as an enterprise-style implementation, applying real-world cloud engineering principles including automation, security, governance, documentation and operational maintainability.

Rather than creating isolated demonstration scripts, Nieuwdam is designed as a complete platform where identity management, security controls, validation, reporting and lifecycle operations work together as a single coherent solution.

The current implementation focuses on Microsoft Entra ID as the foundation of the cloud platform, with future expansion planned towards a complete Azure enterprise environment.

---

## Business Scenario

### Organisation Context

Nieuwdam represents a fictional Belgian municipality that requires a secure and maintainable cloud identity platform.

The municipality contains multiple departments and requires a structured approach for:

- Employee onboarding
- Identity lifecycle management
- Access control
- Security governance
- Compliance validation
- Operational reporting

The platform models how a modern organisation could manage its cloud identity environment using automation and Microsoft cloud technologies.

---

### Business Challenges

Many organisations face challenges when identity management is performed manually.

Common issues include:

- Inconsistent user creation processes
- Manual group assignment
- Limited deployment visibility
- Difficult employee offboarding procedures
- Lack of validation after changes
- Increased risk of configuration drift

The Nieuwdam platform addresses these challenges by introducing a repeatable, configuration-driven automation framework.

---

## Project Objectives

The primary objective of this project is to design and build a realistic enterprise identity management platform using Microsoft technologies and automation principles.

The project focuses on:

- Automating identity lifecycle management
- Creating repeatable deployment workflows
- Applying configuration-driven automation
- Implementing validation processes
- Generating operational reports
- Supporting controlled deprovisioning
- Building a foundation for future Azure expansion

The goal is not only to automate tasks, but to demonstrate how a maintainable cloud platform can be designed and operated.

---

## Platform Scope

### Current Implementation

The current platform focuses on Microsoft Entra ID identity management.

Implemented capabilities include:

#### Identity Lifecycle Management

- Automated user provisioning
- Automated security group provisioning
- Automated group membership assignment
- Controlled identity deprovisioning
- Deployment state tracking

---

#### Security Management

The security framework includes:

- Password policy configuration
- Authentication method configuration
- MFA configuration
- Conditional Access policy framework
- Security Defaults validation
- Emergency access account validation

---

#### Operational Management

The platform provides:

- Centralised logging
- Environment validation
- HTML reporting
- CSV reporting
- JSON reporting
- Deployment execution tracking

---

## Security Automation Framework

The Nieuwdam platform includes a dedicated security automation layer.

The security framework provides configuration and validation capabilities for Microsoft Entra ID security controls.

Implemented security capabilities:

- Password policy configuration
- Authentication method configuration
- MFA configuration
- Conditional Access policy framework
- Security Defaults validation
- Emergency access account validation
- Security reporting

Security automation is executed through:

```text
07-configure-security.ps1
        |
        v
Security Module
        |
        v
Microsoft Graph
        |
        v
Microsoft Entra ID
```

The framework evaluates available tenant capabilities and only applies Conditional Access policies when the required Microsoft Entra ID Premium licensing is available.

---

## Solution Overview

The Nieuwdam platform follows a modular automation architecture.

```text
Configuration Files
        |
        |
        v

Deployment Scripts

        |
        |
        v

PowerShell Automation Framework

        |
        |
        +----------------+
        |                |
        v                v

Microsoft Graph      Validation
Module               Framework

        |
        |
        v

Microsoft Entra ID

        |
        |
        v

Reporting & Deployment State
```
---

## Architecture Principles

The architecture separates configuration, execution logic and validation to improve maintainability, scalability and operational reliability.

The platform follows a layered approach:

- Configuration defines the desired state.
- Automation executes the required changes.
- Validation confirms the resulting environment state.
- Reporting provides operational visibility.

---

## Automation Framework

The Nieuwdam platform uses a configuration-driven deployment model.

Configuration files define the required environment state.

PowerShell modules perform the required actions against Microsoft Entra ID through Microsoft Graph.

Validation verifies that the deployed environment matches the expected configuration.

Reports provide visibility into deployment results and operational status.

### Deployment Flow

```text
Configuration
      |
      v
Automation Scripts
      |
      v
PowerShell Modules
      |
      v
Microsoft Graph
      |
      v
Microsoft Entra ID
      |
      v
Validation
      |
      v
Reporting
```
---

## Engineering Principles

The Nieuwdam platform follows several core engineering principles commonly used in enterprise automation environments.

---

### Modularity

Each responsibility is separated into dedicated PowerShell modules.

Examples:

- Configuration management
- Microsoft Graph integration
- Provisioning
- Validation
- Reporting
- Logging

This approach improves maintainability, reduces complexity and allows individual components to evolve independently.

---

### Repeatability

Deployments are designed to be repeatable.

Running the same configuration against the same environment should produce a predictable result.

This enables consistent environment management and reduces manual administration.

---

### Idempotency

Provisioning operations verify the current environment state before making changes.

Existing objects are detected and handled appropriately to prevent unnecessary duplication.

This allows deployment scripts to be executed safely multiple times without creating inconsistent states.

---

### Separation of Responsibilities

Each script has a clearly defined purpose.

| Script | Responsibility |
|---|---|
| `01-provision-users.ps1` | User lifecycle management |
| `02-provision-groups.ps1` | Security group deployment |
| `03-provision-group-memberships.ps1` | Access assignment |
| `04-validate-environment.ps1` | Environment validation |
| `05-save-provision-state.ps1` | Deployment state tracking |
| `06-deprovision-environment.ps1` | Controlled removal |
| `07-configure-security.ps1` | Security baseline configuration |

The deployment orchestrator coordinates these components without duplicating their internal logic.

This separation ensures that each component remains focused on a single responsibility, making the platform easier to maintain, test and extend.

---

### Centralised Logging

All automation components use a central logging framework to ensure consistent monitoring and troubleshooting across the platform.

Each deployment receives a unique **Run ID**.

This provides:

- Execution tracking
- Troubleshooting capability
- Audit visibility
- Report correlation

The logging framework ensures that actions performed by different automation components can be traced back to a specific deployment execution.

---

## Validation Approach

A deployment is only considered successful after validation has completed.

The validation phase confirms that the expected environment state has been achieved.

Validation ensures:

- Expected objects exist
- Configuration matches requirements
- Deployment results are measurable
- Errors are detected early

This prevents incomplete or inconsistent environments from being considered successfully deployed.

---

## Technology Stack

| Component | Technology |
|---|---|
| Identity Platform | Microsoft Entra ID |
| Automation | PowerShell |
| API Integration | Microsoft Graph |
| Configuration | JSON |
| Reporting | HTML / CSV / JSON |
| Version Control | GitHub |
| Future Infrastructure as Code | Terraform |

---

## Current Environment Statistics

The current identity platform contains approximately:

| Component | Count |
|---|---:|
| Managed Users | 125 |
| Security Groups | 90 |
| Group Membership Relations | 676 |
| PowerShell Deployment Scripts | 8 |
| PowerShell Modules | 8 |
| Reporting Formats | HTML / CSV / JSON |
| Deployment State | JSON |
| Logging | Component-based |

These numbers represent the current implementation and will continue to evolve as additional functionality is added to the platform.

---

## Repository Structure

The repository is organised around modular enterprise development practices.

```text
nieuwdam-portal/

├── scripts/
│   └── PowerShell deployment and orchestration scripts
│
├── modules/
│   └── Reusable PowerShell automation modules
│
├── config/
│   └── Environment configuration files
│
├── docs/
│   └── Technical documentation and validation reports
│
├── assets/
│   └── Architecture diagrams and screenshots
│
└── terraform/
    └── Future Azure Infrastructure as Code
```

---

## Security Philosophy

Security is implemented as an independent architectural capability within the platform design.

Implemented principles include:

- No credentials stored in source control
- Configuration separated from automation logic
- Microsoft Graph-based administration
- Least privilege approach
- Validation before completion
- Controlled lifecycle operations
- Audit-friendly logging

---

## Future Roadmap

The long-term objective is to evolve Nieuwdam into a complete Azure enterprise platform.

---

### Infrastructure

Planned improvements:

- Terraform Infrastructure as Code
- Azure Landing Zone architecture
- Azure Virtual Networks
- Network Security Groups
- Azure Storage
- Azure Key Vault

---

### Security and Governance

Planned improvements:

- Azure Policy
- Role-Based Access Control
- Microsoft Defender integration
- Security monitoring
- Compliance reporting

---

### Operations

Planned improvements:

- Azure Monitor integration
- Backup strategy
- Cost management
- Alerting framework
- Operational dashboards

---

## Target Audience

This project is intended for:

- Cloud engineers
- Azure administrators
- Identity specialists
- System administrators
- Technical recruiters
- IT professionals interested in automation

The repository showcases practical experience in PowerShell automation, Microsoft Entra ID, cloud architecture, security and enterprise engineering practices.

---

## Conclusion

Nieuwdam Cloud Platform illustrates how Microsoft cloud technologies can be combined into a structured, maintainable and secure automation framework.

The project represents an ongoing engineering journey focused on:

- Identity management
- Cloud automation
- Security engineering
- Enterprise architecture

The objective is to continuously expand the platform while maintaining professional development practices, documentation standards and operational reliability.

---

## License

This project is licensed under the Apache License 2.0.

See the [LICENSE](../LICENSE) file for details.

[⬆ Back to Table of Contents](#table-of-contents)