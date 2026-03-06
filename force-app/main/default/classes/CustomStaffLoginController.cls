public without sharing class CustomStaffLoginController {
    public String username { get; set; }
    public String password { get; set; }
    public String errorMessage { get; set; }

    public CustomStaffLoginController() {
        this.username = '';
        this.password = '';
        this.errorMessage = '';
    }

    public PageReference login() {
        errorMessage = '';

        if (String.isBlank(username)) {
            errorMessage = 'Please enter your email address.';
            return null;
        }
        if (String.isBlank(password)) {
            errorMessage = 'Please enter your password.';
            return null;
        }

        try {
            String startUrl = System.currentPageReference().getParameters().get('startURL');
            if (String.isBlank(startUrl)) {
                startUrl = '/';
            }
            PageReference result = Site.login(username, password, startUrl);
            if (result != null) {
                return result;
            }
            errorMessage = 'Invalid email or password. Please check your credentials and try again.';
            return null;
        } catch (Exception ex) {
            errorMessage = 'An error occurred during login. Please try again.';
            return null;
        }
    }

    @AuraEnabled
    public static String doLogin(String username, String password, String startUrl) {
        if (String.isBlank(startUrl)) {
            startUrl = '/grants/';
        }
        try {
            PageReference result = Site.login(username, password, startUrl);
            if (result != null) {
                return result.getUrl();
            }
            return 'ERROR:Invalid email or password. Please check your credentials and try again.';
        } catch (Exception ex) {
            return 'ERROR:An error occurred during login. Please try again.';
        }
    }

    public PageReference forgotPassword() {
        String baseUrl = Site.getBaseSecureUrl();
        return new PageReference(baseUrl + '/ForgotPassword');
    }

    public PageReference goToRegister() {
        String baseUrl = Site.getBaseSecureUrl();
        return new PageReference(baseUrl + '/apex/CustomSelfRegister');
    }
}
