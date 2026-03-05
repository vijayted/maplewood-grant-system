public with sharing class GrantApplicationTriggerHandler {

    private static Boolean isExecuting = false;

    public static void handleAfterInsert(List<Grant_Application__c> newApps) {
        if (isExecuting) {
            return;
        }
        isExecuting = true;
        try {
            List<Grant_Application_Event__e> events = new List<Grant_Application_Event__e>();
            for (Grant_Application__c app : newApps) {
                events.add(new Grant_Application_Event__e(
                    Application_Id__c = app.Id,
                    Application_Name__c = app.Name,
                    New_Status__c = app.Status__c,
                    Old_Status__c = null,
                    Organization_Name__c = app.Organization_Name__c
                ));
            }

            if (!events.isEmpty()) {
                EventBus.publish(events);
            }
        } finally {
            isExecuting = false;
        }
    }

    public static void handleAfterUpdate(
        List<Grant_Application__c> newApps,
        Map<Id, Grant_Application__c> oldMap
    ) {
        if (isExecuting) {
            return;
        }
        isExecuting = true;
        try {
            List<Status_History__c> histories = new List<Status_History__c>();
            List<Grant_Application_Event__e> events = new List<Grant_Application_Event__e>();
            List<Id> appsNeedingEmail = new List<Id>();

            for (Grant_Application__c newApp : newApps) {
                Grant_Application__c oldApp = oldMap.get(newApp.Id);
                if (newApp.Status__c != oldApp.Status__c) {
                    histories.add(new Status_History__c(
                        Application__c = newApp.Id,
                        Old_Status__c = oldApp.Status__c,
                        New_Status__c = newApp.Status__c,
                        Changed_By__c = UserInfo.getUserId(),
                        Comments__c = newApp.Reviewer_Comments__c,
                        Changed_At__c = DateTime.now()
                    ));

                    events.add(new Grant_Application_Event__e(
                        Application_Id__c = newApp.Id,
                        Application_Name__c = newApp.Name,
                        New_Status__c = newApp.Status__c,
                        Old_Status__c = oldApp.Status__c,
                        Organization_Name__c = newApp.Organization_Name__c
                    ));

                    if (newApp.Status__c == 'Approved' || newApp.Status__c == 'Rejected') {
                        appsNeedingEmail.add(newApp.Id);
                    }
                }
            }

            if (!histories.isEmpty()) {
                insert histories;
            }

            if (!events.isEmpty()) {
                EventBus.publish(events);
            }

            if (!appsNeedingEmail.isEmpty()) {
                GrantNotificationService.sendStatusNotifications(appsNeedingEmail);
            }
        } finally {
            isExecuting = false;
        }
    }
}
