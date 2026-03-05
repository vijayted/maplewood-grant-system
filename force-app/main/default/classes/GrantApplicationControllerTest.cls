@IsTest
private class GrantApplicationControllerTest {

    @TestSetup
    static void setupData() {
        Grant_Application__c app = TestDataFactory.createApplication();
        insert app;
    }

    @IsTest
    static void testCreateApplication() {
        GrantApplicationController.ApplicationInput input = new GrantApplicationController.ApplicationInput();
        input.organizationName = 'New Org';
        input.ein = '99-8765432';
        input.organizationType = '501(c)(4)';
        input.yearFounded = 2010;
        input.annualBudget = 250000;
        input.numEmployees = 5;
        input.contactName = 'John Smith';
        input.contactEmail = 'john@neworg.org';
        input.contactPhone = '4105559999';
        input.organizationAddress = '456 New St';
        input.missionStatement = 'Helping the community thrive.';
        input.projectTitle = 'Community Garden Project';
        input.projectCategory = 'Public Health';
        input.projectDescription = 'Building community gardens across underserved neighborhoods.';
        input.targetPopulation = 'Underserved neighborhoods';
        input.numBeneficiaries = 300;
        input.totalProjectCost = 80000;
        input.amountRequested = 35000;
        input.projectStartDate = Date.today().addDays(45);
        input.projectEndDate = Date.today().addDays(400);
        input.previouslyFunded = false;

        Test.startTest();
        Id appId = GrantApplicationController.createApplication(input);
        Test.stopTest();

        System.assertNotEquals(null, appId);
        Grant_Application__c created = [
            SELECT Status__c, Organization_Name__c, Is_Eligible__c, Eligibility_Score__c
            FROM Grant_Application__c WHERE Id = :appId
        ];
        System.assertEquals('Submitted', created.Status__c);
        System.assertEquals('New Org', created.Organization_Name__c);
        System.assertEquals(true, created.Is_Eligible__c, 'Server-side eligibility should pass for valid data');
        System.assertEquals(6, created.Eligibility_Score__c, 'All 6 rules should pass');
    }

    @IsTest
    static void testCreateApplicationWithInvalidEin() {
        GrantApplicationController.ApplicationInput input = new GrantApplicationController.ApplicationInput();
        input.organizationName = 'Bad EIN Org';
        input.ein = 'INVALID-EIN';
        input.organizationType = '501(c)(3)';
        input.yearFounded = 2015;
        input.annualBudget = 100000;
        input.numEmployees = 3;
        input.contactName = 'Test';
        input.contactEmail = 'test@test.org';
        input.contactPhone = '4105550001';
        input.organizationAddress = '123 St';
        input.missionStatement = 'Test mission.';
        input.projectTitle = 'Test Project';
        input.projectCategory = 'Youth Programs';
        input.projectDescription = 'Test description.';
        input.targetPopulation = 'Youth';
        input.numBeneficiaries = 100;
        input.totalProjectCost = 50000;
        input.amountRequested = 20000;
        input.projectStartDate = Date.today().addDays(45);
        input.projectEndDate = Date.today().addDays(400);

        Test.startTest();
        try {
            GrantApplicationController.createApplication(input);
            System.assert(false, 'Should have thrown AuraHandledException for invalid EIN');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('EIN'), 'Error should reference EIN format');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateApplicationAmountExceeds50K() {
        GrantApplicationController.ApplicationInput input = new GrantApplicationController.ApplicationInput();
        input.organizationName = 'Over Limit Org';
        input.ein = '52-1234567';
        input.organizationType = '501(c)(3)';
        input.yearFounded = 2015;
        input.annualBudget = 100000;
        input.numEmployees = 3;
        input.contactName = 'Test';
        input.contactEmail = 'test@test.org';
        input.contactPhone = '4105550001';
        input.organizationAddress = '123 St';
        input.missionStatement = 'Test mission.';
        input.projectTitle = 'Test Project';
        input.projectCategory = 'Youth Programs';
        input.projectDescription = 'Test description.';
        input.targetPopulation = 'Youth';
        input.numBeneficiaries = 100;
        input.totalProjectCost = 200000;
        input.amountRequested = 60000;
        input.projectStartDate = Date.today().addDays(45);
        input.projectEndDate = Date.today().addDays(400);

        Test.startTest();
        try {
            GrantApplicationController.createApplication(input);
            System.assert(false, 'Should have thrown AuraHandledException for amount > 50K');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('50,000'), 'Error should reference $50,000 limit');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetMyApplications() {
        Test.startTest();
        List<Grant_Application__c> apps = GrantApplicationController.getMyApplications();
        Test.stopTest();

        System.assert(apps.size() > 0, 'Should return at least one application');
    }

    @IsTest
    static void testGetApplicationById() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];

        Test.startTest();
        Grant_Application__c result = GrantApplicationController.getApplicationById(app.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('Test Nonprofit', result.Organization_Name__c);
    }

    @IsTest
    static void testGetApplicationByIdNotFound() {
        Id fakeId = Grant_Application__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001';

        Test.startTest();
        try {
            GrantApplicationController.getApplicationById(fakeId);
            System.assert(false, 'Should have thrown AuraHandledException for non-existent Id');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Should return an error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetAllApplications() {
        Test.startTest();
        List<Grant_Application__c> apps = GrantApplicationController.getAllApplications();
        Test.stopTest();

        System.assert(apps.size() > 0);
    }

    @IsTest
    static void testUpdateStatusToUnderReview() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];

        Test.startTest();
        GrantApplicationController.updateStatus(app.Id, 'Under Review', null);
        Test.stopTest();

        Grant_Application__c updated = [SELECT Status__c, Reviewer__c FROM Grant_Application__c WHERE Id = :app.Id];
        System.assertEquals('Under Review', updated.Status__c);
        System.assertEquals(UserInfo.getUserId(), updated.Reviewer__c);
    }

    @IsTest
    static void testUpdateStatusToRejected() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];

        Test.startTest();
        GrantApplicationController.updateStatus(app.Id, 'Rejected', 'Insufficient documentation');
        Test.stopTest();

        Grant_Application__c updated = [
            SELECT Status__c, Reviewer_Comments__c, Reviewed_Date__c, Reviewer__c
            FROM Grant_Application__c WHERE Id = :app.Id
        ];
        System.assertEquals('Rejected', updated.Status__c);
        System.assertEquals('Insufficient documentation', updated.Reviewer_Comments__c);
        System.assertNotEquals(null, updated.Reviewed_Date__c);
    }

    @IsTest
    static void testUpdateStatusInvalidTransitionFromApproved() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];
        app.Status__c = 'Approved';
        app.Award_Amount__c = 10000;
        app.Reviewed_Date__c = DateTime.now();
        app.Reviewer__c = UserInfo.getUserId();
        update app;

        Test.startTest();
        try {
            GrantApplicationController.updateStatus(app.Id, 'Submitted', null);
            System.assert(false, 'Should have thrown AuraHandledException for invalid transition');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid status transition'), 'Error should describe invalid transition');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateStatusInvalidTransitionFromRejected() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];
        app.Status__c = 'Rejected';
        app.Reviewer_Comments__c = 'Not eligible';
        app.Reviewed_Date__c = DateTime.now();
        app.Reviewer__c = UserInfo.getUserId();
        update app;

        Test.startTest();
        try {
            GrantApplicationController.updateStatus(app.Id, 'Under Review', null);
            System.assert(false, 'Should have thrown AuraHandledException for terminal status');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid status transition'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadFile() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];
        String base64 = EncodingUtil.base64Encode(Blob.valueOf('test file content'));

        Test.startTest();
        Id cvId = GrantApplicationController.uploadFile(app.Id, 'test.pdf', base64, 'application/pdf');
        Test.stopTest();

        System.assertNotEquals(null, cvId);
        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :app.Id
        ];
        System.assert(links.size() > 0, 'File should be linked to application');
    }

    @IsTest
    static void testUploadFileWithInvalidBase64() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];

        Test.startTest();
        try {
            GrantApplicationController.uploadFile(app.Id, 'test.pdf', '!!!not-base64!!!', 'application/pdf');
            System.assert(false, 'Should have thrown exception for invalid base64');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Should return an error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetApplicationFiles() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];
        String base64 = EncodingUtil.base64Encode(Blob.valueOf('test file'));
        GrantApplicationController.uploadFile(app.Id, 'doc.pdf', base64, 'application/pdf');

        Test.startTest();
        List<ContentDocumentLink> files = GrantApplicationController.getApplicationFiles(app.Id);
        Test.stopTest();

        System.assert(files.size() > 0);
    }

    @IsTest
    static void testGetApplicationSummary() {
        Test.startTest();
        Map<String, Object> summary = GrantApplicationController.getApplicationSummary();
        Test.stopTest();

        System.assertNotEquals(null, summary);
        System.assert(summary.containsKey('submitted'));
        System.assert(summary.containsKey('underReview'));
        System.assert(summary.containsKey('approved'));
        System.assert(summary.containsKey('rejected'));
        System.assert(summary.containsKey('totalAwarded'));
    }

    @IsTest
    static void testStatusHistoryCreatedOnUpdate() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];

        Test.startTest();
        GrantApplicationController.updateStatus(app.Id, 'Under Review', null);
        Test.stopTest();

        List<Status_History__c> histories = [
            SELECT Old_Status__c, New_Status__c, Changed_By__c
            FROM Status_History__c
            WHERE Application__c = :app.Id
        ];
        System.assert(histories.size() > 0, 'Status history should be created');
        System.assertEquals('Submitted', histories[0].Old_Status__c);
        System.assertEquals('Under Review', histories[0].New_Status__c);
    }
}
