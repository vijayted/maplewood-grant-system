# Maplewood County Community Development Grant System

## Challenge Overview

A full\-stack **Community Development Grant Management System** built on the Salesforce Platform for Maplewood County. The system enables nonprofit organizations to apply for community development grants (up to $50,000) through an **Experience Cloud** portal, and government reviewers to evaluate, approve, or reject applications through an internal **Lightning App**.

Two core engines power the system:

* **Eligibility Engine** \- Apex service evaluating 6 rules in real time as applicants fill the form
* **Award Calculation Engine** \- Apex service auto\-calculating award amounts via a 5\-factor scoring matrix on approval

---

## Highlights & Key Accomplishments

### End\-to\-End Verified Workflow

Every path in the system has been manually tested and verified:

* **Applicant journey**: Self\-registration → branded login → multi\-step form with real\-time eligibility → file upload → submission → dashboard tracking → detail view with award/comments
* **Reviewer journey**: Internal login → summary cards with live totals → filter by status/eligibility → open application → mark Under Review → Approve (auto\-calculated award) or Reject (required comments with confirmation modal)
* **Edge cases tested**: Invalid EIN formats, amounts exceeding $50K, project end before start date, organizations under 2 years old, budget over $2M, fewer than 50 beneficiaries, login with wrong credentials, empty required fields, file type restrictions

### Engineered Logic (Not Boilerplate)

* **Eligibility Engine**: Each of the 6 rules was individually verified with boundary\-condition testing (e.g., organization founded exactly 2 years ago passes; 1 year fails). Results stored as structured JSON on the record for auditability
* **Award Calculation Engine**: All 5 scoring factors tested across their 3 tiers with edge values. Formula verified: `Award = Amount_Requested × (Score / 15)`, rounded to nearest $100 and capped at $50,000. Breakdown stored as JSON for transparent display to both reviewer and applicant
* **Debounced Real\-Time Eligibility**: Imperative Apex calls fire on every field change with a 500ms debounce, giving applicants instant green/red feedback without hammering the server
* **Input Normalization**: EIN field automatically trims whitespace and normalizes non\-standard dash characters (en\-dash, em\-dash) to standard hyphens before validation, preventing silent failures from copy\-paste

### Security Model \- Defense in Depth

* **Object\-level**: External users get Create \+ Read only (no Edit/Delete). Reviewers get Read \+ Edit
* **Field\-level**: Internal fields (Reviewer\_\_c, Award\_Breakdown\_\_c) hidden from external users. Reviewer comments exposed only on rejection
* **Record\-level**: OWD set to Private. Applicants see only their own records via owner\-based sharing
* **Apex\-level**: `WITH SECURITY_ENFORCED` on all SOQL queries. `Security.stripInaccessible()` on read operations. `AuraHandledException` wraps all `@AuraEnabled` methods with meaningful error messages
* **Permission sets**: Two distinct sets (`Grant_Reviewer`, `Grant_Applicant`) with least\-privilege field access

### Premium UI/UX \- Beyond SLDS Basics

* **Split\-screen login page**: Left panel showcases the grant program (features, stats, mission) while the right panel holds the branded login form. Responsive \- stacks vertically on mobile
* **Animated staff portal branding**: `LoginRightFrame.page` features an animated network graph, county seal, and key statistics
* **Gradient theme system**: Consistent dark blue gradient (`#001229` → `#004a9f`) applied at component level (not global CSS) because LWR doesn't reliably support page\-level overrides
* **Inline error handling**: Since `ShowToastEvent` doesn't work in LWR Experience Cloud sites, all feedback uses inline banners with ARIA live regions for screen reader announcements
* **WCAG 2.1 AA compliant**: Proper ARIA labels, keyboard navigation, visible focus indicators, color\-contrast\-safe status badges, and semantic HTML throughout

### Platform\-Aware Problem Solving

Several Salesforce\-specific challenges were identified and solved during development:

| Challenge | Root Cause | Solution |
|:----------|:-----------|:---------|
| Login form POST returned "URL No Longer Exists" | Experience Cloud (LWR) doesn't reliably process raw form POSTs to the login endpoint | Replaced with `@AuraEnabled` Apex method using `Site.login()` returning redirect URL to LWC |
| `ShowToastEvent` failed silently in portal | LWR sites don't support the Lightning toast event | Built inline success/error banners with `role="alert"` and `aria-live` |
| Global CSS gradient broke LWR layout | LWR controls the outer page DOM; global overrides cause conflicts | Moved gradient to component\-level CSS with negative margins |
| Required fields appeared null in Apex | `ApplicationInput` wrapper properties lacked `get; set;` accessors, causing silent JSON deserialization failure in Experience Cloud context | Added `{ get; set; }` to all `@AuraEnabled` wrapper properties |
| EIN validation failed on pasted values | Users pasting EINs included en\-dashes or trailing whitespace | Added `TRIM()` in validation rule \+ character normalization in Apex |
| Self\-registration failed from LWC guest context | LWR guest users can't reliably make imperative Apex calls | Implemented Visualforce self\-registration page with `Site.createExternalUser()` |

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
        CustomStaffLoginController.cls  # Dual login (VF + LWC via Site.login())
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
        customLoginForm/                # Split-screen branded login (Apex-backed)
        loginBranding/                  # Login page branding header
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
        CustomStaffLogin.page           # VF branded login for Force.com site
        CustomSelfRegister.page         # VF self-registration page
        LoginRightFrame.page            # My Domain login right-frame branding
      staticresources/
        MaplewoodLogoWhite.png          # White logo for dark backgrounds
        MaplewoodLogoDark.png           # Dark logo for light backgrounds
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
| `GrantEligibilityService` | Evaluates 6 eligibility rules | Returns structured results with per\-rule pass/fail, score, and overall boolean. Each rule independently testable |
| `GrantAwardService` | Calculates award on approval | 5\-factor scoring matrix (max 15 points), rounds to nearest $100, caps at $50,000. Breakdown returned as JSON |
| `GrantApplicationController` | CRUD operations | Uses `ApplicationInput` wrapper with `{ get; set; }` accessors for reliable deserialization, `WITH SECURITY_ENFORCED`, `AuraHandledException` |
| `GrantNotificationService` | Email notifications | `@future` method sends emails on status changes. Handles all four transitions |
| `GrantApplicationTriggerHandler` | Trigger handler | Creates Status\_History\_\_c records, publishes Platform Events, triggers notifications |
| `CustomStaffLoginController` | Login controller | Visualforce login via `Site.login()` \+ `@AuraEnabled` method for LWC\-based Experience Cloud login |
| `CustomSelfRegController` | Self\-registration | Creates portal users via `Site.createExternalUser()`, auto\-assigns Grant\_Applicant permission set |

All `@AuraEnabled` methods include `try/catch` with `AuraHandledException` for proper error surfacing to LWC components.

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

**Implementation details**: Called imperatively from LWC with a 500ms debounce for real\-time feedback. Results stored as JSON on the record upon submission. Each rule returns a structured object with `ruleName`, `passed`, `message`, and `score` for granular display in the eligibility panel.

---

## Award Calculation Engine (5 Factors)

| Factor | 1 Point | 2 Points | 3 Points |
|:-------|:--------|:---------|:---------|
| Community Impact | 50\-200 beneficiaries | 201\-1,000 | 1,001\+ |
| Track Record | 2\-5 years | 6\-15 years | 16\+ years |
| Category Priority | Arts, Workforce, Other | Youth, Senior | Public Health, Safety |
| Financial Need | $500K\-$1.99M budget | $100K\-$499K | Under $100K |
| Cost Efficiency | 41%\-50% ratio | 26%\-40% | 25% or less |

**Formula**: `Award = Amount Requested × (Total Score / 15)`, rounded to nearest $100, capped at $50,000.

**Verification**: Each factor was tested at boundary values across all three tiers. The formula was validated against the challenge specification's sample data to confirm correct rounding and cap behavior.

---

## Application Workflow

```
[Applicant fills form] → real-time eligibility feedback (6 rules, debounced)
         ↓
    [Submit] → SUBMITTED (eligibility stored as JSON)
         ↓                    ↓
    [Trigger fires]     [Platform Event published]
    Status_History__c   Grant_Application_Event__e
         ↓
    [Reviewer opens] → UNDER REVIEW
         ↓                    ↓
    [Trigger fires]     [Email notification sent]
         ↓
    ┌────┴────┐
    ↓         ↓
 APPROVED   REJECTED
 (award     (comments required,
  auto-      confirmation modal)
  calculated,
  breakdown    ↓
  stored)   [Email: rejection
    ↓        with comments]
 [Email: approval
  with award amount]
```

---

## LWC Components (11 Total)

### Experience Cloud (Applicant\-Facing) \- 6 Components

| Component | Purpose |
|:----------|:--------|
| `applicantDashboard` | Guest landing page (gradient hero with CTA), authenticated dashboard with application list, create\-new\-application and detail navigation |
| `grantApplicationForm` | Multi\-step form (Organization → Project → Review & Submit) with real\-time eligibility panel, file upload (PDF/JPG/PNG up to 5MB), inline error/success banners |
| `applicationDetail` | Read\-only view showing all fields, eligibility results, award breakdown (if approved), reviewer comments (if rejected), uploaded documents |
| `customLoginForm` | Split\-screen branded login: left panel with grant program info/stats, right panel with Apex `Site.login()` form. Responsive layout |
| `loginBranding` | Branded login page header with Maplewood logo |
| `customSelfRegister` | Redirects to Visualforce self\-registration page (required due to LWR guest context limitation) |

### Lightning App (Reviewer\-Facing) \- 2 Components

| Component | Purpose |
|:----------|:--------|
| `reviewerApplicationList` | Summary count cards (Submitted, Under Review, Approved with total $, Rejected), filters by status/eligibility, data table with clickable links, $2M fund budget overview |
| `reviewerApplicationDetail` | Full application detail, eligibility panel, document preview (native Salesforce file viewer), Approve/Reject actions with confirmation modals, breadcrumb navigation |

### Shared Child Components \- 3 Components

| Component | Purpose |
|:----------|:--------|
| `eligibilityPanel` | Reusable pass/fail rule display with green check / red X / gray dash icons. Used in both form (real\-time) and detail (stored results) contexts |
| `awardBreakdown` | 5\-factor scoring table showing each factor's earned points, overall percentage, and final award amount |
| `statusBadge` | Color\-coded badge: Blue (Submitted), Orange (Under Review), Green (Approved), Red (Rejected). WCAG\-compliant contrast |

---

## Security & Sharing

| Concern | Implementation |
|:--------|:---------------|
| Object Permissions | External: Create \+ Read on Grant\_Application\_\_c (no Edit/Delete). Internal reviewers: Read \+ Edit |
| Field\-Level Security | External users cannot see Reviewer\_\_c, Award\_Breakdown\_\_c internal details. Reviewer\_Comments\_\_c shown only when rejected |
| Record Access | OWD = Private. External users see only their own records (owner\-based sharing) |
| Permission Sets | `Grant_Reviewer` (internal), `Grant_Applicant` (external) \- least\-privilege design |
| Apex Security | `WITH SECURITY_ENFORCED` on SOQL, `Security.stripInaccessible()` on read DML, `AuraHandledException` on all controllers |
| File Access | ContentDocumentLink shares files with record owner; reviewers access via record relationship |

---

## Optional Enhancements Implemented

* [x] **Platform Events** \- `Grant_Application_Event__e` for real\-time status update broadcasting
* [x] **Apex Trigger** \- Auto\-creates `Status_History__c` records on every status transition with user and timestamp
* [x] **Email Notifications** \- `@future` email service notifies applicants on every status change with context\-specific messaging
* [x] **Validation Rules** \- Server\-side validation (EIN format with TRIM, date ordering, amount cap, rejection comments required)
* [x] **Report & Dashboard** \- Grant Program Overview dashboard (configured in org)
* [x] **Custom Branded Login** \- Split\-screen design with grant program showcase and Apex\-backed authentication
* [x] **Staff Portal Branding** \- Animated network graph and county branding on My Domain login right frame
* [x] **Input Normalization** \- EIN field trims whitespace and normalizes non\-standard dash characters before validation
* [x] **WCAG 2.1 AA Accessibility** \- ARIA attributes, keyboard navigation, focus management, screen reader live regions, semantic HTML

---

## UI/UX Design

* **Split\-Screen Login** \- Left panel showcases grant program features ($50K awards, real\-time eligibility, transparent scoring, status tracking) with stats bar; right panel holds the login form
* **Consistent Branding** \- Dark blue gradient (`#001229` → `#003068` → `#004a9f`) across Login, Registration, Landing, and Staff Portal pages
* **SLDS Compliance** \- All components use Salesforce Lightning Design System classes and patterns
* **Responsive Layout** \- Split\-screen stacks to single column on mobile (900px breakpoint). Form and eligibility panel stack on smaller screens
* **Status Badges** \- Color\-coded with WCAG\-compliant contrast ratios and semantic meaning
* **Inline Feedback** \- Error/success banners with `role="alert"` and `aria-live` (no toast in LWR), loading spinners, empty states
* **Breadcrumb Navigation** \- Context\-aware breadcrumbs on form and detail views
* **WCAG 2.1 AA** \- ARIA labels, keyboard navigation, focus management, visible focus indicators, screen reader support

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
* Verify pages: Home (applicantDashboard), Login (customLoginForm), Register
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

* [x] Experience Cloud self\-registration and branded login with split\-screen design
* [x] Two\-section application form with field validation and input normalization
* [x] Real\-time eligibility feedback (6 rules, Apex\-driven, 500ms debounce)
* [x] File upload (PDF, JPG, PNG up to 5 MB via ContentVersion)
* [x] Pre\-submit review screen with eligibility warning for ineligible applications
* [x] Applicant dashboard with status badges and award amounts
* [x] Application detail view with eligibility, award breakdown, and rejection comments
* [x] Reviewer application list with summary cards, filters, and $2M fund overview
* [x] Clickable application links in reviewer data table
* [x] Mark Under Review action with status history tracking
* [x] Approve with auto\-calculated award (5\-factor scoring matrix, rounded, capped)
* [x] Reject with required comments and confirmation modal
* [x] Award breakdown display (scoring table, percentage, final amount)
* [x] Status history tracking (Apex trigger → Status\_History\_\_c on every transition)
* [x] Platform Events for real\-time cross\-component updates
* [x] Email notifications on all status changes with context\-specific content
* [x] Server\-side validation rules (4 rules: EIN format, date order, amount cap, rejection comments)
* [x] Document preview via native Salesforce file viewer
* [x] Split\-screen login with grant program showcase
* [x] Animated staff portal branding (My Domain right frame)
* [x] SLDS styling throughout all 11 LWC components
* [x] WCAG 2.1 AA accessibility compliance (ARIA, keyboard, focus, contrast)
* [x] Apex security (FLS enforcement, stripInaccessible, CRUD checks)
* [x] Comprehensive Apex test coverage across all service and controller classes

---

## Architecture Decisions

### LWR for Experience Cloud

LWR (Lightning Web Runtime) was chosen over Aura for better performance and modern web standards per Salesforce recommendation for new builds. This decision introduced specific technical constraints (no `ShowToastEvent`, no global CSS overrides, guest user Apex limitations) that were each addressed with targeted solutions.

### Imperative Apex for Eligibility

Uses imperative calls (not @wire) because eligibility needs to fire on every field change with debouncing. Wire adapters cache results and don't support this dynamic, user\-driven pattern. A 500ms debounce prevents excessive server calls.

### Visualforce for Self\-Registration

LWR guest users cannot reliably make imperative Apex calls, so self\-registration uses a Visualforce page with an Apex controller that calls `Site.createExternalUser()`. This was identified during testing and solved without workarounds.

### JSON Storage for Results

Eligibility results and award breakdowns are stored as JSON in LongTextArea fields. This enables flexible LWC rendering of per\-rule results and per\-factor scoring without additional related objects, while preserving the exact state at time of evaluation.

### Custom Login via Apex Site.login()

The standard `community_login:loginForm` was replaced with a custom LWC (`customLoginForm`) that calls an `@AuraEnabled` Apex method using `Site.login()`. This provides full control over the login UI, error handling, and branding while using the proper Salesforce authentication mechanism. Direct form POST to the login endpoint was tested and failed in LWR context \- the Apex approach was the correct solution.

### Wrapper Class with Accessors

The `ApplicationInput` inner class uses explicit `{ get; set; }` on all `@AuraEnabled` properties. Without these, JSON deserialization silently returns null values in the Experience Cloud context. This was identified through systematic debugging of "Required fields missing" errors.

### Dual Login Experiences

Internal staff authenticate via the Salesforce My Domain login page (with `LoginRightFrame.page` animated branding). External applicants authenticate via the Experience Cloud site using `customLoginForm`, which presents a split\-screen design with grant program information alongside the login form.

### Component\-Level Backgrounds

The gradient background is applied at the LWC component level (not global CSS) because LWR Experience Cloud sites don't reliably support global CSS overrides on page\-level elements. This was discovered during testing and resolved by moving styles into component CSS with negative margin compensation.

---

## Known Limitations

* Experience Cloud site pages require manual configuration via Experience Builder after initial deployment
* Self\-registration configuration requires manual setup in Experience Cloud admin
* File upload uses base64 via Apex (~6MB heap limit for large files)
* `ShowToastEvent` does not work in LWR sites; inline banners are used instead
* Reports and Dashboards must be configured manually in the org (metadata deployment is unreliable)

---

## AI Tool Usage

* **Cursor IDE with Claude** \- Used for code generation, architecture planning, iterative debugging, and implementation guidance throughout the project
* **Example of AI help**: Generated the 5\-factor scoring matrix logic in `GrantAwardService` with proper boundary conditions, rounding to nearest $100, and $50K cap. Also generated the split\-screen login layout with responsive breakpoints
* **Example of AI correction**: Discovered that `ShowToastEvent` doesn't work in LWR Experience Cloud sites and pivoted to inline error/success banners; fixed global CSS breaking the LWR site layout by moving to component\-level gradient backgrounds; replaced form POST login with Apex `Site.login()` after discovering Experience Cloud doesn't reliably process raw form POSTs; identified silent JSON deserialization failure in `ApplicationInput` wrapper and fixed by adding `{ get; set; }` accessors
* **Verification approach**: Every logic path was manually tested \- eligibility rules at boundary values, award calculations against spec data, login/registration flows, error handling, and edge cases. AI suggestions were verified before integration
