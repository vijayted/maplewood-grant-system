import { LightningElement } from 'lwc';

export default class CustomSelfRegister extends LightningElement {
    connectedCallback() {
        const host = window.location.origin;
        window.location.href = host + '/grantsvforcesite/CustomSelfRegister';
    }
}
