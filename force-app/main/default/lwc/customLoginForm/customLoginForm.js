import { LightningElement, track } from 'lwc';
import doLogin from '@salesforce/apex/CustomStaffLoginController.doLogin';

export default class CustomLoginForm extends LightningElement {
    @track email = '';
    @track password = '';
    @track errorMessage = '';
    @track isLoading = false;

    get startUrl() {
        const params = new URLSearchParams(window.location.search);
        return params.get('startURL') || '/grants/';
    }

    handleEmailChange(event) {
        this.email = event.target.value;
        this.errorMessage = '';
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
        this.errorMessage = '';
    }

    handleKeyDown(event) {
        if (event.key === 'Enter') {
            this.handleLogin();
        }
    }

    handleLogin() {
        if (!this.email) {
            this.errorMessage = 'Please enter your email address.';
            return;
        }
        if (!this.password) {
            this.errorMessage = 'Please enter your password.';
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        doLogin({ username: this.email, password: this.password, startUrl: this.startUrl })
            .then(result => {
                if (result && result.startsWith('ERROR:')) {
                    this.errorMessage = result.substring(6);
                    this.isLoading = false;
                } else if (result) {
                    window.location.href = result;
                } else {
                    this.errorMessage = 'Invalid email or password.';
                    this.isLoading = false;
                }
            })
            .catch(error => {
                this.errorMessage = error.body ? error.body.message : 'An unexpected error occurred.';
                this.isLoading = false;
            });
    }
}
