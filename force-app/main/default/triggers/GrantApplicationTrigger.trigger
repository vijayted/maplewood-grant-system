trigger GrantApplicationTrigger on Grant_Application__c (after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        GrantApplicationTriggerHandler.handleAfterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        GrantApplicationTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
