@IsTest
private class GrantAwardServiceTest {

    @TestSetup
    static void setupData() {
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Name__c' => 'Youth Forward Inc.',
            'Contact_Name__c' => 'Diana Torres',
            'Contact_Email__c' => 'diana@youthforward.org',
            'Contact_Phone__c' => '4105550142',
            'Organization_Address__c' => '742 Oak Street, Maplewood, MD 21201',
            'Mission_Statement__c' => 'Youth Forward empowers at-risk youth through mentorship.',
            'Project_Title__c' => 'After-School Mentorship Expansion',
            'Project_Description__c' => 'Expand our after-school mentorship program from 2 to 5 locations.'
        });
        insert app;
    }

    @IsTest
    static void testCalculateAwardSampleData() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];

        Test.startTest();
        GrantAwardService.AwardResult result = GrantAwardService.calculateAward(app.Id);
        Test.stopTest();

        System.assertEquals(5, result.factors.size(), 'Should have 5 factors');
        System.assertEquals(15, result.maxScore);
        System.assert(result.totalScore >= 5 && result.totalScore <= 15, 'Score should be between 5 and 15');
        System.assert(result.finalAward > 0, 'Award should be positive');
        System.assert(result.finalAward <= 50000, 'Award should not exceed $50,000');
        System.assertEquals(0, Math.mod(result.finalAward.intValue(), 100), 'Award should be rounded to nearest $100');

        System.assertEquals(9, result.totalScore, 'Sample data should score 9/15');
        System.assertEquals(24000, result.finalAward, 'Sample award should be $24,000');
    }

    @IsTest
    static void testApproveApplication() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];

        Test.startTest();
        GrantAwardService.approveApplication(app.Id, null);
        Test.stopTest();

        Grant_Application__c updated = [
            SELECT Status__c, Award_Amount__c, Award_Breakdown__c,
                   Reviewed_Date__c, Reviewer__c
            FROM Grant_Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals('Approved', updated.Status__c);
        System.assertNotEquals(null, updated.Award_Amount__c);
        System.assertNotEquals(null, updated.Award_Breakdown__c);
        System.assertNotEquals(null, updated.Reviewed_Date__c);
        System.assertEquals(UserInfo.getUserId(), updated.Reviewer__c);
    }

    @IsTest
    static void testApproveApplicationWithPreCalculatedResult() {
        Grant_Application__c app = [SELECT Id FROM Grant_Application__c LIMIT 1];

        GrantAwardService.AwardResult preview = GrantAwardService.calculateAward(app.Id);
        String awardJson = JSON.serialize(preview);

        Test.startTest();
        GrantAwardService.approveApplication(app.Id, awardJson);
        Test.stopTest();

        Grant_Application__c updated = [
            SELECT Status__c, Award_Amount__c FROM Grant_Application__c WHERE Id = :app.Id
        ];
        System.assertEquals('Approved', updated.Status__c);
        System.assertEquals(preview.finalAward, updated.Award_Amount__c);
    }

    @IsTest
    static void testHighScoreApplication() {
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Name__c' => 'Health First Org',
            'EIN__c' => '52-9999999',
            'Year_Founded__c' => 2000,
            'Annual_Budget__c' => 50000,
            'Num_Employees__c' => 3,
            'Contact_Name__c' => 'Test Contact',
            'Contact_Email__c' => 'test@test.org',
            'Project_Title__c' => 'Public Health Initiative',
            'Project_Category__c' => 'Public Health',
            'Num_Beneficiaries__c' => 5000,
            'Total_Project_Cost__c' => 200000,
            'Amount_Requested__c' => 40000
        });
        insert app;

        Test.startTest();
        GrantAwardService.AwardResult result = GrantAwardService.calculateAward(app.Id);
        Test.stopTest();

        System.assertEquals(15, result.totalScore, 'Max scoring application should get 15/15');
        System.assertEquals(40000, result.finalAward, 'Should get full requested amount');
    }

    @IsTest
    static void testLowScoreApplication() {
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Name__c' => 'Arts Group',
            'EIN__c' => '52-1111111',
            'Year_Founded__c' => 2022,
            'Annual_Budget__c' => 800000,
            'Project_Title__c' => 'Art Showcase',
            'Project_Category__c' => 'Arts & Culture',
            'Num_Beneficiaries__c' => 100,
            'Total_Project_Cost__c' => 50000,
            'Amount_Requested__c' => 25000
        });
        insert app;

        Test.startTest();
        GrantAwardService.AwardResult result = GrantAwardService.calculateAward(app.Id);
        Test.stopTest();

        System.assertEquals(5, result.totalScore, 'Lowest scoring should get 5/15');
        System.assert(result.finalAward <= result.rawAward || result.finalAward == result.rawAward,
            'Final should be rounded version of raw');
    }

    @IsTest
    static void testAwardCappedAt50K() {
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Name__c' => 'Big Health Org',
            'EIN__c' => '52-8888888',
            'Year_Founded__c' => 1990,
            'Annual_Budget__c' => 50000,
            'Project_Title__c' => 'Mega Health Program',
            'Project_Category__c' => 'Public Health',
            'Num_Beneficiaries__c' => 50000,
            'Total_Project_Cost__c' => 500000,
            'Amount_Requested__c' => 50000
        });
        insert app;

        Test.startTest();
        GrantAwardService.AwardResult result = GrantAwardService.calculateAward(app.Id);
        Test.stopTest();

        System.assert(result.finalAward <= 50000, 'Award must not exceed $50,000');
    }
}
