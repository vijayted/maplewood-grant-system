@IsTest
private class GrantEligibilityServiceTest {

    @IsTest
    static void testAllRulesPassing() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', 2015, 320000, 40000, 95000, 500
            );

        System.assertEquals(6, result.rulesPassed, 'All 6 rules should pass');
        System.assertEquals(6, result.totalRules);
        System.assertEquals(true, result.isEligible);
        for (GrantEligibilityService.RuleResult rule : result.rules) {
            System.assertEquals(true, rule.passed, 'Rule ' + rule.ruleNumber + ' should pass');
            System.assertEquals(true, rule.evaluated, 'Rule ' + rule.ruleNumber + ' should be evaluated');
        }
    }

    @IsTest
    static void testNonprofitStatusFails() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                'For-Profit Business', 2015, 320000, 40000, 95000, 500
            );

        System.assertEquals(false, result.isEligible);
        System.assertEquals(5, result.rulesPassed);
        System.assertEquals(false, result.rules[0].passed);
        System.assert(result.rules[0].message.contains('Only nonprofit'));
    }

    @IsTest
    static void testOperatingHistoryFails() {
        Integer currentYear = Date.today().year();
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', currentYear, 320000, 40000, 95000, 500
            );

        System.assertEquals(false, result.isEligible);
        System.assertEquals(false, result.rules[1].passed);
        System.assert(result.rules[1].message.contains('at least 2 years'));
    }

    @IsTest
    static void testBudgetCapFails() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', 2015, 2500000, 40000, 95000, 500
            );

        System.assertEquals(false, result.isEligible);
        System.assertEquals(false, result.rules[2].passed);
        System.assert(result.rules[2].message.contains('$2M or more'));
    }

    @IsTest
    static void testBudgetCapBoundary() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', 2015, 2000000, 40000, 95000, 500
            );

        System.assertEquals(false, result.rules[2].passed, 'Budget of exactly $2M should fail');
    }

    @IsTest
    static void testFundingRatioFails() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', 2015, 320000, 50000, 80000, 500
            );

        System.assertEquals(false, result.isEligible);
        System.assertEquals(false, result.rules[3].passed);
        System.assert(result.rules[3].message.contains('exceed 50%'));
    }

    @IsTest
    static void testFundingRatioBoundary() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', 2015, 320000, 50000, 100000, 500
            );

        System.assertEquals(true, result.rules[3].passed, 'Exactly 50% should pass');
    }

    @IsTest
    static void testMaximumRequestFails() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', 2015, 320000, 60000, 200000, 500
            );

        System.assertEquals(false, result.isEligible);
        System.assertEquals(false, result.rules[4].passed);
        System.assert(result.rules[4].message.contains('$50,000'));
    }

    @IsTest
    static void testMinimumImpactFails() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', 2015, 320000, 40000, 95000, 30
            );

        System.assertEquals(false, result.isEligible);
        System.assertEquals(false, result.rules[5].passed);
        System.assert(result.rules[5].message.contains('at least 50'));
    }

    @IsTest
    static void testMinimumImpactBoundary() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(
                '501(c)(3)', 2015, 320000, 40000, 95000, 50
            );

        System.assertEquals(true, result.rules[5].passed, 'Exactly 50 beneficiaries should pass');
    }

    @IsTest
    static void testNullFieldsNotEvaluated() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility(null, null, null, null, null, null);

        System.assertEquals(0, result.rulesPassed);
        System.assertEquals(false, result.isEligible);
        for (GrantEligibilityService.RuleResult rule : result.rules) {
            System.assertEquals(false, rule.evaluated, 'Rule ' + rule.ruleNumber + ' should not be evaluated with null input');
        }
    }

    @IsTest
    static void testAllEligibleOrgTypes() {
        List<String> eligibleTypes = new List<String>{
            '501(c)(3)', '501(c)(4)', 'Community-Based Organization', 'Faith-Based Organization'
        };
        for (String orgType : eligibleTypes) {
            GrantEligibilityService.EligibilityResult result =
                GrantEligibilityService.checkEligibility(orgType, 2015, 320000, 40000, 95000, 500);
            System.assertEquals(true, result.rules[0].passed, orgType + ' should be eligible');
        }
    }

    @IsTest
    static void testIneligibleOrgTypes() {
        List<String> ineligibleTypes = new List<String>{
            'For-Profit Business', 'Government Agency', 'Individual'
        };
        for (String orgType : ineligibleTypes) {
            GrantEligibilityService.EligibilityResult result =
                GrantEligibilityService.checkEligibility(orgType, 2015, 320000, 40000, 95000, 500);
            System.assertEquals(false, result.rules[0].passed, orgType + ' should not be eligible');
        }
    }

    @IsTest
    static void testEmptyStringOrgType() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility('', 2015, 320000, 40000, 95000, 500);

        System.assertEquals(false, result.rules[0].evaluated, 'Blank org type should not be evaluated');
    }

    @IsTest
    static void testZeroProjectCost() {
        GrantEligibilityService.EligibilityResult result =
            GrantEligibilityService.checkEligibility('501(c)(3)', 2015, 320000, 40000, 0, 500);

        System.assertEquals(false, result.rules[3].evaluated, 'Zero project cost should not evaluate funding ratio');
    }
}
