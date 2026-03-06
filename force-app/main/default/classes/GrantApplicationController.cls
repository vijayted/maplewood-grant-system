public with sharing class GrantApplicationController {

    public class ApplicationInput {
        @AuraEnabled public String organizationName { get; set; }
        @AuraEnabled public String ein { get; set; }
        @AuraEnabled public String organizationType { get; set; }
        @AuraEnabled public Integer yearFounded { get; set; }
        @AuraEnabled public Decimal annualBudget { get; set; }
        @AuraEnabled public Integer numEmployees { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String contactEmail { get; set; }
        @AuraEnabled public String contactPhone { get; set; }
        @AuraEnabled public String organizationAddress { get; set; }
        @AuraEnabled public String missionStatement { get; set; }
        @AuraEnabled public String projectTitle { get; set; }
        @AuraEnabled public String projectCategory { get; set; }
        @AuraEnabled public String projectDescription { get; set; }
        @AuraEnabled public String targetPopulation { get; set; }
        @AuraEnabled public Integer numBeneficiaries { get; set; }
        @AuraEnabled public Decimal totalProjectCost { get; set; }
        @AuraEnabled public Decimal amountRequested { get; set; }
        @AuraEnabled public Date projectStartDate { get; set; }
        @AuraEnabled public Date projectEndDate { get; set; }
        @AuraEnabled public Boolean previouslyFunded { get; set; }
        @AuraEnabled public String eligibilityResultsJson { get; set; }
        @AuraEnabled public Integer eligibilityScore { get; set; }
        @AuraEnabled public Boolean isEligible { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkIsGuestUser() {
        return Auth.CommunitiesUtil.isGuestUser();
    }

    private static AuraHandledException buildAuraException(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }

    private static final Pattern EIN_PATTERN = Pattern.compile('^\\d{2}-\\d{7}$');

    private static void validateInput(ApplicationInput appData) {
        if (String.isNotBlank(appData.ein) && !EIN_PATTERN.matcher(appData.ein).matches()) {
            throw buildAuraException('EIN must be in the format XX-XXXXXXX (e.g. 52-1234567).');
        }
        Integer currentYear = Date.today().year();
        if (appData.yearFounded != null && (appData.yearFounded < 1800 || appData.yearFounded > currentYear)) {
            throw buildAuraException('Year Founded must be between 1800 and ' + currentYear + '.');
        }
        if (appData.annualBudget != null && appData.annualBudget < 0) {
            throw buildAuraException('Annual Budget cannot be negative.');
        }
        if (appData.amountRequested != null && appData.amountRequested > 50000) {
            throw buildAuraException('Amount Requested cannot exceed $50,000.');
        }
        if (appData.amountRequested != null && appData.amountRequested < 0) {
            throw buildAuraException('Amount Requested cannot be negative.');
        }
        if (appData.projectStartDate != null && appData.projectStartDate < Date.today().addDays(30)) {
            throw buildAuraException('Project Start Date must be at least 30 days in the future.');
        }
        if (appData.projectStartDate != null && appData.projectEndDate != null
                && appData.projectEndDate <= appData.projectStartDate) {
            throw buildAuraException('Project End Date must be after the Start Date.');
        }
    }

    @AuraEnabled
    public static Id createApplication(ApplicationInput appData) {
        try {
            validateInput(appData);

            Grant_Application__c app = new Grant_Application__c();
            app.Organization_Name__c = appData.organizationName;
            if (String.isNotBlank(appData.ein)) {
                String cleanEin = appData.ein.trim()
                    .replace('\u2013', '-')
                    .replace('\u2014', '-')
                    .replace('\u2212', '-');
                app.EIN__c = cleanEin;
            } else {
                app.EIN__c = appData.ein;
            }
            app.Organization_Type__c = appData.organizationType;
            app.Year_Founded__c = appData.yearFounded;
            app.Annual_Budget__c = appData.annualBudget;
            app.Num_Employees__c = appData.numEmployees;
            app.Contact_Name__c = appData.contactName;
            app.Contact_Email__c = appData.contactEmail;
            app.Contact_Phone__c = appData.contactPhone;
            app.Organization_Address__c = appData.organizationAddress;
            app.Mission_Statement__c = appData.missionStatement;
            app.Project_Title__c = appData.projectTitle;
            app.Project_Category__c = appData.projectCategory;
            app.Project_Description__c = appData.projectDescription;
            app.Target_Population__c = appData.targetPopulation;
            app.Num_Beneficiaries__c = appData.numBeneficiaries;
            app.Total_Project_Cost__c = appData.totalProjectCost;
            app.Amount_Requested__c = appData.amountRequested;
            app.Project_Start_Date__c = appData.projectStartDate;
            app.Project_End_Date__c = appData.projectEndDate;
            app.Previously_Funded__c = (appData.previouslyFunded == true);
            app.Status__c = 'Submitted';

            GrantEligibilityService.EligibilityResult eligibility =
                GrantEligibilityService.checkEligibility(
                    appData.organizationType,
                    appData.yearFounded,
                    appData.annualBudget,
                    appData.amountRequested,
                    appData.totalProjectCost,
                    appData.numBeneficiaries
                );
            app.Eligibility_Results__c = JSON.serialize(eligibility);
            app.Eligibility_Score__c = eligibility.rulesPassed;
            app.Is_Eligible__c = eligibility.isEligible;

            insert app;
            return app.Id;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (DmlException de) {
            String dmlMsg = de.getDmlMessage(0);
            AuraHandledException ahe = new AuraHandledException(dmlMsg);
            ahe.setMessage(dmlMsg);
            throw ahe;
        } catch (Exception e) {
            String errMsg = e.getMessage();
            AuraHandledException ahe = new AuraHandledException(errMsg);
            ahe.setMessage(errMsg);
            throw ahe;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Grant_Application__c> getMyApplications() {
        try {
            Id userId = UserInfo.getUserId();
            return [
                SELECT Id, Name, Project_Title__c, CreatedDate, Status__c,
                       Award_Amount__c, Is_Eligible__c, Organization_Name__c
                FROM Grant_Application__c
                WHERE CreatedById = :userId
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
            ];
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in getMyApplications: ' + qe.getMessage() + '\n' + qe.getStackTraceString());
            throw new AuraHandledException('Unable to retrieve your applications. Please try again.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ' in getMyApplications: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('An unexpected error occurred. Please try again.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static Grant_Application__c getApplicationById(Id applicationId) {
        try {
            List<Grant_Application__c> results = [
                SELECT Id, Name, Organization_Name__c, EIN__c, Organization_Type__c,
                       Year_Founded__c, Annual_Budget__c, Num_Employees__c,
                       Contact_Name__c, Contact_Email__c, Contact_Phone__c,
                       Organization_Address__c, Mission_Statement__c,
                       Project_Title__c, Project_Category__c, Project_Description__c,
                       Target_Population__c, Num_Beneficiaries__c,
                       Total_Project_Cost__c, Amount_Requested__c,
                       Project_Start_Date__c, Project_End_Date__c, Previously_Funded__c,
                       Status__c, Eligibility_Score__c, Is_Eligible__c,
                       Eligibility_Results__c, Award_Amount__c, Award_Breakdown__c,
                       Reviewer_Comments__c, Reviewed_Date__c, Reviewer__c,
                       Reviewer__r.Name, CreatedDate, CreatedById, CreatedBy.Name
                FROM Grant_Application__c
                WHERE Id = :applicationId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (results.isEmpty()) {
                throw buildAuraException('Application not found.');
            }
            return results[0];
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in getApplicationById: ' + qe.getMessage() + '\n' + qe.getStackTraceString());
            throw new AuraHandledException('Unable to retrieve the application. Please try again.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ' in getApplicationById: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('An unexpected error occurred. Please try again.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Grant_Application__c> getAllApplications() {
        try {
            return [
                SELECT Id, Name, Organization_Name__c, Project_Title__c,
                       CreatedDate, Status__c, Is_Eligible__c, Eligibility_Score__c,
                       Award_Amount__c, Amount_Requested__c, Project_Category__c
                FROM Grant_Application__c
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 200
            ];
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in getAllApplications: ' + qe.getMessage() + '\n' + qe.getStackTraceString());
            throw new AuraHandledException('Unable to retrieve applications. Please try again.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ' in getAllApplications: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('An unexpected error occurred. Please try again.');
        }
    }

    @TestVisible
    private static final Map<String, Set<String>> VALID_TRANSITIONS = new Map<String, Set<String>>{
        'Submitted' => new Set<String>{ 'Under Review', 'Approved', 'Rejected' },
        'Under Review' => new Set<String>{ 'Approved', 'Rejected' }
    };

    @AuraEnabled
    public static void updateStatus(Id applicationId, String newStatus, String comments) {
        try {
            Grant_Application__c app = [
                SELECT Id, Status__c
                FROM Grant_Application__c
                WHERE Id = :applicationId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            String currentStatus = app.Status__c;
            Set<String> allowed = VALID_TRANSITIONS.get(currentStatus);
            if (allowed == null || !allowed.contains(newStatus)) {
                throw buildAuraException(
                    'Invalid status transition: cannot move from '
                    + currentStatus + ' to ' + newStatus + '.'
                );
            }

            app.Status__c = newStatus;
            if (newStatus == 'Rejected') {
                app.Reviewer_Comments__c = comments;
                app.Reviewed_Date__c = DateTime.now();
                app.Reviewer__c = UserInfo.getUserId();
            } else if (newStatus == 'Under Review') {
                app.Reviewer__c = UserInfo.getUserId();
            }

            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPDATABLE, new List<Grant_Application__c>{ app }
            );
            update decision.getRecords();
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (DmlException de) {
            System.debug(LoggingLevel.ERROR, 'DmlException in updateStatus: ' + de.getMessage() + '\n' + de.getStackTraceString());
            throw new AuraHandledException('A database error occurred while updating the status. Please try again.');
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in updateStatus: ' + qe.getMessage() + '\n' + qe.getStackTraceString());
            throw new AuraHandledException('Unable to find the application. Please try again.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ' in updateStatus: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('An unexpected error occurred. Please try again.');
        }
    }

    @AuraEnabled
    public static Id uploadFile(Id applicationId, String fileName, String base64Data, String contentType) {
        try {
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            insert cv;

            Id contentDocId = [
                SELECT ContentDocumentId FROM ContentVersion
                WHERE Id = :cv.Id
                WITH SECURITY_ENFORCED
            ].ContentDocumentId;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocId;
            cdl.LinkedEntityId = applicationId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;

            return cv.Id;
        } catch (DmlException de) {
            System.debug(LoggingLevel.ERROR, 'DmlException in uploadFile: ' + de.getMessage() + '\n' + de.getStackTraceString());
            throw new AuraHandledException('A database error occurred while uploading the file. Please try again.');
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in uploadFile: ' + qe.getMessage() + '\n' + qe.getStackTraceString());
            throw new AuraHandledException('Unable to process the uploaded file. Please try again.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ' in uploadFile: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('An unexpected error occurred while uploading the file. Please try again.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getApplicationFiles(Id applicationId) {
        try {
            return [
                SELECT Id, ContentDocumentId, ContentDocument.Title,
                       ContentDocument.FileType, ContentDocument.ContentSize,
                       ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :applicationId
                WITH SECURITY_ENFORCED
            ];
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in getApplicationFiles: ' + qe.getMessage() + '\n' + qe.getStackTraceString());
            throw new AuraHandledException('Unable to retrieve application files. Please try again.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ' in getApplicationFiles: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('An unexpected error occurred. Please try again.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getApplicationSummary() {
        try {
            Map<String, Object> summary = new Map<String, Object>();

            List<AggregateResult> grouped = [
                SELECT Status__c,
                       COUNT(Id) cnt,
                       SUM(Award_Amount__c) totalAward,
                       SUM(Amount_Requested__c) totalRequested
                FROM Grant_Application__c
                WITH SECURITY_ENFORCED
                GROUP BY Status__c
            ];

            Integer submitted = 0;
            Integer underReview = 0;
            Integer approved = 0;
            Integer rejected = 0;
            Decimal totalAward = 0;
            Decimal pendingRequested = 0;

            for (AggregateResult ar : grouped) {
                String status = (String) ar.get('Status__c');
                Integer cnt = (Integer) ar.get('cnt');
                Decimal award = ar.get('totalAward') != null ? (Decimal) ar.get('totalAward') : 0;
                Decimal requested = ar.get('totalRequested') != null ? (Decimal) ar.get('totalRequested') : 0;

                if (status == 'Submitted') {
                    submitted = cnt;
                    pendingRequested += requested;
                } else if (status == 'Under Review') {
                    underReview = cnt;
                    pendingRequested += requested;
                } else if (status == 'Approved') {
                    approved = cnt;
                    totalAward = award;
                } else if (status == 'Rejected') {
                    rejected = cnt;
                }
            }

            summary.put('submitted', submitted);
            summary.put('underReview', underReview);
            summary.put('approved', approved);
            summary.put('rejected', rejected);
            summary.put('totalAwarded', totalAward);
            summary.put('pendingRequested', pendingRequested);

            Decimal totalBudget = 2000000;
            summary.put('totalBudget', totalBudget);
            summary.put('fundsRemaining', totalBudget - totalAward);
            summary.put('utilizationPct', totalBudget > 0 ? ((totalAward / totalBudget) * 100).setScale(1) : 0);
            summary.put('totalApplications', submitted + underReview + approved + rejected);

            return summary;
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in getApplicationSummary: ' + qe.getMessage() + '\n' + qe.getStackTraceString());
            throw new AuraHandledException('Unable to retrieve the application summary. Please try again.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ' in getApplicationSummary: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('An unexpected error occurred. Please try again.');
        }
    }
}
