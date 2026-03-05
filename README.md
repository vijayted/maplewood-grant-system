# Maplewood County Community Development Grant System

## Challenge Overview

A full\-stack **Community Development Grant Management System** built on the Salesforce Platform for Maplewood County. The system enables nonprofit organizations to apply for community development grants (up to $50,000) through an **Experience Cloud** portal, and government reviewers to evaluate, approve, or reject applications through an internal **Lightning App**.

Two core engines power the system:

* **Eligibility Engine** \- Apex service evaluating 6 rules in real time as applicants fill the form
* **Award Calculation Engine** \- Apex service auto\-calculating award amounts via a 5\-factor scoring matrix on approval

---

## Project Structure

```
force-app/
  main/
    default/
      classes/                          # Apex classes & test classes
        GrantEligibilityService.cls     # 6-rule eligibility engine
        GrantAwardService.cls           # 5-factor award calculator
        GrantApplicationController.cls  # CRUD, file upload, queries
        GrantNotificationService.cls    # Email notifications on status change
        GrantApplicationTriggerHandler.cls  # Trigger handler logic
        CustomSelfRegController.cls     # Experience Cloud self-registration
        *Test.cls                       # Corresponding test classes
      lwc/                              # Lightning Web Components
        grantApplicationForm/           # Multi-step application form
        applicantDashboard/             # Applicant portal dashboard
        applicationDetail/              # Read-only application detail
        reviewerApplicationList/        # Reviewer list with filters
        reviewerApplicationDetail/      # Reviewer detail with actions
        awardBreakdown/                 # Scoring matrix display
        eligibilityPanel/               # Pass/fail rule indicators
        statusBadge/                    # Color-coded status badges
        loginBranding/                  # Login page branding
        customSelfRegister/             # Registration redirect
      objects/
        Grant_Application__c/           # Main application object
        Status_History__c/              # Status change audit trail
        Grant_Application_Event__e/     # Platform Event
      triggers/
        GrantApplicationTrigger.trigger # Auto-creates status history
      permissionsets/
        Grant_Reviewer.permissionset-meta.xml
        Grant_Applicant.permissionset-meta.xml
      validationRules/                  # (within object folders)
        EIN_Format, Project_End_After_Start,
        Amount_Under_50K, Rejection_Requires_Comments
      pages/
        CustomSelfRegister.page         # VF self-registration page
      applications/
        Grant_Review_Console.app-meta.xml
      digitalExperiences/               # Experience Cloud site config
      profiles/                         # Community profiles
      networks/                         # Network configuration
      sites/                            # Force.com site config
```

---

## Custom Objects

### Grant\_Application\_\_c (Main Object)

| Category | Fields |
|:---------|:-------|
| **Organization** | Organization\_Name\_\_c, EIN\_\_c, Organization\_Type\_\_c (Picklist), Year\_Founded\_\_c, Annual\_Budget\_\_c (Currency), Num\_Employees\_\_c, Contact\_Name\_\_c, Contact\_Email\_\_c, Contact\_Phone\_\_c, Organization\_Address\_\_c, Mission\_Statement\_\_c |
| **Project** | Project\_Title\_\_c, Project\_Category\_\_c (Picklist), Project\_Description\_\_c, Target\_Population\_\_c, Num\_Beneficiaries\_\_c, Total\_Project\_Cost\_\_c (Currency), Amount\_Requested\_\_c (Currency), Project\_Start\_Date\_\_c, Project\_End\_Date\_\_c, Previously\_Funded\_\_c |
| **Eligibility** | Eligibility\_Score\_\_c, Is\_Eligible\_\_c, Eligibility\_Results\_\_c (JSON) |
| **Review** | Status\_\_c (Picklist), Award\_Amount\_\_c (Currency), Award\_Breakdown\_\_c (JSON), Reviewer\_Comments\_\_c, Reviewer\_\_c (Lookup→User), Reviewed\_Date\_\_c |
| **Auto** | Name (Auto\-Number: APP\-{0000}) |

### Status\_History\_\_c (Audit Trail)

Master\-Detail to Grant\_Application\_\_c with fields: Old\_Status\_\_c, New\_Status\_\_c, Changed\_By\_\_c (Lookup→User), Comments\_\_c, Changed\_At\_\_c

---

## Apex Classes

| Class | Purpose | Key Details |
|:------|:--------|:------------|
| `GrantEligibilityService` | Evaluates 6 eligibility rules | Returns structured results with per\-rule pass/fail, score, and overall boolean |
| `GrantAwardService` | Calculates award on approval | 5\-factor scoring matrix (max 15 points), rounds to nearest $100, caps at $50,000 |
| `GrantApplicationController` | CRUD operations | Uses `ApplicationInput` wrapper class, `Security.stripInaccessible()`, `WITH SECURITY_ENFORCED` |
| `GrantNotificationService` | Email notifications | `@future` method sends emails on status changes |
| `GrantApplicationTriggerHandler` | Trigger handler | Creates Status\_History\_\_c records, publishes Platform Events, triggers notifications |
| `CustomSelfRegController` | Self\-registration | Creates portal users, auto\-assigns Grant\_Applicant permission set |

All `@AuraEnabled` methods include `try/catch` with `AuraHandledException` for proper error handling.

---

## Eligibility Engine (6 Rules)

| # | Rule | Logic | Pass Message |
|:--|:-----|:------|:-------------|
| 1 | Nonprofit Status | Org type in: 501(c)(3), 501(c)(4), CBO, FBO | "Eligible organization type" |
| 2 | Operating History | (Current Year \- Year Founded) >= 2 | "Organization has been operating for X years" |
| 3 | Budget Cap | Annual Budget < $2,000,000 | "Operating budget is within limit" |
| 4 | Funding Ratio | Amount Requested <= 50% of Total Project Cost | "Requested amount is X% of project cost" |
| 5 | Maximum Request | Amount Requested <= $50,000 | "Requested amount is within the $50,000 maximum" |
| 6 | Minimum Impact | Beneficiaries >= 50 | "Project will serve X beneficiaries" |

Called imperatively from LWC with debounce for real\-time feedback. Stored as JSON on the record on submission.

---

## Award Calculation Engine (5 Factors)

| Factor | 1 Point | 2 Points | 3 Points |
|:-------|:--------|:---------|:---------|
| Community Impact | 50\-200 beneficiaries | 201\-1,000 | 1,001\+ |
| Track Record | 2\-5 years | 6\-15 years | 16\+ years |
| Category Priority | Arts, Workforce, Other | Youth, Senior | Public Health, Safety |
| Financial Need | $500K\-$1.99M budget | $100K\-$499K | Under $100K |
| Cost Efficiency | 41%\-50% ratio | 26%\-40% | 25% or less |

**Formula**: `Award = Amount Requested x (Total Score / 15)`, rounded to nearest $100, capped at $50,000.

---

## Application Workflow

```
[Applicant fills form] → real-time eligibility feedback
         ↓
    [Submit] → SUBMITTED (eligibility stored)
         ↓
    [Reviewer opens] → UNDER REVIEW
         ↓
    ┌────┴────┐
    ↓         ↓
 APPROVED   REJECTED
 (award     (comments
  auto-      required)
  calculated)
```

---

## LWC Components

### Experience Cloud (Applicant\-Facing)

| Component | Purpose |
|:----------|:--------|
| `applicantDashboard` | Landing page (guest view with gradient hero), authenticated dashboard with application list, form, and detail navigation |
| `grantApplicationForm` | Multi\-step form (Organization → Project → Review & Submit) with real\-time eligibility panel, file upload, and inline error/success banners |
| `applicationDetail` | Read\-only view showing all fields, eligibility results, award breakdown (if approved), reviewer comments (if rejected), and uploaded documents |
| `loginBranding` | Branded login page header with Maplewood logo and gradient background |
| `customSelfRegister` | Redirects to Visualforce self\-registration page |

### Lightning App (Reviewer\-Facing)

| Component | Purpose |
|:----------|:--------|
| `reviewerApplicationList` | Summary count cards (Submitted, Under Review, Approved with total $, Rejected), filters by status/eligibility, data table with clickable application links, fund budget overview ($2M total) |
| `reviewerApplicationDetail` | Full application detail, eligibility panel, document preview (native Salesforce file viewer), Approve/Reject actions with confirmation modals, breadcrumb navigation |

### Shared Child Components

| Component | Purpose |
|:----------|:--------|
| `eligibilityPanel` | Reusable pass/fail rule display with green check / red X / gray dash icons |
| `awardBreakdown` | 5\-factor scoring table, percentage, and final award amount |
| `statusBadge` | Color\-coded badge: Blue (Submitted), Orange (Under Review), Green (Approved), Red (Rejected) |

---

## Security & Sharing

| Concern | Implementation |
|:--------|:---------------|
| Object Permissions | External: Create \+ Read on Grant\_Application\_\_c (no Edit/Delete). Internal reviewers: Read \+ Edit |
| Field\-Level Security | External users cannot see Reviewer\_\_c, Award\_Breakdown\_\_c internal details. Reviewer\_Comments\_\_c shown only when rejected |
| Record Access | OWD = Private. External users see only their own records (owner\-based sharing) |
| Permission Sets | `Grant_Reviewer` (internal), `Grant_Applicant` (external) |
| Apex Security | `WITH SECURITY_ENFORCED` on SOQL, `Security.stripInaccessible()` on DML |
| File Access | ContentDocumentLink shares files with record owner; reviewers access via record |

---

## Optional Enhancements Implemented

* [x] **Platform Events** \- `Grant_Application_Event__e` for real\-time status updates
* [x] **Apex Trigger** \- Auto\-creates `Status_History__c` records on status change
* [x] **Email Notifications** \- `@future` email service notifies applicants on status change
* [x] **Validation Rules** \- Server\-side validation (EIN format, date ordering, amount cap, rejection comments)
* [x] **Report & Dashboard** \- Grant Program Overview dashboard (configured manually in org)

---

## UI/UX Design

* **Consistent Branding** \- Dark blue gradient (`#001f44` → `#003068` → `#004a9f`) across Login, Registration, and Landing pages
* **SLDS Compliance** \- All components use Salesforce Lightning Design System classes
* **Responsive Layout** \- Form and eligibility panel stack on mobile breakpoints
* **Status Badges** \- Color\-coded with WCAG\-compliant contrast ratios
* **Inline Feedback** \- Error/success banners (no toast in LWR), loading spinners, empty states
* **Breadcrumb Navigation** \- Context\-aware breadcrumbs on form and detail views
* **WCAG 2.1 AA** \- ARIA labels, keyboard navigation, focus management, screen reader support

---

## Prerequisites

* Salesforce CLI (`sf`)
* A Salesforce Developer Org ([developer.salesforce.com](https://developer.salesforce.com))
* Node.js (for local LWC development)

## Setup Instructions

### 1. Clone & Authenticate

```bash
git clone <repository-url>
cd MaplewoodGrantSystem
sf org login web -a MaplewoodDev
```

### 2. Deploy Source

```bash
sf project deploy start -d force-app -o MaplewoodDev
```

### 3. Assign Permission Sets

```bash
sf org assign permset -n Grant_Reviewer -o MaplewoodDev
```

### 4. Configure Experience Cloud Site

* Navigate to **Setup > Digital Experiences > All Sites**
* The "Maplewood Grant Portal" site should be deployed. If not, create one using the LWR template
* Enable self\-registration for external users (Customer Community license)
* Verify pages: Home (applicantDashboard), Login (loginBranding \+ loginForm), Register
* Publish the site

### 5. Configure Internal Lightning App

* Navigate to the **Grant Review Console** Lightning App
* Set the home page to use the `Grant_Review_Home` FlexiPage
* Set the Grant Application record page to use `Grant_Application_Record_Page` FlexiPage

### 6. Create Test Users

* **Applicant**: Register via Experience Cloud self\-registration at `/grants/SelfRegister`
* **Reviewer**: Any internal user with "Grant Reviewer" permission set assigned

---

## Features Checklist

* [x] Experience Cloud self\-registration and login with branded pages
* [x] Two\-section application form with field validation
* [x] Real\-time eligibility feedback (6 rules, Apex\-driven, debounced)
* [x] File upload (PDF, JPG, PNG up to 5 MB via ContentVersion)
* [x] Pre\-submit review screen with eligibility warning
* [x] Applicant dashboard with status badges and award amounts
* [x] Application detail view with eligibility, award breakdown, and comments
* [x] Reviewer application list with summary cards, filters, and fund overview
* [x] Clickable application links in reviewer data table
* [x] Mark Under Review action
* [x] Approve with auto\-calculated award (5\-factor scoring matrix)
* [x] Reject with required comments and confirmation modal
* [x] Award breakdown display (scoring table, percentage, final amount)
* [x] Status history tracking (Apex trigger \+ Status\_History\_\_c)
* [x] Platform Events for real\-time updates
* [x] Email notifications on status changes
* [x] Server\-side validation rules (4 rules)
* [x] Document preview via native Salesforce file viewer
* [x] Consistent dark blue gradient branding across all portal pages
* [x] SLDS styling throughout
* [x] WCAG 2.1 AA accessibility compliance
* [x] Apex security (FLS enforcement, stripInaccessible)
* [x] Comprehensive Apex test coverage

---

## Architecture Decisions

### LWR for Experience Cloud

LWR (Lightning Web Runtime) was chosen over Aura for better performance and modern web standards per Salesforce recommendation for new builds.

### Imperative Apex for Eligibility

Uses imperative calls (not @wire) because eligibility needs to fire on every field change with debouncing. Wire adapters cache results and don't support this dynamic pattern.

### Visualforce for Self\-Registration

LWR guest users cannot reliably make imperative Apex calls, so self\-registration uses a Visualforce page with an Apex controller that calls `Site.createExternalUser()`.

### JSON Storage for Results

Eligibility results and award breakdowns are stored as JSON in LongTextArea fields for flexible LWC rendering without additional related objects.

### Component\-Level Backgrounds

The gradient background is applied at the LWC component level (not global CSS) because LWR Experience Cloud sites don't reliably support global CSS overrides on page\-level elements.

---

## Known Limitations

* Experience Cloud site pages require manual configuration via Experience Builder after initial deployment
* Self\-registration configuration requires manual setup in Experience Cloud admin
* File upload uses base64 via Apex (~6MB heap limit for large files)
* `ShowToastEvent` does not work in LWR sites; inline banners are used instead
* Reports and Dashboards must be configured manually in the org (metadata deployment is unreliable)

---

## AI Tool Usage

* **Cursor IDE with Claude** \- Used for code generation, architecture planning, iterative debugging, and implementation
* **Example of AI help**: Generated the 5\-factor scoring matrix logic in `GrantAwardService` with proper boundary conditions and rounding
* **Example of AI correction**: Discovered that `ShowToastEvent` doesn't work in LWR Experience Cloud sites and pivoted to inline error/success banners; also fixed global CSS breaking the LWR site layout by moving to component\-level gradient backgrounds
