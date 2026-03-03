# Maplewood County Community Development Grant System

## Salesforce Development Track

**Document Version:** 1.0
**Date:** March 1, 2026
**Duration:** 1 Week (5 Working Days)
**Track:** Salesforce (LWC, Apex, Experience Cloud)

---

## Table of Contents

1. [Challenge Overview](#1-challenge-overview)
2. [Business Context & Problem Statement](#2-business-context--problem-statement)
3. [Personas & User Stories](#3-personas--user-stories)
4. [Grant Application Form \- Field Specifications](#4-grant-application-form---field-specifications)
5. [Eligibility Engine](#5-eligibility-engine)
6. [Award Calculation Engine](#6-award-calculation-engine)
7. [Application Workflow](#7-application-workflow)
8. [Salesforce Architecture & Implementation](#8-salesforce-architecture--implementation)
9. [UI/UX Requirements](#9-uiux-requirements)
10. [Evaluation Criteria](#10-evaluation-criteria)
11. [Daily Milestones](#11-daily-milestones)
12. [Submission Guidelines](#12-submission-guidelines)
13. [Appendix A \- Sample Data](#appendix-a---sample-data)
14. [Appendix B \- Wireframes](#appendix-b---wireframes)
15. [Appendix C \- Glossary](#appendix-c---glossary)

---

## 1. Challenge Overview

### What You Are Building

You will build a **Community Development Grant Management System** on the Salesforce Platform for a fictional county government called **Maplewood County**. This system allows nonprofit organizations to apply online for community development grants of up to $50,000 through an Experience Cloud site, and allows government staff to review, approve, or reject those applications through an internal Lightning App.

The system has two engines that make it more than a simple form\-and\-review app:

* **Eligibility Engine** \- Built in Apex, this engine evaluates 6 eligibility rules against the application data. On the Experience Cloud side (LWC), it runs in real time as the applicant fills the form, showing green checkmarks or red X indicators. On submission, the Apex service verifies eligibility server\-side.
* **Award Calculation Engine** \- Built in Apex, this engine auto\-calculates the grant award amount based on a 5\-factor scoring matrix when a reviewer approves the application.

### What "Done" Looks Like

By the end of the week, you should have a working system where:

* A nonprofit representative can register via Experience Cloud, log in, fill out a two\-section grant application with real\-time eligibility feedback, upload a document, and submit
* The applicant can see their application status on a dashboard page
* A government reviewer can log in to an internal Lightning App, see pending applications with eligibility recommendations, review details, and approve or reject
* When approved, the award amount is auto\-calculated and visible to both the reviewer and the applicant
* When rejected, the reviewer's comments are visible to the applicant

### How You Will Be Evaluated

You are **not** expected to build a production\-ready, polished system. You **are** expected to demonstrate:

* Problem\-solving ability using AI\-assisted coding tools
* Understanding of the Salesforce platform (Apex, LWC, Experience Cloud, custom objects)
* Thoughtful user experience decisions
* Working end\-to\-end functionality
* Clean, well\-structured Apex and LWC code
* Properly implemented eligibility engine and award calculator in Apex

---

## 2. Business Context & Problem Statement

### The Organization

**Maplewood County Government** is a mid\-sized county in the United States with approximately 250,000 residents. The county's Office of Community Development administers a grant program that distributes $2 million annually to local nonprofits for community improvement projects.

### Current Pain Points

**For Applicants (Nonprofits):**

* Must submit paper applications by mail or in person
* No way to know if they qualify before spending hours on the application
* No visibility into where their application stands after submission
* Award amounts feel arbitrary \- no transparency into funding decisions

**For Government Staff (Reviewers):**

* Paper applications pile up with no prioritization
* Manually checking eligibility criteria is tedious and error\-prone
* Calculating award amounts involves a spreadsheet that only one person knows
* No audit trail of decisions

### The Goal

Build a Salesforce\-based grant management system that:

1. Lets nonprofits apply through an Experience Cloud site with real\-time eligibility feedback
2. Automatically screens applications against eligibility rules (Apex)
3. Gives reviewers a clear recommendation via an internal Lightning App
4. Auto\-calculates award amounts using a consistent Apex\-driven formula
5. Provides a dashboard for applicants to track status

---

## 3. Personas & User Stories

### Persona 1: Diana Torres \- The Applicant

| Attribute | Detail |
|:----------|:-------|
| **Age** | 38 |
| **Role** | Executive Director of "Youth Forward," a nonprofit youth mentorship program |
| **Tech Comfort** | Moderate \- uses web apps daily |
| **Goal** | Apply for a Community Development Grant to fund an after\-school mentorship expansion |
| **Frustration** | "I spent 3 days on a paper application last year and got rejected because we didn't meet one criterion I didn't even know about." |

#### Diana's User Stories

| ID | User Story | Priority | Acceptance Criteria |
|:---|:-----------|:---------|:--------------------|
| US\-101 | As an applicant, I want to register and log in via the Experience Cloud site | Must Have | Self\-registration works. Login redirects to applicant dashboard. |
| US\-102 | As an applicant, I want to see a dashboard showing my grant applications | Must Have | LWC component shows list of my applications with: Application ID (Name field), Project Title, Date Submitted, Status, Award Amount (if approved). Empty state shows "Start New Application" button. |
| US\-103 | As an applicant, I want to fill out a two\-section grant application | Must Have | Section 1: Organization Info. Section 2: Project Details. Required fields marked. Can navigate between sections. |
| US\-104 | As an applicant, I want real\-time eligibility feedback as I fill out the form | Must Have | LWC calls Apex eligibility service on field change. Each rule shows green check or red X. Overall status displayed. |
| US\-105 | As an applicant, I want to upload a supporting document | Must Have | File uploaded as a ContentVersion linked to the application record. Accepted: PDF, JPG, PNG up to 5 MB. |
| US\-106 | As an applicant, I want to review my application before submitting | Should Have | Read\-only summary LWC showing all fields and eligibility status before final submit. |
| US\-107 | As an applicant, I want to submit even if not fully eligible | Must Have | System warns but does not block. Reviewer makes final call. |
| US\-108 | As an applicant, I want to see the award amount if approved | Must Have | Award amount field visible on application detail after approval. |
| US\-109 | As an applicant, I want to see reviewer comments if rejected | Should Have | Reviewer comments field visible on application detail after rejection. |

---

### Persona 2: Marcus Johnson \- The Reviewer

| Attribute | Detail |
|:----------|:-------|
| **Age** | 42 |
| **Role** | Grants Analyst at Maplewood County |
| **Tech Comfort** | High \- uses Salesforce daily |
| **Goal** | Efficiently review grant applications with system\-generated recommendations |
| **Frustration** | "I manually check every eligibility criterion and calculate awards in a spreadsheet." |

#### Marcus's User Stories

| ID | User Story | Priority | Acceptance Criteria |
|:---|:-----------|:---------|:--------------------|
| US\-201 | As a reviewer, I want to see pending applications in a Lightning App | Must Have | Lightning App page with a list view or LWC showing applications sorted by date. Each row: Application Name, Org Name, Project Title, Date Submitted, Eligibility Status, Application Status. |
| US\-202 | As a reviewer, I want to open an application and see details plus eligibility results | Must Have | Record page or LWC shows all fields, uploaded document, and eligibility check results (each rule with pass/fail). |
| US\-203 | As a reviewer, I want to approve or reject with award auto\-calculated on approval | Must Have | Custom actions or LWC buttons. Approve triggers Apex award calculator, shows breakdown, asks for confirmation. Reject requires comment. |
| US\-204 | As a reviewer, I want summary counts by status | Should Have | Dashboard component or LWC showing counts: Submitted, Under Review, Approved (with total $), Rejected. |
| US\-205 | As a reviewer, I want to filter by eligibility and status | Should Have | Filter controls on the application list. |

---

### Persona 3: Director Priya Sharma (Stretch Goal)

| ID | User Story | Priority |
|:---|:-----------|:---------|
| US\-301 | As an administrator, I want a Salesforce report showing applications by status and total funds awarded | Nice to Have |

---

## 4. Grant Application Form \- Field Specifications

### Section 1: Organization Information

| Field Name | Salesforce Field Type | API Name (Suggested) | Required | Validation | Help Text |
|:-----------|:---------------------|:---------------------|:---------|:-----------|:----------|
| Organization Name | Text(200) | Organization_Name\_\_c | Yes | 2\-100 chars | Legal name of the organization |
| EIN (Tax ID) | Text(12) | EIN\_\_c | Yes | Regex: ^\d{2}\-\d{7}$ | IRS Employer Identification Number |
| Organization Type | Picklist | Organization_Type\_\_c | Yes | Values: 501(c)(3), 501(c)(4), Community\-Based Organization, Faith\-Based Organization, For\-Profit Business, Government Agency, Individual | Organization classification |
| Year Founded | Number(4,0) | Year_Founded\_\_c | Yes | 1800 \- current year | Year the organization was established |
| Annual Operating Budget | Currency(16,2) | Annual_Budget\_\_c | Yes | $0 \- $100,000,000 | Total annual budget |
| Number of Full\-Time Employees | Number(5,0) | Num_Employees\_\_c | Yes | 0 \- 9999 | Full\-time staff count |
| Primary Contact Name | Text(100) | Contact_Name\_\_c | Yes | 2\-50 chars | Primary contact first and last name |
| Primary Contact Email | Email | Contact_Email\_\_c | Yes | Valid email | Correspondence email |
| Primary Contact Phone | Phone | Contact_Phone\_\_c | Yes | Valid phone | Contact phone number |
| Organization Address | TextArea(500) | Organization_Address\_\_c | Yes | Non\-empty | Physical address |
| Mission Statement | LongTextArea(2000) | Mission_Statement\_\_c | Yes | 20\-500 chars | Organization's mission |

### Section 2: Project Details

| Field Name | Salesforce Field Type | API Name (Suggested) | Required | Validation | Help Text |
|:-----------|:---------------------|:---------------------|:---------|:-----------|:----------|
| Project Title | Text(200) | Project_Title\_\_c | Yes | 5\-100 chars | Descriptive project title |
| Project Category | Picklist | Project_Category\_\_c | Yes | Values: Youth Programs, Senior Services, Public Health, Neighborhood Safety, Arts & Culture, Workforce Development, Other | Best\-fit category |
| Project Description | LongTextArea(5000) | Project_Description\_\_c | Yes | 50\-2000 chars | Goals, activities, expected outcomes |
| Target Population Served | Text(500) | Target_Population\_\_c | Yes | 5\-200 chars | Who benefits? |
| Estimated Beneficiaries | Number(7,0) | Num_Beneficiaries\_\_c | Yes | 1 \- 1,000,000 | Direct beneficiaries |
| Total Project Cost | Currency(16,2) | Total_Project_Cost\_\_c | Yes | $100 \- $10,000,000 | Total project cost |
| Amount Requested | Currency(16,2) | Amount_Requested\_\_c | Yes | $100 \- $50,000 | Grant amount requested |
| Project Start Date | Date | Project_Start_Date\_\_c | Yes | At least 30 days in future | Project start |
| Project End Date | Date | Project_End_Date\_\_c | Yes | After start, within 24 months | Project end |
| Previously Funded | Checkbox | Previously_Funded\_\_c | No | \- | Has org received Maplewood grant before? |
| Supporting Document | \- (use ContentDocumentLink) | \- | Yes | PDF, JPG, PNG; max 5 MB | Upload supporting docs |

### Additional System Fields on the Custom Object

| Field Name | Salesforce Field Type | API Name (Suggested) | Description |
|:-----------|:---------------------|:---------------------|:------------|
| Eligibility Score | Number(2,0) | Eligibility_Score\_\_c | How many of 6 rules passed |
| Is Eligible | Checkbox | Is_Eligible\_\_c | All 6 rules passed? |
| Eligibility Results | LongTextArea(10000) | Eligibility_Results\_\_c | JSON string of rule\-by\-rule results |
| Application Status | Picklist | Status\_\_c | Values: Submitted, Under Review, Approved, Rejected |
| Award Amount | Currency(16,2) | Award_Amount\_\_c | Auto\-calculated on approval |
| Award Breakdown | LongTextArea(5000) | Award_Breakdown\_\_c | JSON string of scoring factors |
| Reviewer Comments | LongTextArea(5000) | Reviewer_Comments\_\_c | Comments from reviewer |
| Reviewed Date | DateTime | Reviewed_Date\_\_c | When the review action was taken |
| Reviewer | Lookup(User) | Reviewer\_\_c | The reviewer who took action |

---

## 5. Eligibility Engine

### How It Works

The eligibility engine is an **Apex service class** that evaluates 6 rules. On the Experience Cloud side, an LWC calls this Apex method (via `@wire` or imperative call) whenever relevant fields change, displaying real\-time feedback. On submission, the Apex controller calls the same service to store the verified result.

### The 6 Eligibility Rules

| Rule # | Rule Name | Logic | Pass Message | Fail Message |
|:-------|:----------|:------|:-------------|:-------------|
| 1 | Nonprofit Status | Organization Type is one of: 501(c)(3), 501(c)(4), Community\-Based Organization, Faith\-Based Organization | "Eligible organization type" | "Only nonprofit and community organizations are eligible" |
| 2 | Minimum Operating History | (Current Year \- Year Founded) >= 2 | "Organization has been operating for X years" | "Organization must be at least 2 years old" |
| 3 | Budget Cap | Annual Operating Budget < 2,000,000 | "Operating budget is within limit" | "Organizations with budgets of $2M or more are not eligible" |
| 4 | Funding Ratio | Amount Requested <= 50% of Total Project Cost | "Requested amount is X% of project cost" | "Requested amount cannot exceed 50% of total project cost" |
| 5 | Maximum Request | Amount Requested <= 50,000 | "Requested amount is within the $50,000 maximum" | "Maximum grant amount is $50,000" |
| 6 | Minimum Impact | Estimated Beneficiaries >= 50 | "Project will serve X beneficiaries" | "Project must serve at least 50 beneficiaries" |

### Apex Implementation Guidance

Build an Apex service class (e.g., `GrantEligibilityService`) that:

* Accepts the relevant field values as parameters (organization type, year founded, annual budget, amount requested, total project cost, number of beneficiaries)
* Evaluates all 6 rules and returns a structured result containing: each rule's ID, name, pass/fail status, and message; the total number of rules passed; and an overall eligibility boolean
* Is annotated with `@AuraEnabled` so it can be called from LWC
* Includes an Apex test class with test coverage

### LWC Integration Guidance

In your application form LWC:

* Call the Apex eligibility service imperatively (not via `@wire`) whenever a relevant field value changes
* Display the results in a sidebar panel using SLDS styling with `slds-icon-utility-check` (green) and `slds-icon-utility-close` (red) icons
* Use inner wrapper classes annotated with `@AuraEnabled` to pass structured data back to the LWC

### Important Behavior

* Rules evaluate as soon as the relevant field has a value
* Empty fields show a gray/neutral state
* The eligibility result is stored on the GrantApplication\_\_c record on submission
* The reviewer sees the same eligibility results on the record page

---

## 6. Award Calculation Engine

### When It Runs

The award calculation engine runs **only** when a reviewer clicks "Approve." It is an Apex method triggered by a custom LWC button or Quick Action on the record page.

### Scoring Matrix

| Factor | What It Measures | 1 Point | 2 Points | 3 Points |
|:-------|:-----------------|:--------|:---------|:---------|
| Community Impact | Estimated beneficiaries | 50 \- 200 | 201 \- 1,000 | 1,001 or more |
| Organization Track Record | Years operating | 2 \- 5 years | 6 \- 15 years | 16 or more years |
| Project Category Priority | Project category | Arts & Culture, Workforce Development, Other | Youth Programs, Senior Services | Public Health, Neighborhood Safety |
| Financial Need | Annual operating budget | $500K \- $1,999,999 | $100K \- $499,999 | Under $100,000 |
| Cost Efficiency | Requested amount / total cost | 41% \- 50% | 26% \- 40% | 25% or less |

### Award Formula

```
Total Score      = sum of all 5 factor scores (range: 5 to 15)
Award Percentage = Total Score / 15
Award Amount     = Amount Requested × Award Percentage
Award Amount     = round to nearest $100
Award Amount     = cap at $50,000
```

### Worked Example

* Beneficiaries: 500 (Score: 2), Years Operating: 11 (Score: 2), Category: Youth Programs (Score: 2), Budget: $320K (Score: 2), Request Ratio: 42% (Score: 1)
* Total Score = 9 / 15 = 60%
* Award = $40,000 x 60% = $24,000

### Apex Implementation Guidance

Build a separate Apex service class (e.g., `GrantAwardService`) that:

* Accepts the Application record Id as a parameter
* Queries the application record to get the relevant field values
* Scores each of the 5 factors using the matrix above
* Calculates the total score, award percentage, raw award amount, rounds to the nearest $100, and caps at $50,000
* Returns a structured result with individual factor scores, total score, max score, award percentage, and final award amount
* Is annotated with `@AuraEnabled` so it can be called from a reviewer LWC

On approval confirmation, the Apex code should update the application record with the award amount, a JSON\-serialized breakdown of the scores, the current timestamp, the reviewer's User Id, and set the status to "Approved."

---

## 7. Application Workflow

### State Machine

```
[Applicant fills form in Experience Cloud]
    |
    |  LWC calls Apex eligibility service in real time
    |  (pass/fail indicators visible on form)
    |
    v
[Applicant submits] ──────> SUBMITTED
                              |  (eligibility stored on record)
                              |
                    [Reviewer opens in Lightning App] ──> UNDER REVIEW
                                              |
                              +---------------+----------------+
                              |                                |
                    [Reviewer approves]              [Reviewer rejects]
                              |                                |
                    Apex calculates award            Comment required
                              |                                |
                          APPROVED                         REJECTED
                     (Award_Amount__c set)       (Reviewer_Comments__c set)
```

### Status Definitions

| Status | Description | Who Sets It |
|:-------|:------------|:------------|
| Submitted | Application received | Apex controller on insert |
| Under Review | Reviewer has opened it | Reviewer via LWC or Quick Action |
| Approved | Approved with auto\-calculated award | Reviewer via LWC \- triggers GrantAwardService |
| Rejected | Rejected with reason | Reviewer via LWC \- requires Reviewer_Comments\_\_c |

---

## 8. Salesforce Architecture & Implementation

### Object Model

```
┌─────────────────────────────────┐
│   Grant_Application__c          │
│   (Custom Object)               │
├─────────────────────────────────┤
│ Name (Auto-Number: APP-{0000})  │
│ Organization_Name__c            │
│ EIN__c                          │
│ Organization_Type__c (Picklist) │
│ Year_Founded__c                 │
│ Annual_Budget__c (Currency)     │
│ ... (all form fields)           │
│ Status__c (Picklist)            │
│ Eligibility_Score__c            │
│ Is_Eligible__c (Checkbox)       │
│ Eligibility_Results__c (LTA)    │
│ Award_Amount__c (Currency)      │
│ Award_Breakdown__c (LTA)        │
│ Reviewer_Comments__c (LTA)      │
│ Reviewer__c (Lookup → User)     │
│ Reviewed_Date__c (DateTime)     │
├─────────────────────────────────┤
│ Related: ContentDocumentLink    │
│ Related: Status_History__c      │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│   Status_History__c             │
│   (Custom Object - Child)       │
├─────────────────────────────────┤
│ Application__c (MD Relationship)│
│ Old_Status__c (Text)            │
│ New_Status__c (Text)            │
│ Changed_By__c (Lookup → User)   │
│ Comments__c (LTA)               │
│ Changed_At__c (DateTime)        │
└─────────────────────────────────┘
```

### Component Architecture

| Component | Where It Lives | Purpose |
|:----------|:---------------|:--------|
| **grantApplicationForm** (LWC) | Experience Cloud Page | Two\-section form with eligibility panel. Calls GrantEligibilityService. |
| **applicantDashboard** (LWC) | Experience Cloud Page | Shows logged\-in user's applications with status badges. |
| **applicationDetail** (LWC) | Experience Cloud Page | Read\-only view of submitted application with eligibility, award, comments. |
| **reviewerApplicationList** (LWC) | Lightning App Page | List of all applications with filters for eligibility and status. |
| **reviewerApplicationDetail** (LWC) | Lightning App Page or Record Page | Full detail view with eligibility panel and approve/reject actions. |
| **awardBreakdown** (LWC) | Used within reviewerApplicationDetail | Displays the scoring matrix breakdown and calculated award on approval. |
| **GrantEligibilityService** (Apex) | Backend | Eligibility check logic (6 rules). Called by LWC and by controller on submit. |
| **GrantAwardService** (Apex) | Backend | Award calculation logic (5 factors). Called on approval. |
| **GrantApplicationController** (Apex) | Backend | Handles CRUD operations: create application, update status, query lists. |

### Experience Cloud Setup

| Item | Configuration |
|:-----|:-------------|
| Site Type | Aura or LWR (your choice \- LWR is recommended for new builds) |
| Authentication | Self\-registration enabled for external users (Customer Community license or Customer Community Plus) |
| External User Profile | Use a custom profile or clone Customer Community User |
| Pages | Home/Landing, Login, Registration, Applicant Dashboard, Application Form, Application Detail |
| Guest User | Landing page accessible to guest user. All other pages require login. |

### Security & Sharing

| Concern | Implementation |
|:--------|:--------------|
| Object Permissions | External users: Create and Read on Grant_Application\_\_c. No Edit/Delete. |
| Field\-Level Security | External users cannot see: Reviewer\_\_c, Reviewer_Comments\_\_c (until status is Rejected), Award_Breakdown\_\_c internal details. Use FLS or LWC conditional rendering. |
| Record Access | External users see only their own records. Use OWD = Private + "Grant access using hierarchies" unchecked. Owner\-based sharing. |
| Internal Reviewers | Custom Permission Set: "Grant Reviewer" with Read/Edit on all Grant_Application\_\_c fields. |
| Apex Security | Use `WITH SECURITY_ENFORCED` or `stripInaccessible()` in SOQL/DML. |
| File Access | ContentDocumentLink shares the file with the application record owner. Reviewers access via the record. |

### Salesforce\-Specific Notes

* Use `lightning-record-edit-form` for quick prototyping or build fully custom LWC forms for more control over the eligibility panel integration
* Use `lightning-datatable` for the reviewer's application list
* Use `lightning-icon` with `utility:check` and `utility:close` for eligibility indicators
* Use `lightning-badge` for status display
* Follow SLDS (Salesforce Lightning Design System) for all styling
* Store eligibility results as JSON in a Long Text Area field (parsed in LWC for display)
* Use `NavigationMixin` for page navigation in Experience Cloud

### Optional Enhancements (Bonus Points)

* **Salesforce Flow** for the approval workflow (Screen Flow or Record\-Triggered Flow)
* **Platform Events** for real\-time status updates
* **Apex Trigger** on Grant_Application\_\_c to auto\-create Status_History\_\_c records on status change
* **Email Alert** (Workflow or Flow) to notify applicant when status changes
* **Validation Rules** for server\-side field validation (in addition to Apex)
* **Report & Dashboard** for the administrator persona

---

## 9. UI/UX Requirements

### Design Principles

| Principle | What It Means |
|:----------|:-------------|
| **Use SLDS** | All components should use Salesforce Lightning Design System classes and components |
| **Clarity** | User always knows where they are and what to do |
| **Guidance** | Eligibility panel actively guides the applicant |
| **Feedback** | Loading spinners (`lightning-spinner`), toast messages, error states |
| **Consistency** | Same patterns across all pages |

### Required Pages / Components

#### Experience Cloud (Applicant\-Facing)

**Landing Page:** Program description, Register and Login buttons.

**Applicant Dashboard (LWC):** Welcome message, "New Application" button, table or card list of applications with: App ID, Project Title, Date, Status Badge, Award Amount. Empty state message.

**Application Form (LWC):** Two sections with tab or step navigation. Eligibility panel alongside the form. File upload area. "Review & Submit" button.

**Application Detail (LWC):** Read\-only field display. Status badge. Eligibility results. Award amount and breakdown (if approved). Reviewer comments (if rejected).

#### Lightning App (Reviewer\-Facing)

**Reviewer Dashboard (LWC on App Page):** Summary count cards (Submitted, Under Review, Approved with total $, Rejected). Filter controls. Application data table.

**Reviewer Detail (LWC on App Page or Record Page Override):** All application fields. Eligibility panel with pass/fail. Document preview/download. Approve/Reject buttons with confirmation modal. Award breakdown display on approval.

### Status Badge Colors

| Status | SLDS Badge Variant | Color |
|:-------|:-------------------|:------|
| Submitted | `slds-badge` (default or custom blue) | Blue |
| Under Review | `slds-badge` (warning/custom) | Orange |
| Approved | `slds-badge_success` or custom | Green |
| Rejected | `slds-badge_error` or custom | Red |

### Eligibility Indicator Icons

| State | Icon | Color |
|:------|:-----|:------|
| Passing | `utility:check` | Green (#1A652A) |
| Failing | `utility:close` | Red (#993333) |
| Not Yet Evaluated | `utility:dash` or `utility:question` | Gray (#6B7280) |

---

## 10. Evaluation Criteria

### Scoring Rubric (100 Points Total)

| Category | Points | What We're Looking For |
|:---------|:-------|:-----------------------|
| **Functionality** | 30 | End\-to\-end workflow: apply, review, approve/reject |
| **Eligibility Engine** | 15 | All 6 rules in Apex, real\-time LWC feedback, results stored on record |
| **Award Calculator** | 10 | 5\-factor scoring in Apex, correct formula, breakdown displayed |
| **Code Quality** | 15 | Clean Apex (bulkified, secure), modular LWC, separation of concerns |
| **User Experience** | 15 | SLDS usage, form guidance, loading states, error handling |
| **Problem Solving & AI Usage** | 10 | Smart decisions, effective AI usage, can explain the code |
| **Documentation** | 5 | README, setup instructions, design notes |

### Functionality Breakdown (30 Points)

| Sub\-Criteria | Points |
|:-------------|:-------|
| Experience Cloud registration & login | 5 |
| Application form with validation | 7 |
| File upload (ContentVersion) | 3 |
| Applicant dashboard with status | 5 |
| Reviewer list and detail | 5 |
| Approve/reject workflow | 5 |

### Salesforce\-Specific Code Quality (15 Points)

| Sub\-Criteria | Points |
|:-------------|:-------|
| Apex follows best practices (bulkified, no SOQL in loops, error handling) | 5 |
| LWC is modular (separate components, not one monolith) | 3 |
| Security: FLS, CRUD checks, sharing rules configured | 4 |
| Object model is clean (proper field types, relationships, naming) | 3 |

---

## 11. Daily Milestones

### Day 1 (Monday): Org Setup & Data Model

**Morning:**

* Read this document completely
* Set up a Salesforce Developer Org (sign up free at developer.salesforce.com if you don't have one)
* Create the Grant_Application\_\_c custom object with all fields
* Create the Status_History\_\_c child object
* Create picklist values, validation rules, page layouts

**Afternoon:**

* Set up Experience Cloud site with self\-registration
* Configure profiles, permission sets, sharing rules
* Create reviewer user accounts
* Test: can log in as external user and internal reviewer

**Checkpoint:**

* [ ] Custom objects created with all fields
* [ ] Experience Cloud site is accessible
* [ ] External user registration works
* [ ] Reviewer can log in to the Lightning App

---

### Day 2 (Tuesday): Eligibility Engine & Application Form

**Morning:**

* Build GrantEligibilityService Apex class with all 6 rules
* Write Apex test class for eligibility service
* Build the application form LWC (Section 1) with eligibility panel

**Afternoon:**

* Complete Section 2 of the form LWC
* Wire eligibility checks to field changes in LWC
* Implement file upload (ContentVersion)
* Build the Apex controller method to save the application

**Checkpoint:**

* [ ] Eligibility engine works in Apex (test class passes)
* [ ] Form LWC shows real\-time eligibility feedback
* [ ] Application saves to Grant_Application\_\_c
* [ ] File upload works

---

### Day 3 (Wednesday): Dashboards & Review Workflow

**Morning:**

* Build applicant dashboard LWC (list of my applications)
* Add to Experience Cloud site
* Build reviewer application list LWC

**Afternoon:**

* Build reviewer detail view with eligibility results display
* Implement GrantAwardService Apex class
* Build approve/reject actions (LWC buttons with confirmation)
* Ensure status updates reflect on applicant dashboard

**Checkpoint:**

* [ ] Applicant dashboard shows applications with status
* [ ] Reviewer can see and open applications
* [ ] Approve triggers award calculation with breakdown
* [ ] Reject stores comments
* [ ] Status updates visible to applicant

---

### Day 4 (Thursday): Polish & Detail Views

**Morning:**

* Build applicant application detail view (post\-submit)
* Build pre\-submit review screen
* Add filtering on reviewer list

**Afternoon:**

* Add Apex trigger or Flow for Status_History\_\_c records
* Add email notification on status change (optional)
* Fix bugs, improve error handling
* Test edge cases in eligibility and award engines

**Checkpoint:**

* [ ] Application detail views work for both personas
* [ ] Pre\-submit review works
* [ ] Status history is tracked
* [ ] No major bugs

---

### Day 5 (Friday): Testing, Documentation & Submission

**Morning:**

* Full end\-to\-end testing
* Fix critical bugs
* Stretch features (reports, dashboards, flows)

**Afternoon:**

* Write README
* Document design decisions
* Record demo video
* Final commit / package

**Checkpoint:**

* [ ] End\-to\-end flow works
* [ ] README complete
* [ ] Demo video recorded
* [ ] Code committed

---

## 12. Submission Guidelines

### What to Submit

| Item | Format | Required |
|:-----|:-------|:---------|
| Source Code | Git repository with full SFDX project structure | Yes |
| README | Markdown in repo root | Yes |
| Demo Video | 3\-5 minute screen recording | Yes |

### README Template

```markdown
# Maplewood County Grant Portal - Salesforce Track

## Salesforce Components
- Custom Objects: [list]
- Apex Classes: [list]
- LWC Components: [list]
- Experience Cloud Site: [name]

## Prerequisites
- Salesforce CLI (sf/sfdx)
- A Salesforce Developer Org (free at developer.salesforce.com)

## Setup Instructions
1. Clone the repository
2. Authenticate to your org: `sf org login web`
3. Push source: `sf project deploy start`
4. Assign permission sets: [commands]
5. Load seed data: [steps]
6. Access the Experience Cloud site at: [URL]

## Test Credentials
- Applicant: Register via Experience Cloud
- Reviewer: [username] / [password or login method]

## Features Implemented
- [x] Experience Cloud registration
- [x] Application form with eligibility engine
- [x] Award calculation engine
- [ ] ... etc.

## Eligibility Engine
- [Apex class name and approach]

## Award Calculator
- [Apex class name and approach]

## Known Limitations
- [List]

## AI Tool Usage
- [Which tools, one help example, one correction example]
```

### Demo Video

Walk through:

1. Experience Cloud landing page
2. Register as a new applicant
3. Fill the application — show eligibility indicators updating
4. Trigger a failing rule, then fix it
5. Submit
6. Show applicant dashboard
7. Switch to reviewer (Lightning App)
8. Open the application — show eligibility results
9. Approve — show award calculation breakdown
10. Switch back to applicant — show approved status and award amount

---

## Appendix A \- Sample Data

### Sample Grant Application

**Section 1:**

| Field | Value |
|:------|:------|
| Organization Name | Youth Forward Inc. |
| EIN | 52\-1234567 |
| Organization Type | 501(c)(3) |
| Year Founded | 2015 |
| Annual Operating Budget | $320,000 |
| Full\-Time Employees | 8 |
| Contact Name | Diana Torres |
| Contact Email | diana@youthforward.org |
| Contact Phone | (410) 555\-0142 |
| Address | 742 Oak Street, Maplewood, MD 21201 |
| Mission Statement | Youth Forward empowers at\-risk youth through mentorship, academic support, and leadership development programs. |

**Section 2:**

| Field | Value |
|:------|:------|
| Project Title | After\-School Mentorship Expansion |
| Project Category | Youth Programs |
| Project Description | Expand our after\-school mentorship program from 2 to 5 locations across East Maplewood, serving an additional 200 students with one\-on\-one mentoring, homework help, and career exploration workshops. |
| Target Population | At\-risk youth ages 14\-18 in East Maplewood |
| Beneficiaries | 500 |
| Total Project Cost | $95,000 |
| Amount Requested | $40,000 |
| Start Date | 2026\-05\-01 |
| End Date | 2027\-04\-30 |
| Previously Funded | No |

**Eligibility: Eligible (6/6)** | **Award: $24,000 (Score 9/15 = 60%)**

---

## Appendix B \- Wireframes

### Application Form with Eligibility Panel (LWC)

```
┌────────────────────────────────────────────────────────────────────┐
│  MAPLEWOOD COUNTY GRANT PROGRAM                       [Logout]    │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌──────────────────────────────┐  ┌────────────────────────────┐ │
│  │ SECTION 1: Organization      │  │ ELIGIBILITY CHECK          │ │
│  │                              │  │                            │ │
│  │ Organization Name *          │  │ ✅ Nonprofit Status        │ │
│  │ ┌──────────────────────────┐ │  │ ✅ Operating History       │ │
│  │ │ Youth Forward Inc.       │ │  │ ✅ Budget Under $2M        │ │
│  │ └──────────────────────────┘ │  │ ⬜ Funding Ratio           │ │
│  │                              │  │ ⬜ Under $50K Max          │ │
│  │ Organization Type *          │  │ ⬜ Min. Beneficiaries      │ │
│  │ ┌────────────────────── ▼ ─┐ │  │                            │ │
│  │ │ 501(c)(3)                │ │  │ 3 of 6 evaluated          │ │
│  │ └──────────────────────────┘ │  │ All passing so far ✅      │ │
│  │                              │  └────────────────────────────┘ │
│  │ Year Founded *               │                                 │
│  │ ┌──────────────────────────┐ │                                 │
│  │ │ 2015                     │ │                                 │
│  │ └──────────────────────────┘ │                                 │
│  │                              │                                 │
│  │ ... (more fields) ...        │                                 │
│  │                              │                                 │
│  │              [Next: Project Details →]                         │
│  └──────────────────────────────┘                                 │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## Appendix C \- Glossary

| Term | Definition |
|:-----|:-----------|
| **LWC** | Lightning Web Components \- Salesforce's modern web component framework |
| **Apex** | Salesforce's server\-side programming language (similar to Java) |
| **Experience Cloud** | Salesforce's platform for building external\-facing websites (formerly Community Cloud) |
| **SLDS** | Salesforce Lightning Design System \- the design framework for consistent Salesforce UIs |
| **Custom Object** | A database table you define in Salesforce (like Grant_Application\_\_c) |
| **Picklist** | A dropdown field type in Salesforce |
| **ContentVersion** | The Salesforce object that stores file uploads |
| **ContentDocumentLink** | The junction object that links a file to a record |
| **SOQL** | Salesforce Object Query Language \- like SQL but for Salesforce |
| **FLS** | Field\-Level Security \- controls which fields a user profile can see or edit |
| **OWD** | Organization\-Wide Defaults \- the baseline sharing setting for records |
| **Permission Set** | A collection of permissions that can be assigned to users (additive to their profile) |
| **Developer Org** | A free Salesforce environment for development, obtained at developer.salesforce.com |
| **@AuraEnabled** | An Apex annotation that exposes a method to Lightning components |
| **Quick Action** | A Salesforce button that triggers a specific action on a record page |
| **Record\-Triggered Flow** | A Salesforce automation that runs when a record is created or updated |

---

**Good luck! We're excited to see what you build.**
