@IsTest
private class EvaluatorValidationTest {

    // ================================================================
    // TEST APPLICATION 1 - Fully Eligible, High Award ($50,000)
    // Org: 501(c)(3), Year 2005, Budget $85K
    // Project: Public Health, 2500 beneficiaries, $50K/$200K
    // Expected: Eligible 6/6, Score 15/15, Award $50,000
    // ================================================================

    @IsTest
    static void testApp1_Eligibility_AllPass() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', 2005, 85000, 50000, 200000, 2500
            );
        System.assertEquals(true, result.isEligible, 'App1: Should be eligible');
        System.assertEquals(6, result.rulesPassed, 'App1: All 6 rules should pass');
        for (GrantEligibilityService.RuleResult rule : result.rules) {
            System.assertEquals(true, rule.passed,
                'App1 Rule ' + rule.ruleNumber + ' (' + rule.ruleName + ') should pass');
        }
    }

    @IsTest
    static void testApp1_Award_50000() {
        Grant_Application__c app = createApp1Base(null);
        insert app;

        Test.startTest();
        GrantAwardService.AwardResult result = GrantAwardService.calculateAward(app.Id);
        Test.stopTest();

        System.assertEquals(3, result.factors[0].score, 'App1: Community Impact = 3 (2500 >= 1001)');
        System.assertEquals(3, result.factors[1].score, 'App1: Track Record = 3 (21 years >= 16)');
        System.assertEquals(3, result.factors[2].score, 'App1: Category Priority = 3 (Public Health)');
        System.assertEquals(3, result.factors[3].score, 'App1: Financial Need = 3 (< $100K)');
        System.assertEquals(3, result.factors[4].score, 'App1: Cost Efficiency = 3 (25% <= 25%)');
        System.assertEquals(15, result.totalScore, 'App1: Total score should be 15/15');
        System.assertEquals(50000, result.finalAward, 'App1: Final award should be $50,000');
    }

    // ================================================================
    // TEST APPLICATION 2 - Fully Ineligible, Multiple Failures
    // Org: For-Profit, Year 2025, Budget $5M
    // Project: Workforce Dev, 30 beneficiaries, $55K/$80K
    // Expected: Not Eligible 0/6
    // ================================================================

    @IsTest
    static void testApp2_Eligibility_AllFail() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                'For-Profit Business', 2025, 5000000, 55000, 80000, 30
            );
        System.assertEquals(false, result.isEligible, 'App2: Should NOT be eligible');
        System.assertEquals(0, result.rulesPassed, 'App2: 0 of 6 rules should pass');
        for (GrantEligibilityService.RuleResult rule : result.rules) {
            System.assertEquals(true, rule.evaluated,
                'App2 Rule ' + rule.ruleNumber + ' should be evaluated');
            System.assertEquals(false, rule.passed,
                'App2 Rule ' + rule.ruleNumber + ' (' + rule.ruleName + ') should FAIL');
        }
    }

    // ================================================================
    // TEST APPLICATION 3 - Boundary Values (all at exact thresholds)
    // Org: Community-Based, Year 2024 (exactly 2 yrs), Budget $1,999,999
    // Project: Arts & Culture, 50 beneficiaries, $20K/$40K (50%)
    // Expected: Eligible 6/6, Score 5/15, Award $6,700
    // ================================================================

    @IsTest
    static void testApp3_Eligibility_BoundaryPass() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                'Community-Based Organization', 2024, 1999999, 20000, 40000, 50
            );
        System.assertEquals(true, result.isEligible, 'App3: Should be eligible (all boundaries pass)');
        System.assertEquals(6, result.rulesPassed, 'App3: All 6 rules should pass at boundaries');
        System.assertEquals(true, result.rules[0].passed, 'App3: Community-Based Org is eligible type');
        System.assertEquals(true, result.rules[1].passed, 'App3: 2024 = exactly 2 years (>= 2)');
        System.assertEquals(true, result.rules[2].passed, 'App3: $1,999,999 < $2,000,000');
        System.assertEquals(true, result.rules[3].passed, 'App3: $20K/$40K = 50% (<= 50%)');
        System.assertEquals(true, result.rules[4].passed, 'App3: $20,000 <= $50,000');
        System.assertEquals(true, result.rules[5].passed, 'App3: 50 >= 50');
    }

    @IsTest
    static void testApp3_Award_6700() {
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Type__c' => 'Community-Based Organization',
            'Year_Founded__c' => 2024,
            'Annual_Budget__c' => 1999999,
            'Amount_Requested__c' => 20000,
            'Total_Project_Cost__c' => 40000,
            'Num_Beneficiaries__c' => 50,
            'Project_Category__c' => 'Arts & Culture'
        });
        insert app;

        Test.startTest();
        GrantAwardService.AwardResult result = GrantAwardService.calculateAward(app.Id);
        Test.stopTest();

        System.assertEquals(1, result.factors[0].score, 'App3: Community Impact = 1 (50-200)');
        System.assertEquals(1, result.factors[1].score, 'App3: Track Record = 1 (2 years, 2-5 range)');
        System.assertEquals(1, result.factors[2].score, 'App3: Category Priority = 1 (Arts & Culture)');
        System.assertEquals(1, result.factors[3].score, 'App3: Financial Need = 1 ($500K-$1.99M)');
        System.assertEquals(1, result.factors[4].score, 'App3: Cost Efficiency = 1 (50%, 41-50% range)');
        System.assertEquals(5, result.totalScore, 'App3: Total score should be 5/15');
        System.assertEquals(6700, result.finalAward, 'App3: Final award should be $6,700');
    }

    // ================================================================
    // TEST APPLICATION 4 - Eligible, Low Scores
    // Org: 501(c)(4), Year 2021, Budget $750K
    // Project: Senior Services, 150 beneficiaries, $14K/$30K
    // Expected: Eligible 6/6, Score 6/15, Award $5,600
    // ================================================================

    @IsTest
    static void testApp4_Eligibility_AllPass() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(4)', 2021, 750000, 14000, 30000, 150
            );
        System.assertEquals(true, result.isEligible, 'App4: Should be eligible');
        System.assertEquals(6, result.rulesPassed, 'App4: All 6 rules should pass');
    }

    @IsTest
    static void testApp4_Award_5600() {
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Type__c' => '501(c)(4)',
            'Year_Founded__c' => 2021,
            'Annual_Budget__c' => 750000,
            'Amount_Requested__c' => 14000,
            'Total_Project_Cost__c' => 30000,
            'Num_Beneficiaries__c' => 150,
            'Project_Category__c' => 'Senior Services'
        });
        insert app;

        Test.startTest();
        GrantAwardService.AwardResult result = GrantAwardService.calculateAward(app.Id);
        Test.stopTest();

        System.assertEquals(1, result.factors[0].score, 'App4: Community Impact = 1 (50-200)');
        System.assertEquals(1, result.factors[1].score, 'App4: Track Record = 1 (5 years, 2-5 range)');
        System.assertEquals(2, result.factors[2].score, 'App4: Category Priority = 2 (Senior Services)');
        System.assertEquals(1, result.factors[3].score, 'App4: Financial Need = 1 ($500K-$1.99M)');
        System.assertEquals(1, result.factors[4].score, 'App4: Cost Efficiency = 1 (46.7%, 41-50%)');
        System.assertEquals(6, result.totalScore, 'App4: Total score should be 6/15');
        System.assertEquals(5600, result.finalAward, 'App4: Final award should be $5,600');
    }

    // ================================================================
    // TEST APPLICATION 5 - Eligible, Maximum Scores
    // Org: Faith-Based, Year 1998, Budget $65K
    // Project: Neighborhood Safety, 5000 beneficiaries, $50K/$250K
    // Expected: Eligible 6/6, Score 15/15, Award $50,000
    // ================================================================

    @IsTest
    static void testApp5_Eligibility_AllPass() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                'Faith-Based Organization', 1998, 65000, 50000, 250000, 5000
            );
        System.assertEquals(true, result.isEligible, 'App5: Should be eligible');
        System.assertEquals(6, result.rulesPassed, 'App5: All 6 rules should pass');
    }

    @IsTest
    static void testApp5_Award_50000() {
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Type__c' => 'Faith-Based Organization',
            'Year_Founded__c' => 1998,
            'Annual_Budget__c' => 65000,
            'Amount_Requested__c' => 50000,
            'Total_Project_Cost__c' => 250000,
            'Num_Beneficiaries__c' => 5000,
            'Project_Category__c' => 'Neighborhood Safety'
        });
        insert app;

        Test.startTest();
        GrantAwardService.AwardResult result = GrantAwardService.calculateAward(app.Id);
        Test.stopTest();

        System.assertEquals(3, result.factors[0].score, 'App5: Community Impact = 3 (>= 1001)');
        System.assertEquals(3, result.factors[1].score, 'App5: Track Record = 3 (28 years >= 16)');
        System.assertEquals(3, result.factors[2].score, 'App5: Category Priority = 3 (Neighborhood Safety)');
        System.assertEquals(3, result.factors[3].score, 'App5: Financial Need = 3 (< $100K)');
        System.assertEquals(3, result.factors[4].score, 'App5: Cost Efficiency = 3 (20% <= 25%)');
        System.assertEquals(15, result.totalScore, 'App5: Total score should be 15/15');
        System.assertEquals(50000, result.finalAward, 'App5: Final award should be $50,000');
    }

    // ================================================================
    // ELIGIBILITY EDGE CASES (E-01 to E-14)
    // Base: Test App 1 values, change one field per test
    // ================================================================

    @IsTest
    static void testEdge_E01_Individual_FailsRule1() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('Individual', 2005, 85000, 50000, 200000, 2500);
        System.assertEquals(false, r.rules[0].passed, 'E-01: Individual should FAIL Rule 1');
        System.assertEquals(5, r.rulesPassed, 'E-01: 5 of 6 should pass');
    }

    @IsTest
    static void testEdge_E02_GovernmentAgency_FailsRule1() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('Government Agency', 2005, 85000, 50000, 200000, 2500);
        System.assertEquals(false, r.rules[0].passed, 'E-02: Government Agency should FAIL Rule 1');
    }

    @IsTest
    static void testEdge_E03_FaithBased_PassesRule1() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('Faith-Based Organization', 2005, 85000, 50000, 200000, 2500);
        System.assertEquals(true, r.rules[0].passed, 'E-03: Faith-Based Organization should PASS Rule 1');
        System.assertEquals(6, r.rulesPassed, 'E-03: All 6 should pass');
    }

    @IsTest
    static void testEdge_E04_Year2025_FailsRule2() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2025, 85000, 50000, 200000, 2500);
        System.assertEquals(false, r.rules[1].passed, 'E-04: Year 2025 (1 year) should FAIL Rule 2');
    }

    @IsTest
    static void testEdge_E05_Year2024_PassesRule2() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2024, 85000, 50000, 200000, 2500);
        System.assertEquals(true, r.rules[1].passed, 'E-05: Year 2024 (exactly 2 years) should PASS Rule 2');
    }

    @IsTest
    static void testEdge_E06_Year2026_FailsRule2() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2026, 85000, 50000, 200000, 2500);
        System.assertEquals(false, r.rules[1].passed, 'E-06: Year 2026 (0 years) should FAIL Rule 2');
    }

    @IsTest
    static void testEdge_E07_Budget2M_FailsRule3() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2005, 2000000, 50000, 200000, 2500);
        System.assertEquals(false, r.rules[2].passed, 'E-07: Budget $2,000,000 (exactly) should FAIL Rule 3');
    }

    @IsTest
    static void testEdge_E08_BudgetJustUnder2M_PassesRule3() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2005, 1999999.99, 50000, 200000, 2500);
        System.assertEquals(true, r.rules[2].passed, 'E-08: Budget $1,999,999.99 should PASS Rule 3');
    }

    @IsTest
    static void testEdge_E09_FundingRatio50002Pct_FailsRule4() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2005, 85000, 25001, 50000, 2500);
        System.assertEquals(false, r.rules[3].passed,
            'E-09: $25,001/$50,000 = 50.002% should FAIL Rule 4');
    }

    @IsTest
    static void testEdge_E10_FundingRatio50Pct_PassesRule4() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2005, 85000, 25000, 50000, 2500);
        System.assertEquals(true, r.rules[3].passed,
            'E-10: $25,000/$50,000 = 50% should PASS Rule 4');
    }

    @IsTest
    static void testEdge_E11_RequestOver50K_FailsRule5() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2005, 85000, 50001, 200000, 2500);
        System.assertEquals(false, r.rules[4].passed,
            'E-11: $50,001 should FAIL Rule 5 (max $50,000)');
    }

    @IsTest
    static void testEdge_E12_Beneficiaries49_FailsRule6() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2005, 85000, 50000, 200000, 49);
        System.assertEquals(false, r.rules[5].passed,
            'E-12: 49 beneficiaries should FAIL Rule 6');
    }

    @IsTest
    static void testEdge_E13_Beneficiaries50_PassesRule6() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2005, 85000, 50000, 200000, 50);
        System.assertEquals(true, r.rules[5].passed,
            'E-13: 50 beneficiaries should PASS Rule 6');
    }

    @IsTest
    static void testEdge_E14_Beneficiaries1_FailsRule6() {
        GrantEligibilityService.EligibilityResult r =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2005, 85000, 50000, 200000, 1);
        System.assertEquals(false, r.rules[5].passed,
            'E-14: 1 beneficiary should FAIL Rule 6');
    }

    // ================================================================
    // AWARD SCORING BOUNDARY TESTS (A-01 to A-08)
    // Base: Test App 1, modify one field
    // ================================================================

    @IsTest
    static void testAward_A01_Beneficiaries200() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Num_Beneficiaries__c' => 200
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(1, r.factors[0].score, 'A-01: Impact(200) = 1');
        System.assertEquals(13, r.totalScore, 'A-01: Total = 13');
        System.assertEquals(43300, r.finalAward, 'A-01: Award = $43,300');
    }

    @IsTest
    static void testAward_A02_Beneficiaries201() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Num_Beneficiaries__c' => 201
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[0].score, 'A-02: Impact(201) = 2');
        System.assertEquals(14, r.totalScore, 'A-02: Total = 14');
        System.assertEquals(46700, r.finalAward, 'A-02: Award = $46,700');
    }

    @IsTest
    static void testAward_A03_Beneficiaries1000() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Num_Beneficiaries__c' => 1000
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[0].score, 'A-03: Impact(1000) = 2');
        System.assertEquals(14, r.totalScore, 'A-03: Total = 14');
        System.assertEquals(46700, r.finalAward, 'A-03: Award = $46,700');
    }

    @IsTest
    static void testAward_A04_Beneficiaries1001() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Num_Beneficiaries__c' => 1001
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(3, r.factors[0].score, 'A-04: Impact(1001) = 3');
        System.assertEquals(15, r.totalScore, 'A-04: Total = 15');
        System.assertEquals(50000, r.finalAward, 'A-04: Award = $50,000');
    }

    @IsTest
    static void testAward_A05_Budget100K() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Annual_Budget__c' => 100000
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[3].score, 'A-05: Need($100K) = 2');
        System.assertEquals(14, r.totalScore, 'A-05: Total = 14');
        System.assertEquals(46700, r.finalAward, 'A-05: Award = $46,700');
    }

    @IsTest
    static void testAward_A06_Budget99999() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Annual_Budget__c' => 99999
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(3, r.factors[3].score, 'A-06: Need($99,999) = 3');
        System.assertEquals(15, r.totalScore, 'A-06: Total = 15');
        System.assertEquals(50000, r.finalAward, 'A-06: Award = $50,000');
    }

    @IsTest
    static void testAward_A07_Budget500K() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Annual_Budget__c' => 500000
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(1, r.factors[3].score, 'A-07: Need($500K) = 1');
        System.assertEquals(13, r.totalScore, 'A-07: Total = 13');
        System.assertEquals(43300, r.finalAward, 'A-07: Award = $43,300');
    }

    @IsTest
    static void testAward_A08_Budget499999() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Annual_Budget__c' => 499999
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[3].score, 'A-08: Need($499,999) = 2');
        System.assertEquals(14, r.totalScore, 'A-08: Total = 14');
        System.assertEquals(46700, r.finalAward, 'A-08: Award = $46,700');
    }

    // ================================================================
    // REQUEST RATIO SCORING TESTS (A-09 to A-12)
    // All use App1 base with Amount=$50K, varying Total Project Cost
    // ================================================================

    @IsTest
    static void testAward_A09_Ratio25Pct() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Total_Project_Cost__c' => 200000
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(3, r.factors[4].score, 'A-09: Efficiency(25%) = 3');
        System.assertEquals(15, r.totalScore, 'A-09: Total = 15');
        System.assertEquals(50000, r.finalAward, 'A-09: Award = $50,000');
    }

    @IsTest
    static void testAward_A10_Ratio26Pct() {
        // Evaluator doc uses $192,308 but 50000/192308 = 25.9999% (truncates to 25).
        // Use $192,307 to get a true 26.0001% for boundary test.
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Total_Project_Cost__c' => 192307
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[4].score, 'A-10: Efficiency(26%) = 2');
        System.assertEquals(14, r.totalScore, 'A-10: Total = 14');
        System.assertEquals(46700, r.finalAward, 'A-10: Award = $46,700');
    }

    @IsTest
    static void testAward_A11_Ratio40Pct() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Total_Project_Cost__c' => 125000
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[4].score, 'A-11: Efficiency(40%) = 2');
        System.assertEquals(14, r.totalScore, 'A-11: Total = 14');
        System.assertEquals(46700, r.finalAward, 'A-11: Award = $46,700');
    }

    @IsTest
    static void testAward_A12_Ratio41Pct() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Total_Project_Cost__c' => 121951
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(1, r.factors[4].score, 'A-12: Efficiency(41%) = 1');
        System.assertEquals(13, r.totalScore, 'A-12: Total = 13');
        System.assertEquals(43300, r.finalAward, 'A-12: Award = $43,300');
    }

    // ================================================================
    // TRACK RECORD SCORING TESTS (A-13 to A-17)
    // ================================================================

    @IsTest
    static void testAward_A13_TrackRecord_2Years() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Year_Founded__c' => 2024
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(1, r.factors[1].score, 'A-13: Track(2 yrs) = 1');
    }

    @IsTest
    static void testAward_A14_TrackRecord_5Years() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Year_Founded__c' => 2021
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(1, r.factors[1].score, 'A-14: Track(5 yrs) = 1');
    }

    @IsTest
    static void testAward_A15_TrackRecord_6Years() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Year_Founded__c' => 2020
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[1].score, 'A-15: Track(6 yrs) = 2');
    }

    @IsTest
    static void testAward_A16_TrackRecord_15Years() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Year_Founded__c' => 2011
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[1].score, 'A-16: Track(15 yrs) = 2');
    }

    @IsTest
    static void testAward_A17_TrackRecord_16Years() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Year_Founded__c' => 2010
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(3, r.factors[1].score, 'A-17: Track(16 yrs) = 3');
    }

    // ================================================================
    // CATEGORY SCORING TESTS (A-18 to A-24)
    // ================================================================

    @IsTest
    static void testAward_A18_PublicHealth_Score3() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Project_Category__c' => 'Public Health'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(3, r.factors[2].score, 'A-18: Public Health = 3');
    }

    @IsTest
    static void testAward_A19_NeighborhoodSafety_Score3() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Project_Category__c' => 'Neighborhood Safety'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(3, r.factors[2].score, 'A-19: Neighborhood Safety = 3');
    }

    @IsTest
    static void testAward_A20_YouthPrograms_Score2() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Project_Category__c' => 'Youth Programs'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[2].score, 'A-20: Youth Programs = 2');
    }

    @IsTest
    static void testAward_A21_SeniorServices_Score2() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Project_Category__c' => 'Senior Services'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(2, r.factors[2].score, 'A-21: Senior Services = 2');
    }

    @IsTest
    static void testAward_A22_ArtsAndCulture_Score1() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Project_Category__c' => 'Arts & Culture'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(1, r.factors[2].score, 'A-22: Arts & Culture = 1');
    }

    @IsTest
    static void testAward_A23_WorkforceDev_Score1() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Project_Category__c' => 'Workforce Development'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(1, r.factors[2].score, 'A-23: Workforce Development = 1');
    }

    @IsTest
    static void testAward_A24_Other_Score1() {
        Grant_Application__c app = createApp1Base(new Map<String, Object>{
            'Project_Category__c' => 'Other'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(1, r.factors[2].score, 'A-24: Other = 1');
    }

    // ================================================================
    // ROUNDING TESTS (A-25 to A-28)
    // ================================================================

    @IsTest
    static void testAward_A25_Rounding_Score7_Award4700() {
        // Score 7: Impact=1(100), Track=1(4yrs), Cat=3(PH), Need=1($600K), Eff=1(45%)
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Type__c' => '501(c)(3)',
            'Year_Founded__c' => 2022,
            'Annual_Budget__c' => 600000,
            'Amount_Requested__c' => 10000,
            'Total_Project_Cost__c' => 22000,
            'Num_Beneficiaries__c' => 100,
            'Project_Category__c' => 'Public Health'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(7, r.totalScore, 'A-25: Total score = 7');
        System.assertEquals(4700, r.finalAward, 'A-25: $10K * 46.7% rounded = $4,700');
    }

    @IsTest
    static void testAward_A26_Rounding_Score8_Award5300() {
        // Score 8: Impact=1(100), Track=2(6yrs), Cat=3(PH), Need=1($600K), Eff=1(45%)
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Type__c' => '501(c)(3)',
            'Year_Founded__c' => 2020,
            'Annual_Budget__c' => 600000,
            'Amount_Requested__c' => 10000,
            'Total_Project_Cost__c' => 22000,
            'Num_Beneficiaries__c' => 100,
            'Project_Category__c' => 'Public Health'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(8, r.totalScore, 'A-26: Total score = 8');
        System.assertEquals(5300, r.finalAward, 'A-26: $10K * 53.3% rounded = $5,300');
    }

    @IsTest
    static void testAward_A27_Rounding_Score11_Award11000() {
        // Score 11: Impact=1(100), Track=3(21yrs), Cat=3(PH), Need=3($85K), Eff=1(45%)
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Type__c' => '501(c)(3)',
            'Year_Founded__c' => 2005,
            'Annual_Budget__c' => 85000,
            'Amount_Requested__c' => 15000,
            'Total_Project_Cost__c' => 33000,
            'Num_Beneficiaries__c' => 100,
            'Project_Category__c' => 'Public Health'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(11, r.totalScore, 'A-27: Total score = 11');
        System.assertEquals(11000, r.finalAward, 'A-27: $15K * 73.3% rounded = $11,000');
    }

    @IsTest
    static void testAward_A28_Rounding_Score5_Award11100() {
        // Score 5: Impact=1(100), Track=1(4yrs), Cat=1(A&C), Need=1($600K), Eff=1(45%)
        Grant_Application__c app = TestDataFactory.createApplication(new Map<String, Object>{
            'Organization_Type__c' => '501(c)(3)',
            'Year_Founded__c' => 2022,
            'Annual_Budget__c' => 600000,
            'Amount_Requested__c' => 33333,
            'Total_Project_Cost__c' => 74000,
            'Num_Beneficiaries__c' => 100,
            'Project_Category__c' => 'Arts & Culture'
        });
        insert app;

        GrantAwardService.AwardResult r = GrantAwardService.calculateAward(app.Id);
        System.assertEquals(5, r.totalScore, 'A-28: Total score = 5');
        System.assertEquals(11100, r.finalAward, 'A-28: $33,333 * 33.3% rounded = $11,100');
    }

    // ================================================================
    // WORKFLOW TESTS (W-01 to W-05)
    // ================================================================

    @IsTest
    static void testWorkflow_W01_SubmitSetsSubmitted() {
        Grant_Application__c app = TestDataFactory.createApplication();
        insert app;

        Grant_Application__c inserted = [SELECT Status__c FROM Grant_Application__c WHERE Id = :app.Id];
        System.assertEquals('Submitted', inserted.Status__c, 'W-01: New application should be Submitted');
    }

    @IsTest
    static void testWorkflow_W02_ReviewerOpensUnderReview() {
        Grant_Application__c app = TestDataFactory.createApplication();
        insert app;

        Test.startTest();
        GrantApplicationController.updateStatus(app.Id, 'Under Review', null);
        Test.stopTest();

        Grant_Application__c updated = [SELECT Status__c FROM Grant_Application__c WHERE Id = :app.Id];
        System.assertEquals('Under Review', updated.Status__c, 'W-02: Should transition to Under Review');
    }

    @IsTest
    static void testWorkflow_W03_ApproveCalculatesAward() {
        Grant_Application__c app = createApp1Base(null);
        insert app;

        GrantApplicationController.updateStatus(app.Id, 'Under Review', null);

        Test.startTest();
        GrantAwardService.approveApplication(app.Id, null);
        Test.stopTest();

        Grant_Application__c updated = [
            SELECT Status__c, Award_Amount__c, Award_Breakdown__c,
                   Reviewed_Date__c, Reviewer__c
            FROM Grant_Application__c WHERE Id = :app.Id
        ];
        System.assertEquals('Approved', updated.Status__c, 'W-03: Status should be Approved');
        System.assertNotEquals(null, updated.Award_Amount__c, 'W-03: Award amount should be set');
        System.assertEquals(50000, updated.Award_Amount__c, 'W-03: Award should be $50,000');
        System.assertNotEquals(null, updated.Award_Breakdown__c, 'W-03: Breakdown should be stored');
        System.assertNotEquals(null, updated.Reviewed_Date__c, 'W-03: Reviewed date should be set');
        System.assertEquals(UserInfo.getUserId(), updated.Reviewer__c, 'W-03: Reviewer should be current user');
    }

    @IsTest
    static void testWorkflow_W05_RejectStoresComment() {
        Grant_Application__c app = TestDataFactory.createApplication();
        insert app;

        String rejectComment = 'Application does not meet eligibility criteria.';

        Test.startTest();
        GrantApplicationController.updateStatus(app.Id, 'Rejected', rejectComment);
        Test.stopTest();

        Grant_Application__c updated = [
            SELECT Status__c, Reviewer_Comments__c, Reviewed_Date__c, Reviewer__c
            FROM Grant_Application__c WHERE Id = :app.Id
        ];
        System.assertEquals('Rejected', updated.Status__c, 'W-05: Status should be Rejected');
        System.assertEquals(rejectComment, updated.Reviewer_Comments__c, 'W-05: Comment should be stored');
        System.assertNotEquals(null, updated.Reviewed_Date__c, 'W-05: Reviewed date should be set');
    }

    // ================================================================
    // STATUS TRANSITION VALIDATION
    // ================================================================

    @IsTest
    static void testWorkflow_InvalidTransition_ApprovedToSubmitted() {
        Grant_Application__c app = createApp1Base(null);
        insert app;

        GrantAwardService.approveApplication(app.Id, null);

        Test.startTest();
        try {
            GrantApplicationController.updateStatus(app.Id, 'Submitted', null);
            System.assert(false, 'Should have thrown exception for invalid transition');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid status transition') ||
                          e.getMessage().contains('cannot move'),
                'Should mention invalid transition');
        }
        Test.stopTest();
    }

    // ================================================================
    // HELPERS
    // ================================================================

    private static Grant_Application__c createApp1Base(Map<String, Object> overrides) {
        Map<String, Object> base = new Map<String, Object>{
            'Organization_Name__c' => 'Maplewood Public Health Coalition',
            'EIN__c' => '52-9876543',
            'Organization_Type__c' => '501(c)(3)',
            'Year_Founded__c' => 2005,
            'Annual_Budget__c' => 85000,
            'Num_Employees__c' => 4,
            'Contact_Name__c' => 'Dr. Angela Rivera',
            'Contact_Email__c' => 'angela@mphc.org',
            'Contact_Phone__c' => '4105550201',
            'Organization_Address__c' => '100 Health Way, Maplewood, MD 21201',
            'Mission_Statement__c' => 'The Maplewood Public Health Coalition works to improve community health outcomes.',
            'Project_Title__c' => 'Community Wellness Navigator Program',
            'Project_Category__c' => 'Public Health',
            'Project_Description__c' => 'Deploy 10 trained community health workers across 5 underserved neighborhoods.',
            'Target_Population__c' => 'Low-income residents in underserved Maplewood neighborhoods',
            'Num_Beneficiaries__c' => 2500,
            'Total_Project_Cost__c' => 200000,
            'Amount_Requested__c' => 50000,
            'Previously_Funded__c' => false
        };
        if (overrides != null) {
            base.putAll(overrides);
        }
        return TestDataFactory.createApplication(base);
    }
}
