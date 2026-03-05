@IsTest
public class TestDataFactory {

    private static final Map<String, Object> DEFAULT_VALUES = new Map<String, Object>{
        'Organization_Name__c' => 'Test Nonprofit',
        'EIN__c' => '52-1234567',
        'Organization_Type__c' => '501(c)(3)',
        'Year_Founded__c' => 2015,
        'Annual_Budget__c' => 320000,
        'Num_Employees__c' => 8,
        'Contact_Name__c' => 'Jane Doe',
        'Contact_Email__c' => 'jane@test.org',
        'Contact_Phone__c' => '4105550100',
        'Organization_Address__c' => '123 Test Street',
        'Mission_Statement__c' => 'Serving the community through education.',
        'Project_Title__c' => 'Education Initiative',
        'Project_Category__c' => 'Youth Programs',
        'Project_Description__c' => 'A comprehensive education program serving at-risk youth.',
        'Target_Population__c' => 'At-risk youth ages 10-18',
        'Num_Beneficiaries__c' => 500,
        'Total_Project_Cost__c' => 95000,
        'Amount_Requested__c' => 40000,
        'Previously_Funded__c' => false,
        'Status__c' => 'Submitted',
        'Is_Eligible__c' => true,
        'Eligibility_Score__c' => 6
    };

    public static Grant_Application__c createApplication(Map<String, Object> overrides) {
        Grant_Application__c app = new Grant_Application__c();

        Map<String, Object> merged = new Map<String, Object>(DEFAULT_VALUES);
        if (!merged.containsKey('Project_Start_Date__c')) {
            merged.put('Project_Start_Date__c', Date.today().addDays(60));
        }
        if (!merged.containsKey('Project_End_Date__c')) {
            merged.put('Project_End_Date__c', Date.today().addDays(425));
        }

        if (overrides != null) {
            merged.putAll(overrides);
        }

        for (String fieldName : merged.keySet()) {
            app.put(fieldName, merged.get(fieldName));
        }

        return app;
    }

    public static Grant_Application__c createApplication() {
        return createApplication(null);
    }
}
