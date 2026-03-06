Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Grant_Application__c.fields.getMap();
for (String f : fieldMap.keySet()) {
    Schema.DescribeFieldResult dfr = fieldMap.get(f).getDescribe();
    if (dfr.isCustom()) {
        System.debug(f + ' -> createable: ' + dfr.isCreateable() + ', updateable: ' + dfr.isUpdateable());
    }
}
