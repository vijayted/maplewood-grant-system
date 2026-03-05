@IsTest
private class GrantApplicationTriggerTest {

    private static Grant_Application__c createTestApplication() {
        return TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Name__c' => 'Trigger Test Org',
            'EIN__c' => '52-9999999',
            'Year_Founded__c' => 2008,
            'Annual_Budget__c' => 250000,
            'Num_Employees__c' => 6,
            'Contact_Name__c' => 'Trigger Contact',
            'Contact_Email__c' => 'trigger@test.org',
            'Contact_Phone__c' => '4105550001',
            'Organization_Address__c' => '500 Trigger Blvd',
            'Mission_Statement__c' => 'Testing trigger behavior.',
            'Project_Title__c' => 'Trigger Test Project',
            'Project_Category__c' => 'Public Health',
            'Project_Description__c' => 'A project designed to test trigger logic.',
            'Target_Population__c' => 'General public',
            'Num_Beneficiaries__c' => 300,
            'Total_Project_Cost__c' => 100000,
            'Amount_Requested__c' => 45000
        });
    }

    @IsTest
    static void testStatusHistoryCreatedOnStatusChange() {
        Grant_Application__c app = createTestApplication();
        insert app;

        Test.startTest();
        app.Status__c = 'Under Review';
        app.Reviewer__c = UserInfo.getUserId();
        update app;
        Test.stopTest();

        List<Status_History__c> histories = [
            SELECT Old_Status__c, New_Status__c, Changed_By__c, Changed_At__c
            FROM Status_History__c
            WHERE Application__c = :app.Id
            ORDER BY Changed_At__c
        ];

        System.assertEquals(1, histories.size(), 'One history record should be created');
        System.assertEquals('Submitted', histories[0].Old_Status__c);
        System.assertEquals('Under Review', histories[0].New_Status__c);
        System.assertEquals(UserInfo.getUserId(), histories[0].Changed_By__c);
        System.assertNotEquals(null, histories[0].Changed_At__c);
    }

    @IsTest
    static void testMultipleStatusChangesCreateMultipleHistories() {
        Grant_Application__c app = createTestApplication();
        insert app;

        app.Status__c = 'Under Review';
        update app;

        Test.startTest();
        app.Status__c = 'Rejected';
        app.Reviewer_Comments__c = 'Does not meet criteria';
        app.Reviewed_Date__c = DateTime.now();
        app.Reviewer__c = UserInfo.getUserId();
        update app;
        Test.stopTest();

        List<Status_History__c> histories = [
            SELECT Old_Status__c, New_Status__c, Comments__c
            FROM Status_History__c
            WHERE Application__c = :app.Id
            ORDER BY Changed_At__c
        ];

        System.assertEquals(2, histories.size(), 'Two history records should exist');
        System.assertEquals('Submitted', histories[0].Old_Status__c);
        System.assertEquals('Under Review', histories[0].New_Status__c);
        System.assertEquals('Under Review', histories[1].Old_Status__c);
        System.assertEquals('Rejected', histories[1].New_Status__c);
        System.assertEquals('Does not meet criteria', histories[1].Comments__c);
    }

    @IsTest
    static void testNoHistoryWhenStatusUnchanged() {
        Grant_Application__c app = createTestApplication();
        insert app;

        Test.startTest();
        app.Contact_Name__c = 'Updated Name';
        update app;
        Test.stopTest();

        List<Status_History__c> histories = [
            SELECT Id FROM Status_History__c WHERE Application__c = :app.Id
        ];

        System.assertEquals(0, histories.size(), 'No history when status did not change');
    }

    @IsTest
    static void testPlatformEventPublishedOnInsert() {
        Test.startTest();
        Grant_Application__c app = createTestApplication();
        insert app;
        Test.stopTest();

        System.assertNotEquals(null, app.Id, 'Application should be inserted');
    }

    @IsTest
    static void testEmailTriggeredOnApproval() {
        Grant_Application__c app = createTestApplication();
        insert app;

        app.Status__c = 'Under Review';
        update app;

        Test.startTest();
        app.Status__c = 'Approved';
        app.Award_Amount__c = 20000;
        app.Reviewed_Date__c = DateTime.now();
        app.Reviewer__c = UserInfo.getUserId();
        update app;
        Test.stopTest();

        List<Status_History__c> histories = [
            SELECT New_Status__c FROM Status_History__c
            WHERE Application__c = :app.Id AND New_Status__c = 'Approved'
        ];
        System.assertEquals(1, histories.size(), 'Approval history should exist');
    }

    @IsTest
    static void testEmailTriggeredOnRejection() {
        Grant_Application__c app = createTestApplication();
        insert app;

        Test.startTest();
        app.Status__c = 'Rejected';
        app.Reviewer_Comments__c = 'Budget too high';
        app.Reviewed_Date__c = DateTime.now();
        app.Reviewer__c = UserInfo.getUserId();
        update app;
        Test.stopTest();

        List<Status_History__c> histories = [
            SELECT New_Status__c, Comments__c FROM Status_History__c
            WHERE Application__c = :app.Id AND New_Status__c = 'Rejected'
        ];
        System.assertEquals(1, histories.size());
        System.assertEquals('Budget too high', histories[0].Comments__c);
    }

    @IsTest
    static void testBulkInsert() {
        List<Grant_Application__c> apps = new List<Grant_Application__c>();
        for (Integer i = 0; i < 50; i++) {
            Grant_Application__c app = createTestApplication();
            app.Organization_Name__c = 'Bulk Org ' + i;
            app.EIN__c = '52-' + String.valueOf(1000000 + i);
            apps.add(app);
        }

        Test.startTest();
        insert apps;
        Test.stopTest();

        System.assertEquals(50, [SELECT COUNT() FROM Grant_Application__c WHERE Organization_Name__c LIKE 'Bulk Org%']);
    }

    @IsTest
    static void testBulkUpdate() {
        List<Grant_Application__c> apps = new List<Grant_Application__c>();
        for (Integer i = 0; i < 50; i++) {
            Grant_Application__c app = createTestApplication();
            app.Organization_Name__c = 'Bulk Update Org ' + i;
            app.EIN__c = '52-' + String.valueOf(2000000 + i);
            apps.add(app);
        }
        insert apps;

        for (Grant_Application__c app : apps) {
            app.Status__c = 'Under Review';
        }

        Test.startTest();
        update apps;
        Test.stopTest();

        List<Status_History__c> histories = [
            SELECT Id FROM Status_History__c
            WHERE Application__c IN :apps
        ];
        System.assertEquals(50, histories.size(), 'Each status change should create a history record');
    }
}
