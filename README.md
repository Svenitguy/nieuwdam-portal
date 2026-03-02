# Gemeente Nieuwdam – Azure Cloud Infrastructure Case Study

Dit project simuleert de opzet en implementatie van een veilige Microsoft Azure cloudomgeving voor een fictieve Belgische gemeente, **Nieuwdam**. Het is opgezet als praktijk- en portfolio-project om hands-on ervaring te tonen met moderne IT- en cloudtechnologieën.

---

## Doel van het project

Dit project is opgezet om aan te tonen dat ik in staat ben om:

- Microsoft Entra ID (Identity & Access Management) te configureren  
- Role-Based Access Control (RBAC) toe te passen  
- Azure networking fundamentals te gebruiken  
- PowerShell te gebruiken voor Infrastructure-as-Code en automatisering  
- Security best practices toe te passen  
- Governance en kostenbeheer op te zetten  
- Microsoft 365 en clouddiensten te beheren  

> Dit is geen tutorial, maar een gestructureerde case study die de opzet van een cloudomgeving simuleert.

---

## Scenario

De gemeente Nieuwdam heeft:

- ±30 medewerkers verdeeld over HR, Finance, IT, Administratie en Politie  
- Gevoelige gegevens van inwoners  
- Geen bestaande cloudinfrastructuur  

De gemeente wil:

- Veilige identiteits- en toegangsbeheer implementeren  
- Role-based access toepassen  
- Centrale governance en kostenmonitoring invoeren  
- Klaar zijn voor toekomstige cloud workloads  

---

## Tenant Architectuur

Een aparte Azure tenant werd opgezet:  

`nieuwdam.onmicrosoft.com`


Deze tenant is geïsoleerd van mijn professionele tenant om een realistische organisatorische scheiding na te bootsen.

---

## Identity & Access Management

### Gebruikers

Gebruikers worden provisioned via PowerShell scripts en JSON-configuratiebestanden:

- Bulk user provisioning via Microsoft Graph PowerShell  
- Reproduceerbare en schaalbare gebruikersbeheerprocessen  
- Idempotent: bestaande gebruikers worden overgeslagen  

### Security Groups & Role-Based Access Control

- Security groups gebruikt i.p.v. individuele gebruikersrechten  
- Voorbeelden van groepen:  
  - SG_IT_Admins  
  - SG_IT_Support  
  - SG_HR  
  - SG_Finance  
  - SG_Administration  
  - SG_Police  

> Volgt best practices van enterprise RBAC.

---

## Security Principes

- Scheiding van administratieve accounts  
- Role-based toegang, geen directe permissies  
- Isolatie van guest accounts  
- Basis voorbereid voor Conditional Access & MFA  
- Tenant isolatie voor simulatie van productieomgeving  

---

## Governance Strategie

- Logische structuur van resource groups  
- Naming conventions toegepast  
- Budget monitoring gepland  
- Tagging model (per afdeling / omgeving)  

---

## PowerShell Automatisering

PowerShell scripts worden gebruikt om:

- Verbinding te maken met Microsoft Graph  
- Gebruikers aan te maken vanuit JSON-configuratie  
- Groepen aan te maken en gebruikers eraan toe te wijzen  
- Schaalbare deployment van identiteitsbeheer te simuleren  

Scripts zijn opgeslagen in de `/scripts` map.  
Specifiek kan het script [01-create-users.ps1](https://github.com/Svenitguy/nieuwdam-portal/blob/main/scripts/01-create-users.ps1) geraadpleegd worden voor bulk user provisioning.  
Bekijk de volledige lijst van scripts in de [scripts-map](https://github.com/Svenitguy/nieuwdam-portal/tree/main/scripts).

---

## Project Structuur

De repo is georganiseerd als volgt:

- `/assets` – Afbeeldingen, screenshots, diagrammen  
- `/azure` – Azure-gerelateerde resources, scripts en configuratiebestanden  
- `/config` – JSON configuratiebestanden voor gebruikers, groepen, enz.  
- `/docs` – Documentatie over projecten en cloud setup  
- `/projects` – Specifieke projectpagina’s zoals portfolio, quiz, games  
- `/scripts` – PowerShell scripts voor gebruikers, groepen, provisioning en automatisering  

> Met deze structuur kan het project makkelijk onderhouden en uitgebreid worden. Het toont hands-on ervaring zoals in een echte professionele IT-omgeving.