# Grant Review Console – What Shows (Based on User Stories)

The internal app is configured so reviewers see what the challenge user stories (US-201–US-205) require.

---

## What’s Configured (Deployed)

| User Story | Requirement | What Shows |
|------------|-------------|------------|
| **US-201** | See pending applications in a Lightning App | **Grant Review Console** opens to the **Grant Applications** list tab. Columns: Application, Organization, Project Title, Date Submitted, Eligibility, Status, Amount Requested. **View** action on each row. |
| **US-202** | Open an application and see details + eligibility | Clicking **View** opens the **Grant Application Record Page** (custom Lightning page) with all fields, uploaded document, and eligibility check results (each rule pass/fail). |
| **US-203** | Approve or reject; award auto-calculated on approve | Same record page: **Approve** (runs award calculator, shows breakdown, asks for confirmation) and **Reject** (comment required). |
| **US-204** | Summary counts by status | Available on the **Grant Review Home** Lightning page (optional, see below). |
| **US-205** | Filter by eligibility and status | Available on the **Grant Review Home** Lightning page (optional, see below). |

---

## Current Behavior

1. Open **Grant Review Console** from the App Launcher (assign the app to your profile if you don’t see it).
2. You land on the **Grant Applications** tab (list of all applications).
3. Click **View** on a row to open the **custom record page** with full detail, eligibility, and **Approve** / **Reject** (US-201, US-202, US-203).

---

## Optional: Custom Home with Counts and Filters (US-204, US-205)

The **Grant Review Home** Lightning page shows:

- Summary counts: Submitted, Under Review, Approved (with total $), Rejected  
- Filters by eligibility and status  
- Same application list in a custom LWC  

To use it as the app’s first screen:

1. **Setup** → **App Manager** → find **Grant Review Console** → **Edit**.
2. Under **Navigation Items** or **App Options**, set **Home** (or the first tab) to the Lightning page **Grant Review Home**.
3. **Save**.

After that, opening Grant Review Console will show Grant Review Home first (counts + filters + list); the **Grant Applications** tab is still available for the standard list.
