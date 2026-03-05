public with sharing class GrantEligibilityService {

    private static final Set<String> ELIGIBLE_ORG_TYPES = new Set<String>{
        '501(c)(3)', '501(c)(4)', 'Community-Based Organization', 'Faith-Based Organization'
    };
    private static final Integer MIN_OPERATING_YEARS = 2;
    private static final Decimal MAX_BUDGET = 2000000;
    private static final Decimal MAX_FUNDING_RATIO = 0.50;
    private static final Decimal MAX_REQUEST_AMOUNT = 50000;
    private static final Integer MIN_BENEFICIARIES = 50;
    private static final Integer TOTAL_RULES = 6;

    public class EligibilityResult {
        @AuraEnabled public List<RuleResult> rules;
        @AuraEnabled public Integer rulesPassed;
        @AuraEnabled public Integer totalRules;
        @AuraEnabled public Boolean isEligible;

        public EligibilityResult() {
            this.rules = new List<RuleResult>();
            this.rulesPassed = 0;
            this.totalRules = TOTAL_RULES;
            this.isEligible = false;
        }
    }

    public class RuleResult {
        @AuraEnabled public Integer ruleNumber;
        @AuraEnabled public String ruleName;
        @AuraEnabled public Boolean passed;
        @AuraEnabled public String message;
        @AuraEnabled public Boolean evaluated;

        public RuleResult(Integer num, String name) {
            this.ruleNumber = num;
            this.ruleName = name;
            this.passed = false;
            this.message = '';
            this.evaluated = false;
        }
    }

    @AuraEnabled
    public static EligibilityResult checkEligibility(
        String organizationType,
        Integer yearFounded,
        Decimal annualBudget,
        Decimal amountRequested,
        Decimal totalProjectCost,
        Integer numBeneficiaries
    ) {
        EligibilityResult result = new EligibilityResult();

        result.rules.add(checkNonprofitStatus(organizationType));
        result.rules.add(checkOperatingHistory(yearFounded));
        result.rules.add(checkBudgetCap(annualBudget));
        result.rules.add(checkFundingRatio(amountRequested, totalProjectCost));
        result.rules.add(checkMaximumRequest(amountRequested));
        result.rules.add(checkMinimumImpact(numBeneficiaries));

        Integer passed = 0;
        for (RuleResult rule : result.rules) {
            if (rule.evaluated && rule.passed) {
                passed++;
            }
        }
        result.rulesPassed = passed;
        result.isEligible = (passed == TOTAL_RULES);

        return result;
    }

    private static RuleResult checkNonprofitStatus(String organizationType) {
        RuleResult rule = new RuleResult(1, 'Nonprofit Status');
        if (String.isBlank(organizationType)) {
            return rule;
        }
        rule.evaluated = true;
        if (ELIGIBLE_ORG_TYPES.contains(organizationType)) {
            rule.passed = true;
            rule.message = 'Eligible organization type';
        } else {
            rule.passed = false;
            rule.message = 'Only nonprofit and community organizations are eligible';
        }
        return rule;
    }

    private static RuleResult checkOperatingHistory(Integer yearFounded) {
        RuleResult rule = new RuleResult(2, 'Minimum Operating History');
        if (yearFounded == null) {
            return rule;
        }
        rule.evaluated = true;
        Integer currentYear = Date.today().year();
        Integer yearsOperating = currentYear - yearFounded;
        if (yearsOperating >= MIN_OPERATING_YEARS) {
            rule.passed = true;
            rule.message = 'Organization has been operating for ' + yearsOperating + ' years';
        } else {
            rule.passed = false;
            rule.message = 'Organization must be at least 2 years old';
        }
        return rule;
    }

    private static RuleResult checkBudgetCap(Decimal annualBudget) {
        RuleResult rule = new RuleResult(3, 'Budget Cap');
        if (annualBudget == null) {
            return rule;
        }
        rule.evaluated = true;
        if (annualBudget < MAX_BUDGET) {
            rule.passed = true;
            rule.message = 'Operating budget is within limit';
        } else {
            rule.passed = false;
            rule.message = 'Organizations with budgets of $2M or more are not eligible';
        }
        return rule;
    }

    private static RuleResult checkFundingRatio(Decimal amountRequested, Decimal totalProjectCost) {
        RuleResult rule = new RuleResult(4, 'Funding Ratio');
        if (amountRequested == null || totalProjectCost == null || totalProjectCost == 0) {
            return rule;
        }
        rule.evaluated = true;
        Decimal ratio = amountRequested / totalProjectCost;
        Integer percentage = (Integer)(ratio * 100);
        if (ratio <= MAX_FUNDING_RATIO) {
            rule.passed = true;
            rule.message = 'Requested amount is ' + percentage + '% of project cost';
        } else {
            rule.passed = false;
            rule.message = 'Requested amount cannot exceed 50% of total project cost';
        }
        return rule;
    }

    private static RuleResult checkMaximumRequest(Decimal amountRequested) {
        RuleResult rule = new RuleResult(5, 'Maximum Request');
        if (amountRequested == null) {
            return rule;
        }
        rule.evaluated = true;
        if (amountRequested <= MAX_REQUEST_AMOUNT) {
            rule.passed = true;
            rule.message = 'Requested amount is within the $50,000 maximum';
        } else {
            rule.passed = false;
            rule.message = 'Maximum grant amount is $50,000';
        }
        return rule;
    }

    private static RuleResult checkMinimumImpact(Integer numBeneficiaries) {
        RuleResult rule = new RuleResult(6, 'Minimum Impact');
        if (numBeneficiaries == null) {
            return rule;
        }
        rule.evaluated = true;
        if (numBeneficiaries >= MIN_BENEFICIARIES) {
            rule.passed = true;
            rule.message = 'Project will serve ' + numBeneficiaries + ' beneficiaries';
        } else {
            rule.passed = false;
            rule.message = 'Project must serve at least 50 beneficiaries';
        }
        return rule;
    }
}
