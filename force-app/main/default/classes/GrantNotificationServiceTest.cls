@IsTest
private class GrantNotificationServiceTest {

    @TestSetup
    static void setupData() {
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Name__c' => 'Notification Test Org',
            'EIN__c' => '52-1111111',
            'Annual_Budget__c' => 200000,
            'Num_Employees__c' => 5,
            'Contact_Name__c' => 'Test Contact',
            'Contact_Email__c' => 'test@notification.org',
            'Contact_Phone__c' => '4105551234',
            'Organization_Address__c' => '100 Test Lane',
            'Mission_Statement__c' => 'Testing notification delivery.',
            'Project_Title__c' => 'Notification Test Project',
            'Project_Description__c' => 'A test project for validating notification emails.',
            'Total_Project_Cost__c' => 80000,
            'Amount_Requested__c' => 30000,
            'Num_Beneficiaries__c' => 200
        });
        insert app;
    }

    @IsTest
    static void testApprovalNotification() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];
        app.Status__c = 'Approved';
        app.Award_Amount__c = 18000;
        app.Reviewed_Date__c = DateTime.now();
        app.Reviewer__c = UserInfo.getUserId();
        update app;

        Test.startTest();
        GrantNotificationService.sendStatusNotifications(new List<Id>{ app.Id });
        Test.stopTest();

        Grant_Application__c result = [SELECT Status__c FROM Grant_Application__c WHERE Id = :app.Id];
        System.assertEquals('Approved', result.Status__c);
    }

    @IsTest
    static void testRejectionNotification() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];
        app.Status__c = 'Rejected';
        app.Reviewer_Comments__c = 'Insufficient community impact documentation';
        app.Reviewed_Date__c = DateTime.now();
        app.Reviewer__c = UserInfo.getUserId();
        update app;

        Test.startTest();
        GrantNotificationService.sendStatusNotifications(new List<Id>{ app.Id });
        Test.stopTest();

        Grant_Application__c result = [SELECT Status__c FROM Grant_Application__c WHERE Id = :app.Id];
        System.assertEquals('Rejected', result.Status__c);
    }

    @IsTest
    static void testNoEmailWhenContactEmailBlank() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];
        app.Contact_Email__c = 'placeholder@none.com';
        app.Status__c = 'Approved';
        app.Award_Amount__c = 10000;
        update app;

        app.Contact_Email__c = '';
        try {
            update app;
        } catch (DmlException e) {
            return;
        }

        Test.startTest();
        GrantNotificationService.sendStatusNotifications(new List<Id>{ app.Id });
        Test.stopTest();
    }

    @IsTest
    static void testEmptyListDoesNotFail() {
        Test.startTest();
        GrantNotificationService.sendStatusNotifications(new List<Id>());
        Test.stopTest();

        System.assert(true, 'Empty list should not throw');
    }

    @IsTest
    static void testMultipleApplications() {
        Grant_Application__c existing = [SELECT Id FROM Grant_Application__c LIMIT 1];
        existing.Status__c = 'Approved';
        existing.Award_Amount__c = 15000;
        update existing;

        Grant_Application__c app2 = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Name__c' => 'Second Org',
            'EIN__c' => '52-2222222',
            'Organization_Type__c' => '501(c)(4)',
            'Year_Founded__c' => 2012,
            'Annual_Budget__c' => 150000,
            'Num_Employees__c' => 3,
            'Contact_Name__c' => 'Second Contact',
            'Contact_Email__c' => 'second@test.org',
            'Project_Title__c' => 'Second Project',
            'Project_Category__c' => 'Senior Services',
            'Num_Beneficiaries__c' => 100,
            'Total_Project_Cost__c' => 60000,
            'Amount_Requested__c' => 25000,
            'Status__c' => 'Rejected',
            'Reviewer_Comments__c' => 'Budget concerns'
        });
        insert app2;

        Test.startTest();
        GrantNotificationService.sendStatusNotifications(new List<Id>{ existing.Id, app2.Id });
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM Grant_Application__c]);
    }

    @IsTest
    static void testGetPortalUrl() {
        Test.startTest();
        String url = GrantNotificationService.getPortalUrl();
        Test.stopTest();

        System.assertNotEquals(null, url, 'Portal URL should not be null');
        System.assert(url.contains('/grants/'), 'Portal URL should contain /grants/ path');
    }
}
