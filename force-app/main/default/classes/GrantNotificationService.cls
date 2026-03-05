public with sharing class GrantNotificationService {

    @future
    public static void sendStatusNotifications(List<Id> applicationIds) {
        List<Grant_Application__c> apps = [
            SELECT Id, Name, Project_Title__c, Status__c,
                   Contact_Email__c, Contact_Name__c, Organization_Name__c,
                   Award_Amount__c, Reviewer_Comments__c
            FROM Grant_Application__c
            WHERE Id IN :applicationIds
            WITH SECURITY_ENFORCED
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Grant_Application__c app : apps) {
            if (String.isBlank(app.Contact_Email__c)) continue;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ app.Contact_Email__c });
            mail.setSaveAsActivity(false);

            if (app.Status__c == 'Approved') {
                mail.setSubject('Grant Application ' + app.Name + ' - Approved');
                mail.setHtmlBody(buildApprovalEmail(app));
            } else if (app.Status__c == 'Rejected') {
                mail.setSubject('Grant Application ' + app.Name + ' - Not Approved');
                mail.setHtmlBody(buildRejectionEmail(app));
            }

            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Email send failed: ' + e.getMessage());
            }
        }
    }

    private static String buildApprovalEmail(Grant_Application__c app) {
        String award = (app.Award_Amount__c != null)
            ? '$' + app.Award_Amount__c.setScale(0).toPlainString()
            : '$0';

        String safeName = esc(app.Name);
        String safeContact = esc(String.valueOf(app.Contact_Name__c));
        String safeOrg = esc(app.Organization_Name__c);
        String safeProject = esc(app.Project_Title__c);

        return '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">'
            + '<div style="background: #1a652a; color: white; padding: 24px; text-align: center;">'
            + '<h1 style="margin: 0; font-size: 24px;">Congratulations!</h1>'
            + '</div>'
            + '<div style="padding: 24px; background: #f9f9f9;">'
            + '<p>Dear ' + safeContact + ',</p>'
            + '<p>We are pleased to inform you that your grant application has been <strong>approved</strong>.</p>'
            + '<table style="width: 100%; border-collapse: collapse; margin: 16px 0;">'
            + '<tr><td style="padding: 8px; border-bottom: 1px solid #ddd; font-weight: bold;">Application</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ddd;">' + safeName + '</td></tr>'
            + '<tr><td style="padding: 8px; border-bottom: 1px solid #ddd; font-weight: bold;">Organization</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ddd;">' + safeOrg + '</td></tr>'
            + '<tr><td style="padding: 8px; border-bottom: 1px solid #ddd; font-weight: bold;">Project</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ddd;">' + safeProject + '</td></tr>'
            + '<tr style="background: #e8f5e9;"><td style="padding: 8px; font-weight: bold; font-size: 18px;">Award Amount</td>'
            + '<td style="padding: 8px; font-weight: bold; font-size: 18px; color: #1a652a;">' + award + '</td></tr>'
            + '</table>'
            + '<p>You can view the full details by logging into the <a href="' + getPortalUrl() + '">Maplewood Grant Portal</a>.</p>'
            + '<p>Thank you for your commitment to the Maplewood County community.</p>'
            + '<p>Sincerely,<br/>Maplewood County Grants Office</p>'
            + '</div>'
            + '</div>';
    }

    private static String buildRejectionEmail(Grant_Application__c app) {
        String comments = String.isNotBlank(app.Reviewer_Comments__c)
            ? esc(app.Reviewer_Comments__c)
            : 'No additional comments provided.';

        String safeName = esc(app.Name);
        String safeContact = esc(String.valueOf(app.Contact_Name__c));
        String safeOrg = esc(app.Organization_Name__c);
        String safeProject = esc(app.Project_Title__c);

        return '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">'
            + '<div style="background: #003068; color: white; padding: 24px; text-align: center;">'
            + '<h1 style="margin: 0; font-size: 24px;">Application Update</h1>'
            + '</div>'
            + '<div style="padding: 24px; background: #f9f9f9;">'
            + '<p>Dear ' + safeContact + ',</p>'
            + '<p>Thank you for submitting your grant application to Maplewood County. '
            + 'After careful review, we regret to inform you that your application was <strong>not approved</strong> at this time.</p>'
            + '<table style="width: 100%; border-collapse: collapse; margin: 16px 0;">'
            + '<tr><td style="padding: 8px; border-bottom: 1px solid #ddd; font-weight: bold;">Application</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ddd;">' + safeName + '</td></tr>'
            + '<tr><td style="padding: 8px; border-bottom: 1px solid #ddd; font-weight: bold;">Organization</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ddd;">' + safeOrg + '</td></tr>'
            + '<tr><td style="padding: 8px; border-bottom: 1px solid #ddd; font-weight: bold;">Project</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ddd;">' + safeProject + '</td></tr>'
            + '</table>'
            + '<div style="background: #fff3e0; border-left: 4px solid #e65100; padding: 12px; margin: 16px 0;">'
            + '<strong>Reviewer Comments:</strong><br/>' + comments
            + '</div>'
            + '<p>We encourage you to review the feedback and consider applying again in the future.</p>'
            + '<p>You can view the full details by logging into the <a href="' + getPortalUrl() + '">Maplewood Grant Portal</a>.</p>'
            + '<p>Sincerely,<br/>Maplewood County Grants Office</p>'
            + '</div>'
            + '</div>';
    }

    private static String esc(String input) {
        return String.isBlank(input) ? '' : input.escapeHtml4();
    }

    @TestVisible
    private static String getPortalUrl() {
        return URL.getOrgDomainUrl().toExternalForm() + '/grants/';
    }
}
