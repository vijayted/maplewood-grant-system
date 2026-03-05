public without sharing class CustomSelfRegController {
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String email { get; set; }
    public String password { get; set; }
    public String confirmPassword { get; set; }
    public String errorMessage { get; set; }
    public String successMessage { get; set; }

    public CustomSelfRegController() {
        firstName = '';
        lastName = '';
        email = '';
        password = '';
        confirmPassword = '';
        errorMessage = '';
        successMessage = '';
    }

    public PageReference registerUser() {
        errorMessage = '';
        successMessage = '';

        if (String.isBlank(lastName)) {
            errorMessage = 'Last Name is required.';
            return null;
        }
        if (String.isBlank(email)) {
            errorMessage = 'Email is required.';
            return null;
        }
        if (String.isBlank(password)) {
            errorMessage = 'Password is required.';
            return null;
        }
        if (password != confirmPassword) {
            errorMessage = 'Passwords do not match.';
            return null;
        }
        if (password.length() < 8) {
            errorMessage = 'Password must be at least 8 characters.';
            return null;
        }

        try {
            String profileId = null;
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
            if (!profiles.isEmpty()) {
                profileId = profiles[0].Id;
            }

            String nickname = (firstName != null ? firstName : '') + lastName;
            if (nickname.length() > 40) {
                nickname = nickname.substring(0, 40);
            }
            nickname += String.valueOf(Math.abs(Crypto.getRandomInteger())).right(4);

            User u = new User(
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
            );

            String userId = Site.createExternalUser(u, null, password);

            if (userId != null) {
                assignPermissionSet(userId);
                String baseUrl = Site.getBaseSecureUrl();
                String loginUrl = baseUrl.replace('/grantsvforcesite', '/grants') + '/login';
                PageReference loginPage = new PageReference(loginUrl);
                loginPage.setRedirect(true);
                return loginPage;
            }

            errorMessage = 'Registration failed. Please try again.';
            return null;
        } catch (Site.ExternalUserCreateException ex) {
            String msg = ex.getMessage();
            if (msg.contains('DUPLICATE_USERNAME')) {
                errorMessage = 'An account with this email already exists. Please log in instead.';
            } else if (msg.contains('INVALID_EMAIL_ADDRESS')) {
                errorMessage = 'Please enter a valid email address.';
            } else {
                errorMessage = msg;
            }
            return null;
        } catch (Exception ex) {
            errorMessage = 'Registration error: ' + ex.getMessage();
            return null;
        }
    }

    @future
    private static void assignPermissionSet(String userId) {
        try {
            List<PermissionSet> ps = [SELECT Id FROM PermissionSet WHERE Name = 'Grant_Applicant' LIMIT 1];
            if (!ps.isEmpty()) {
                insert new PermissionSetAssignment(
                    AssigneeId = userId,
                    PermissionSetId = ps[0].Id
                );
            }
        } catch (Exception e) {
            System.debug('Permission set assignment error: ' + e.getMessage());
        }
    }
}
