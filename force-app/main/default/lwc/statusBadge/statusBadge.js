import { LightningElement, api } from 'lwc';

const STATUS_CONFIG = {
    'Submitted': { cssClass: 'badge badge-submitted', iconName: 'utility:email', label: 'Submitted' },
    'Under Review': { cssClass: 'badge badge-underreview', iconName: 'utility:preview', label: 'Under Review' },
    'Approved': { cssClass: 'badge badge-approved', iconName: 'utility:check', label: 'Approved' },
    'Rejected': { cssClass: 'badge badge-rejected', iconName: 'utility:close', label: 'Rejected' }
};

const DEFAULT_CONFIG = { cssClass: 'badge badge-default', iconName: 'utility:question', label: 'Unknown' };

export default class StatusBadge extends LightningElement {
    @api status;
    @api showIcon = false;

    get config() {
        return STATUS_CONFIG[this.status] || DEFAULT_CONFIG;
    }

    get badgeClass() {
        return this.config.cssClass;
    }

    get iconName() {
        return this.config.iconName;
    }

    get label() {
        return this.config.label;
    }
}
