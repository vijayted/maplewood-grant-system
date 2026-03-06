import { LightningElement } from 'lwc';

export default class LoginBranding extends LightningElement {
    connectedCallback() {
        const startUrl = new URLSearchParams(window.location.search).get('startURL') || '/';
        const baseUrl = window.location.origin;
        window.location.href = baseUrl + '/grantsvforcesite/apex/CustomStaffLogin?startURL=' + encodeURIComponent(startUrl);
    }
}
