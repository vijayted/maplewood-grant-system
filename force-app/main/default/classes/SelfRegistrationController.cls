public without sharing class SelfRegistrationController {
    @AuraEnabled
    public static String registerUser(String firstName, String lastName, String email, String password) {
        if (String.isBlank(lastName)) {
            throw new AuraHandledException('Last Name is required.');
        }
        if (String.isBlank(email)) {
            throw new AuraHandledException('Email is required.');
        }
        if (String.isBlank(password)) {
            throw new AuraHandledException('Password is required.');
        }

        try {
            String profileId = null;
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
            if (!profiles.isEmpty()) {
                profileId = profiles[0].Id;
            }

            String accountId = null;
            List<Account> accts = [SELECT Id FROM Account LIMIT 1];
            if (!accts.isEmpty()) {
                accountId = accts[0].Id;
            }

            String nickname = firstName != null ? firstName : '';
            nickname += lastName;
            if (nickname.length() > 40) {
                nickname = nickname.substring(0, 40);
            }
            nickname += String.valueOf(Crypto.getRandomInteger()).right(4);

            Id userId = Site.createExternalUser(
                new User(
                    FirstName = firstName,
                    LastName = lastName,
                    Email = email,
                    Username = email,
                    CommunityNickname = nickname,
                    ProfileId = profileId,
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US'
                ),
                accountId,
                password
            );

            if (userId != null) {
                String siteUrl = Site.getBaseUrl();
                String loginUrl = siteUrl + '/login?un=' + EncodingUtil.urlEncode(email, 'UTF-8');
                return loginUrl;
            }
            throw new AuraHandledException('Registration failed. Please try again.');
        } catch (Site.ExternalUserCreateException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AuraHandledException('Registration error: ' + ex.getMessage());
        }
    }
}
