# Nieuwdam Cloud Platform

## Engineering Challenges and Design Decisions

Version: 1.0
Document Status: Final
Platform: Microsoft Entra ID Automation Framework

---

<a name="table-of-contents"></a>

# Table of Contents

* [Introduction](#introduction)
* [Challenge 1: Building Idempotent Deployments](#challenge-1-building-idempotent-deployments)
* [Challenge 2: Separating Configuration from Code](#challenge-2-separating-configuration-from-code)
* [Challenge 3: Designing Safe Deprovisioning](#challenge-3-designing-safe-deprovisioning)
* [Challenge 4: Creating a Validation Framework](#challenge-4-creating-a-validation-framework)
* [Challenge 5: Building Operational Reporting](#challenge-5-building-operational-reporting)
* [Challenge 6: Designing Modular PowerShell Architecture](#challenge-6-designing-modular-powershell-architecture)
* [Challenge 7: Security as an Independent Layer](#challenge-7-security-as-an-independent-layer)
* [Lessons Learned](#lessons-learned)
* [Conclusion](#conclusion)

---

# Introduction

During the development of the Nieuwdam Cloud Platform, several engineering challenges required architectural decisions to create a maintainable and reliable automation framework.

The objective was not only to automate Microsoft Entra ID administration tasks, but to design a complete identity lifecycle platform based on enterprise automation principles.

The platform needed to support:

* Repeatable deployments
* Safe identity lifecycle management
* Configuration-driven automation
* Environment validation
* Operational visibility
* Security integration
* Future extensibility

Throughout development, several design decisions were made to ensure that the platform remained maintainable as additional capabilities were introduced.

This document describes the main engineering challenges encountered during development and the solutions implemented.

---

# Challenge 1: Building Idempotent Deployments

## Problem

One of the first challenges was ensuring that deployments could be executed repeatedly without creating duplicate resources or causing inconsistent states.

A simple automation script can create users, groups or memberships during the first execution, but problems occur when the same script is executed again.

Potential issues include:

* Duplicate user creation attempts
* Duplicate security groups
* Duplicate group memberships
* Unclear deployment outcomes
* Configuration drift between executions

A production-oriented automation framework must be able to determine the current environment state before applying changes.

---

## Solution

The platform was designed around an idempotent deployment model.

Before creating or modifying resources, the automation framework evaluates the current Microsoft Entra ID environment.

The provisioning process follows this approach:

```text
Configuration

      |

      v

Evaluate Current State

      |

      v

Determine Required Action

      |

      v

Apply Change if Required

      |

      v

Record Result
```

Examples:

* Existing users are detected before creation
* Existing groups are detected before creation
* Existing memberships are verified before assignment
* Previously deployed resources are tracked

---

## Result

The deployment framework can safely execute the same configuration multiple times while producing predictable results.

This improves:

* Deployment reliability
* Operational confidence
* Troubleshooting capability
* Environment consistency

Idempotency became a fundamental design principle throughout the platform.

---

# Challenge 2: Separating Configuration from Code

## Problem

A common challenge in automation projects is avoiding environment-specific information inside implementation logic.

When configuration values are directly embedded inside scripts:

* Changes require code modifications
* Automation becomes difficult to reuse
* Testing becomes harder
* Different environments require different scripts

For an enterprise-style platform, the desired environment state should be separated from the automation engine.

---

## Solution

The Nieuwdam Cloud Platform uses a configuration-driven architecture.

Environment definitions are stored in structured JSON files.

Examples:

```text
config/

├── users.json
├── groups.json
├── group-memberships.json
├── security.json
├── conditional-access.json
└── cleanup.json
```

The PowerShell automation framework consumes this configuration without containing organisation-specific values.

The architecture separates:

```text
Configuration

      |

      v

Automation Logic

      |

      v

Microsoft Entra ID
```

---

## Result

The same automation framework can support different environments by changing configuration instead of modifying implementation code.

Benefits include:

* Improved maintainability
* Reusable automation components
* Easier change management
* Clear separation of responsibilities

Configuration becomes the definition of the desired platform state.

---

# Challenge 3: Designing Safe Deprovisioning

## Problem

Creating resources is only one part of identity lifecycle management.

Removing resources introduces additional risks because incorrect deletion actions can impact operational environments.

A simple deletion script can easily remove unintended objects if sufficient controls are not implemented.

Challenges included:

* Selecting the correct resources
* Preventing accidental removal
* Maintaining execution history
* Providing review capabilities

---

## Solution

The platform implements controlled deprovisioning through a dedicated lifecycle workflow.

Deprovisioning is separated from provisioning and uses its own configuration model.

Example:

```text
cleanup.json

      |

      v

Deprovisioning Script

      |

      v

Resource Evaluation

      |

      v

Controlled Removal

      |

      v

Result Logging
```

Safety mechanisms include:

* Configuration-based targeting
* Resource validation before removal
* Dry Run support
* Centralized logging
* Result tracking

---

## Result

Resources can be removed through a predictable and controlled process.

The platform supports a complete identity lifecycle:

```text
Create

  |

Manage

  |

Validate

  |

Retire
```

This provides a more realistic enterprise identity management approach.

---

# Challenge 4: Creating a Validation Framework

## Problem

A deployment that completes without errors does not automatically mean that the environment is correct.

Automation can fail silently or create unexpected results.

A reliable platform requires an independent method to verify whether the deployed environment matches the intended configuration.

---

## Solution

A dedicated validation framework was created.

The Validation module performs read-only comparison between:

* Expected configuration
* Current Microsoft Entra ID state

The validation process follows:

```text
Expected Configuration

        |

        v

Retrieve Current Environment

        |

        v

Compare Expected vs Actual State

        |

        v

Generate Validation Results
```

Validation checks include:

* User existence
* Group existence
* Membership assignments
* Deployment consistency

---

## Result

Every deployment can be verified independently.

The platform provides:

* Objective deployment verification
* Clear failure identification
* Structured validation results
* Increased operational confidence

Validation became a required stage before considering a deployment successful.

---

# Challenge 5: Building Operational Reporting

## Problem

Automation generates large amounts of technical information.

Without structured reporting, administrators must manually analyse logs and execution output.

The challenge was transforming raw automation data into useful operational information.

---

## Solution

A dedicated Reporting module was implemented.

The reporting architecture separates data collection from presentation.

The platform generates multiple output formats:

### CSV

Used for:

* Data analysis
* Filtering
* Spreadsheet processing

### JSON

Used for:

* Machine-readable output
* Future integrations
* Automation workflows

### HTML

Used for:

* Human-readable dashboards
* Operational review
* Validation summaries

The reporting flow:

```text
Execution Results

        |

        v

Reporting Module

        |

        v

CSV / JSON / HTML Output
```

---

## Result

Deployment information becomes easier to review, analyse and integrate.

Reporting improves:

* Operational visibility
* Troubleshooting
* Documentation
* Future automation possibilities

---

# Challenge 6: Designing Modular PowerShell Architecture

## Problem

As the platform expanded, a single large PowerShell script would become difficult to maintain.

Combining provisioning, security, validation, reporting and logging into one script would create:

* High complexity
* Difficult testing
* Limited reusability
* Strong dependencies between components

---

## Solution

The platform was redesigned using a modular PowerShell architecture.

Responsibilities were separated into dedicated modules:

```text
modules/

├── Configuration
├── Graph
├── Helpers
├── Logging
├── Provisioning
├── Security
├── Validation
└── Reporting
```

Operational scripts act as controlled entry points while reusable logic remains inside modules.

---

## Result

The modular architecture provides:

* Better maintainability
* Code reuse
* Easier troubleshooting
* Independent component development
* Future expansion capability

The platform structure allows new functionality to be added without redesigning existing components.

---

# Challenge 7: Security as an Independent Layer

## Problem

Security controls are often added after systems are deployed.

This approach can create inconsistent security configurations and increase operational risk.

The challenge was designing security as a fundamental part of the platform rather than an additional step.

---

## Solution

Security was implemented as an independent architectural layer.

The Security module manages security-related automation separately from identity provisioning.

Security capabilities include:

* Authentication configuration
* MFA configuration
* Conditional Access framework
* Security validation
* Emergency access validation

The architecture follows:

```text
Security Configuration

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

---

## Result

Security controls are deployed using the same principles as other platform components:

* Repeatable execution
* Configuration-driven management
* Validation
* Operational reporting

Security becomes part of the platform design instead of an afterthought.

---

# Lessons Learned

The development of the Nieuwdam Cloud Platform demonstrated several important engineering lessons.

## Automation Requires Architecture

Writing automation code is only part of building a reliable platform.

A scalable automation solution requires:

* Clear responsibilities
* Defined workflows
* Error handling
* Validation
* Operational visibility

---

## Repeatability Is Essential

Automation becomes valuable when it can be executed consistently.

Idempotency, configuration separation and validation are essential principles for reliable automation.

---

## Documentation Improves Engineering Quality

Documenting architecture and design decisions improves understanding and maintainability.

The documentation process also helped identify areas where the platform could be improved further.

---

## Security Should Be Designed Early

Security controls are most effective when they are integrated into the architecture from the beginning.

Treating security as an independent capability improves consistency and reduces future complexity.

---

# Conclusion

The Nieuwdam Cloud Platform was developed not only as an automation project, but as an exercise in designing a maintainable enterprise-style identity platform.

The engineering challenges encountered during development influenced the final architecture and resulted in a framework based on:

* Configuration-driven automation
* Modular PowerShell design
* Idempotent deployments
* Independent validation
* Controlled lifecycle management
* Security-focused architecture
* Operational reporting

These design decisions provide a strong foundation for future expansion towards a broader Azure cloud platform.

[⬆ Back to Table of Contents](#table-of-contents)
