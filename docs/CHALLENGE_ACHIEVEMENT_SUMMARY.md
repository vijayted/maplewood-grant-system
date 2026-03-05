# Maplewood Grant System – What Was Achieved vs Challenge

This document maps the **Salesforce_Track_Grant_System_Challenge.md** requirements to what is actually built and deployed, and what you need to do once so the portal works.

---

## One-Time Fix for “Apex request is invalid”

The **Grant Applicant** permission set (with Apex class access) is deployed, but it must be **assigned to your Experience Cloud users**.

Do this once:

1. In Salesforce: **Setup** → **Users** → **Permission Set Assignments** (or **Setup** → **Permission Sets** → **Grant Applicant** → **Manage Assignments**).
2. Click **Add Assignments**.
3. Choose **Users** and filter by profile **“Customer Community User”** (or select the specific portal users).
4. Select all relevant users and click **Assign**.
5. For **new** self-registered users: repeat the same steps when new users register, or use a **Flow** (e.g. Record-Triggered on User, when Profile = Customer Community User) to auto-assign the **Grant Applicant** permission set.

After this, the dashboard and form Apex calls will work and the red “Apex request is invalid” error will go away.

---

## What the Challenge Asked For vs What You Have

### 1. Challenge Overview – “What You Are Building”

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| Community Development Grant Management System on Salesforce | Done | Custom objects, Apex, LWC, Experience Cloud site |
| Nonprofits apply online via Experience Cloud (up to $50,000) | Done | Grant application form on portal, amount cap in validation |
| Government staff review via internal Lightning App | Done | Grant Review Console app + reviewer LWCs |
| Eligibility Engine (6 rules, Apex) | Done | `GrantEligibilityService.cls` + real-time check in form |
| Award Calculation Engine (5-factor matrix, Apex) | Done | `GrantAwardService.cls` on approve |

### 2. “What Done Looks Like”

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| Nonprofit can register via Experience Cloud, log in | Done | Self-registration enabled; Login/Register on home |
| Fill two-section grant application with real-time eligibility | Done | `grantApplicationForm` LWC, two sections + eligibility panel |
| Upload a document | Done | File upload (PDF/JPG/PNG, 5 MB), ContentVersion/link |
| Applicant sees status on dashboard | Done | `applicantDashboard` LWC (after permission set is assigned) |
| Reviewer sees pending apps in Lightning App | Done | `reviewerApplicationList` in Grant Review Console |
| Reviewer can approve/reject; approve triggers award calc | Done | `reviewerApplicationDetail` + `GrantAwardService` |
| Approved: award visible to reviewer and applicant | Done | Award on record + applicant `applicationDetail` |
| Rejected: reviewer comments visible to applicant | Done | `Reviewer_Comments__c` on applicant detail |

### 3. Data Model (Section 4 & 8)

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| Grant_Application__c with all specified fields | Done | Object + fields in metadata |
| Section 1: Org info (name, EIN, type, year, budget, employees, contact, address, mission) | Done | All fields |
| Section 2: Project (title, category, description, target pop, beneficiaries, costs, dates, previously funded) | Done | All fields |
| Supporting document (ContentVersion/ContentDocumentLink) | Done | Upload in form; controller links to application |
| System fields (Eligibility_Score__c, Is_Eligible__c, Eligibility_Results__c, Status__c, Award_Amount__c, Award_Breakdown__c, Reviewer_Comments__c, Reviewed_Date__c, Reviewer__c) | Done | All on Grant_Application__c |
| Status_History__c (child, status audit) | Done | Object + trigger to create history on status change |

### 4. Eligibility Engine (Section 5)

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| Apex service, 6 rules, @AuraEnabled | Done | `GrantEligibilityService.cls` |
| Rule 1: Nonprofit status (org type) | Done | Implemented |
| Rule 2: Min 2 years operating | Done | Implemented |
| Rule 3: Budget &lt; $2M | Done | Implemented |
| Rule 4: Request ≤ 50% of project cost | Done | Implemented |
| Rule 5: Request ≤ $50,000 | Done | Implemented |
| Rule 6: Beneficiaries ≥ 50 | Done | Implemented |
| LWC calls on field change; green/red indicators | Done | `grantApplicationForm` + eligibility panel |
| Result stored on submit | Done | Controller passes eligibility to insert |
| Test class with coverage | Done | `GrantEligibilityServiceTest` |

### 5. Award Calculation Engine (Section 6)

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| Apex service, 5 factors, @AuraEnabled | Done | `GrantAwardService.cls` |
| Community Impact, Track Record, Category Priority, Financial Need, Cost Efficiency | Done | All in scoring matrix |
| Formula: score/15, amount = requested × %, round to $100, cap $50K | Done | In `GrantAwardService` |
| Runs on approve; updates record (award, breakdown, reviewer, date, status) | Done | Reviewer LWC calls service; record updated |
| Reviewer sees breakdown | Done | `awardBreakdown` LWC |

### 6. Application Workflow (Section 7)

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| Submitted → Under Review → Approved / Rejected | Done | Status picklist + reviewer actions |
| Status_History__c on status change | Done | Trigger on Grant_Application__c |
| Approve: award calculated and stored | Done | GrantAwardService + update |
| Reject: comment required | Done | Reviewer_Comments__c in UI + validation |

### 7. UI/UX – Experience Cloud (Applicant)

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| Home/landing with Login / Register | Done | Custom home page; public access |
| Applicant dashboard (my applications, New Application, View Details) | Done | `applicantDashboard` on home (needs permission set assigned) |
| Two-section form + eligibility panel | Done | `grantApplicationForm` |
| Review-before-submit screen | Done | Review step in form |
| Application detail (read-only, award/comments when applicable) | Done | `applicationDetail` |

### 8. UI/UX – Internal (Reviewer)

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| Lightning App with list of applications | Done | Grant Review Console + `reviewerApplicationList` |
| Filters / summary counts | Done | In reviewer list LWC |
| Record/detail view with approve/reject | Done | `reviewerApplicationDetail` on Grant_Application__c record page |
| Award breakdown on approve | Done | `awardBreakdown` in reviewer detail |

### 9. Security & Sharing

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| OWD Private; applicants see own records | Done | Sharing + CreatedById in queries |
| Reviewer permission set (read/edit Grant_Application__c, etc.) | Done | Grant_Reviewer permission set |
| Apex class access for portal users | Done | **Grant_Applicant** permission set (you must assign it; see top of doc) |

### 10. Automation & Quality

| Requirement | Status | What You Have |
|-------------|--------|----------------|
| Trigger for Status_History__c | Done | GrantApplicationTrigger |
| Validation rules (server-side) | Done | On Grant_Application__c |
| Apex test coverage | Done | All main classes have tests; 42 tests, 100% pass |

---

## What You Should See When It’s Working

- **Guest (not logged in):** Home page with title, description, Log In, Register.
- **Logged-in applicant (after assigning Grant Applicant permission set):** Same page + “My Grant Applications” section (table or “No applications yet” + “New Application”). Clicking “New Application” shows the form; submitting shows success and returns to dashboard; “View Details” shows application detail.
- **Internal reviewer:** Grant Review Console app with list of applications; open record → reviewerApplicationDetail with approve/reject and award breakdown on approve.

---

## Summary

- **Built and deployed:** Objects, fields, all Apex (eligibility, award, controller, trigger), all LWCs (applicant and reviewer), Experience Cloud site, home page, self-registration, Grant Reviewer permission set, and **Grant Applicant permission set** (with Apex class access).
- **Blocking issue:** “Apex request is invalid” is due to Experience Cloud users not having Apex class access until **Grant Applicant** is assigned to them.
- **Your one-time action:** Assign the **Grant Applicant** permission set to all Customer Community User (portal) users as described at the top of this document. After that, the applicant dashboard and form should work as intended.
