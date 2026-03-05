public with sharing class GrantAwardService {

    private static final Decimal MAX_AWARD = 50000;
    private static final Integer MAX_SCORE = 15;

    private static final Set<String> HIGH_PRIORITY_CATEGORIES = new Set<String>{
        'Public Health', 'Neighborhood Safety'
    };
    private static final Set<String> MEDIUM_PRIORITY_CATEGORIES = new Set<String>{
        'Youth Programs', 'Senior Services'
    };

    public class AwardResult {
        @AuraEnabled public List<FactorScore> factors;
        @AuraEnabled public Integer totalScore;
        @AuraEnabled public Integer maxScore;
        @AuraEnabled public Decimal awardPercentage;
        @AuraEnabled public Decimal rawAward;
        @AuraEnabled public Decimal finalAward;

        public AwardResult() {
            this.factors = new List<FactorScore>();
            this.totalScore = 0;
            this.maxScore = MAX_SCORE;
        }
    }

    public class FactorScore {
        @AuraEnabled public String factorName;
        @AuraEnabled public Integer score;
        @AuraEnabled public String reasoning;

        public FactorScore(String name, Integer score, String reasoning) {
            this.factorName = name;
            this.score = score;
            this.reasoning = reasoning;
        }
    }

    @AuraEnabled
    public static AwardResult calculateAward(Id applicationId) {
        try {
            Grant_Application__c app = [
                SELECT Id, Num_Beneficiaries__c, Year_Founded__c,
                       Project_Category__c, Annual_Budget__c,
                       Amount_Requested__c, Total_Project_Cost__c
                FROM Grant_Application__c
                WHERE Id = :applicationId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            AwardResult result = new AwardResult();

            result.factors.add(scoreCommunityImpact(app.Num_Beneficiaries__c));
            result.factors.add(scoreOrganizationTrackRecord(app.Year_Founded__c));
            result.factors.add(scoreCategoryPriority(app.Project_Category__c));
            result.factors.add(scoreFinancialNeed(app.Annual_Budget__c));
            result.factors.add(scoreCostEfficiency(app.Amount_Requested__c, app.Total_Project_Cost__c));

            Integer total = 0;
            for (FactorScore fs : result.factors) {
                total += fs.score;
            }
            result.totalScore = total;
            result.awardPercentage = (Decimal)total / MAX_SCORE;

            Decimal rawAward = app.Amount_Requested__c * result.awardPercentage;
            result.rawAward = rawAward;

            Decimal rounded = Math.round(rawAward / 100.0) * 100;
            result.finalAward = Math.min(rounded, MAX_AWARD);

            return result;
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in calculateAward: ' + qe.getMessage() + '\n' + qe.getStackTraceString());
            throw new AuraHandledException('Unable to retrieve the application for award calculation. Please try again.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ' in calculateAward: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('An unexpected error occurred during award calculation. Please try again.');
        }
    }

    @AuraEnabled
    public static void approveApplication(Id applicationId, String awardResultJson) {
        try {
            AwardResult result;
            if (String.isNotBlank(awardResultJson)) {
                result = (AwardResult) JSON.deserialize(awardResultJson, AwardResult.class);
            } else {
                result = calculateAward(applicationId);
            }

            Grant_Application__c app = new Grant_Application__c(
                Id = applicationId,
                Status__c = 'Approved',
                Award_Amount__c = result.finalAward,
                Award_Breakdown__c = JSON.serialize(result),
                Reviewed_Date__c = DateTime.now(),
                Reviewer__c = UserInfo.getUserId()
            );

            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPDATABLE, new List<Grant_Application__c>{ app }
            );
            update decision.getRecords();
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (DmlException de) {
            System.debug(LoggingLevel.ERROR, 'DmlException in approveApplication: ' + de.getMessage() + '\n' + de.getStackTraceString());
            throw new AuraHandledException('A database error occurred while approving the application. Please try again.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getTypeName() + ' in approveApplication: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('An unexpected error occurred. Please try again.');
        }
    }

    private static FactorScore scoreCommunityImpact(Decimal beneficiaries) {
        Integer ben = (beneficiaries != null) ? beneficiaries.intValue() : 0;
        Integer score;
        String reasoning;

        if (ben >= 1001) {
            score = 3;
            reasoning = ben + ' beneficiaries (1,001+) = 3 points';
        } else if (ben >= 201) {
            score = 2;
            reasoning = ben + ' beneficiaries (201-1,000) = 2 points';
        } else {
            score = 1;
            reasoning = ben + ' beneficiaries (50-200) = 1 point';
        }
        return new FactorScore('Community Impact', score, reasoning);
    }

    private static FactorScore scoreOrganizationTrackRecord(Decimal yearFounded) {
        Integer currentYear = Date.today().year();
        Integer years = (yearFounded != null) ? currentYear - yearFounded.intValue() : 0;
        Integer score;
        String reasoning;

        if (years >= 16) {
            score = 3;
            reasoning = years + ' years operating (16+) = 3 points';
        } else if (years >= 6) {
            score = 2;
            reasoning = years + ' years operating (6-15) = 2 points';
        } else {
            score = 1;
            reasoning = years + ' years operating (2-5) = 1 point';
        }
        return new FactorScore('Organization Track Record', score, reasoning);
    }

    private static FactorScore scoreCategoryPriority(String category) {
        Integer score;
        String reasoning;

        if (HIGH_PRIORITY_CATEGORIES.contains(category)) {
            score = 3;
            reasoning = category + ' (high priority) = 3 points';
        } else if (MEDIUM_PRIORITY_CATEGORIES.contains(category)) {
            score = 2;
            reasoning = category + ' (medium priority) = 2 points';
        } else {
            score = 1;
            reasoning = category + ' (standard priority) = 1 point';
        }
        return new FactorScore('Project Category Priority', score, reasoning);
    }

    private static FactorScore scoreFinancialNeed(Decimal annualBudget) {
        Integer score;
        String reasoning;
        Decimal budget = (annualBudget != null) ? annualBudget : 0;

        if (budget < 100000) {
            score = 3;
            reasoning = 'Budget $' + budget.setScale(0).toPlainString() + ' (under $100K) = 3 points';
        } else if (budget < 500000) {
            score = 2;
            reasoning = 'Budget $' + budget.setScale(0).toPlainString() + ' ($100K-$499K) = 2 points';
        } else {
            score = 1;
            reasoning = 'Budget $' + budget.setScale(0).toPlainString() + ' ($500K-$1.99M) = 1 point';
        }
        return new FactorScore('Financial Need', score, reasoning);
    }

    private static FactorScore scoreCostEfficiency(Decimal amountRequested, Decimal totalProjectCost) {
        Integer score;
        String reasoning;

        if (amountRequested == null || totalProjectCost == null || totalProjectCost == 0) {
            return new FactorScore('Cost Efficiency', 1, 'Unable to calculate ratio = 1 point');
        }

        Decimal ratio = (amountRequested / totalProjectCost) * 100;
        Integer pct = ratio.intValue();

        if (pct <= 25) {
            score = 3;
            reasoning = pct + '% of project cost (25% or less) = 3 points';
        } else if (pct <= 40) {
            score = 2;
            reasoning = pct + '% of project cost (26%-40%) = 2 points';
        } else {
            score = 1;
            reasoning = pct + '% of project cost (41%-50%) = 1 point';
        }
        return new FactorScore('Cost Efficiency', score, reasoning);
    }
}
