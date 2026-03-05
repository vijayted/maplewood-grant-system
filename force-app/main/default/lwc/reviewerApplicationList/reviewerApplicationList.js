import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllApplications from '@salesforce/apex/GrantApplicationController.getAllApplications';
import getApplicationSummary from '@salesforce/apex/GrantApplicationController.getApplicationSummary';

const COLUMNS = [
    {
        label: 'Application',
        fieldName: 'recordUrl',
        type: 'url',
        sortable: true,
        typeAttributes: { label: { fieldName: 'Name' }, target: '_self' }
    },
    { label: 'Organization', fieldName: 'Organization_Name__c', type: 'text', sortable: true },
    { label: 'Project Title', fieldName: 'Project_Title__c', type: 'text', sortable: true },
    {
        label: 'Date Submitted',
        fieldName: 'CreatedDate',
        type: 'date',
        sortable: true,
        typeAttributes: { month: '2-digit', day: '2-digit', year: 'numeric' }
    },
    {
        label: 'Eligibility',
        fieldName: 'eligibilityLabel',
        type: 'text',
        cellAttributes: { class: { fieldName: 'eligibilityClass' } }
    },
    {
        label: 'Status',
        fieldName: 'Status__c',
        type: 'text',
        sortable: true,
        cellAttributes: { class: { fieldName: 'statusClass' } }
    },
    {
        label: 'Amount Requested',
        fieldName: 'Amount_Requested__c',
        type: 'currency',
        sortable: true,
        typeAttributes: { currencyCode: 'USD' }
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [{ label: 'View', name: 'view' }]
        }
    }
];

const STATUS_CLASS_MAP = {
    'Submitted': 'status-submitted',
    'Under Review': 'status-underreview',
    'Approved': 'status-approved',
    'Rejected': 'status-rejected'
};

const STATUS_OPTIONS = [
    { label: 'All Statuses', value: 'all' },
    { label: 'Submitted', value: 'Submitted' },
    { label: 'Under Review', value: 'Under Review' },
    { label: 'Approved', value: 'Approved' },
    { label: 'Rejected', value: 'Rejected' }
];

const ELIGIBILITY_OPTIONS = [
    { label: 'All Eligibility', value: 'all' },
    { label: 'Eligible', value: 'eligible' },
    { label: 'Not Eligible', value: 'notEligible' }
];

export default class ReviewerApplicationList extends NavigationMixin(LightningElement) {
    columns = COLUMNS;
    statusOptions = STATUS_OPTIONS;
    eligibilityOptions = ELIGIBILITY_OPTIONS;

    statusFilter = 'all';
    eligibilityFilter = 'all';

    allApplications = [];
    filteredApplications = [];
    error;
    isLoading = true;

    summary = {};
    summaryError;

    _wiredSummaryResult;
    _wiredAppsResult;
    _subscription = null;
    _channelName = '/event/Grant_Application_Event__e';

    connectedCallback() {
        this._subscribeToPlatformEvent();
    }

    disconnectedCallback() {
        this._unsubscribeFromPlatformEvent();
    }

    _subscribeToPlatformEvent() {
        const messageCallback = (response) => {
            const payload = response.data?.payload;
            const appName = payload?.Application_Name__c || 'An application';
            const newStatus = payload?.New_Status__c || '';

            this.dispatchEvent(new ShowToastEvent({
                title: 'Application Updated',
                message: `${appName} status changed to ${newStatus}`,
                variant: 'info'
            }));

            refreshApex(this._wiredAppsResult);
            refreshApex(this._wiredSummaryResult);
        };

        subscribe(this._channelName, -1, messageCallback).then(response => {
            this._subscription = response;
        });

        onError(error => {
            console.error('EmpApi error: ', error);
        });
    }

    _unsubscribeFromPlatformEvent() {
        if (this._subscription) {
            unsubscribe(this._subscription);
            this._subscription = null;
        }
    }

    @wire(getApplicationSummary)
    wiredSummary(result) {
        this._wiredSummaryResult = result;
        const { error, data } = result;
        if (data) {
            this.summary = data;
            this.summaryError = undefined;
        } else if (error) {
            this.summaryError = error.body?.message || 'Failed to load summary.';
            this.summary = {};
        }
    }

    @wire(getAllApplications)
    wiredApplications(result) {
        this._wiredAppsResult = result;
        const { error, data } = result;
        this.isLoading = false;
        if (data) {
            this.allApplications = data.map(app => ({
                ...app,
                recordUrl: `/lightning/r/Grant_Application__c/${app.Id}/view`,
                eligibilityLabel: app.Is_Eligible__c ? 'Eligible' : 'Not Eligible',
                eligibilityClass: app.Is_Eligible__c ? 'eligibility-pass' : 'eligibility-fail',
                statusClass: STATUS_CLASS_MAP[app.Status__c] || ''
            }));
            this.error = undefined;
            this.applyFilters();
        } else if (error) {
            this.error = error.body?.message || 'An error occurred while loading applications.';
            this.allApplications = [];
            this.filteredApplications = [];
        }
    }

    get submittedCount() {
        return this.summary.submitted || 0;
    }

    get underReviewCount() {
        return this.summary.underReview || 0;
    }

    get approvedCount() {
        return this.summary.approved || 0;
    }

    get rejectedCount() {
        return this.summary.rejected || 0;
    }

    get totalAwarded() {
        return this._formatCurrency(this.summary.totalAwarded || 0);
    }

    get totalBudget() {
        return this._formatCurrency(this.summary.totalBudget || 2000000);
    }

    get fundsRemaining() {
        return this._formatCurrency(this.summary.fundsRemaining || 0);
    }

    get pendingRequested() {
        return this._formatCurrency(this.summary.pendingRequested || 0);
    }

    get utilizationPct() {
        return this.summary.utilizationPct || 0;
    }

    get progressBarStyle() {
        const pct = Math.min(this.utilizationPct, 100);
        let color = '#1a652a';
        if (pct > 80) color = '#c23934';
        else if (pct > 60) color = '#ff9a3c';
        return `width:${pct}%;background-color:${color}`;
    }

    _formatCurrency(amount) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    }

    get hasApplications() {
        return this.filteredApplications && this.filteredApplications.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.error && !this.hasApplications;
    }

    get emptyMessage() {
        if (this.statusFilter !== 'all' || this.eligibilityFilter !== 'all') {
            return 'No applications match the selected filters.';
        }
        return 'No applications have been submitted yet.';
    }

    get filteredCount() {
        return this.filteredApplications ? this.filteredApplications.length : 0;
    }

    handleStatusChange(event) {
        this.statusFilter = event.detail.value;
        this.applyFilters();
    }

    handleEligibilityChange(event) {
        this.eligibilityFilter = event.detail.value;
        this.applyFilters();
    }

    applyFilters() {
        let result = [...this.allApplications];

        if (this.statusFilter !== 'all') {
            result = result.filter(app => app.Status__c === this.statusFilter);
        }

        if (this.eligibilityFilter === 'eligible') {
            result = result.filter(app => app.Is_Eligible__c === true);
        } else if (this.eligibilityFilter === 'notEligible') {
            result = result.filter(app => app.Is_Eligible__c !== true);
        }

        this.filteredApplications = result;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: 'Grant_Application__c',
                    actionName: 'view'
                }
            });
        }
    }
}
