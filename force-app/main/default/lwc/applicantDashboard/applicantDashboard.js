import { LightningElement, wire } from 'lwc';
import checkIsGuestUser from '@salesforce/apex/GrantApplicationController.checkIsGuestUser';
import getMyApplications from '@salesforce/apex/GrantApplicationController.getMyApplications';

const STATUS_CLASS_MAP = {
    'Submitted': 'status-submitted',
    'Under Review': 'status-underreview',
    'Approved': 'status-approved',
    'Rejected': 'status-rejected'
};

const COLUMNS = [
    { label: 'Application ID', fieldName: 'Name', type: 'text' },
    { label: 'Project Title', fieldName: 'Project_Title__c', type: 'text' },
    {
        label: 'Date Submitted',
        fieldName: 'CreatedDate',
        type: 'date',
        typeAttributes: { month: '2-digit', day: '2-digit', year: 'numeric' }
    },
    {
        label: 'Status',
        fieldName: 'Status__c',
        type: 'text',
        cellAttributes: { class: { fieldName: 'statusClass' } }
    },
    { label: 'Award Amount', fieldName: 'Award_Amount__c', type: 'currency' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [{ label: 'View Details', name: 'view' }]
        }
    }
];

export default class ApplicantDashboard extends LightningElement {
    applications;
    error;
    isLoading = true;
    columns = COLUMNS;
    currentView = 'dashboard';
    selectedRecordId;
    _isGuest = true;
    _guestCheckDone = false;

    @wire(checkIsGuestUser)
    wiredGuestCheck({ data, error }) {
        if (data !== undefined) {
            this._isGuest = data;
            this._guestCheckDone = true;
            if (!data) {
                this.loadApplications();
            } else {
                this.isLoading = false;
            }
        } else if (error) {
            this._isGuest = true;
            this._guestCheckDone = true;
            this.isLoading = false;
        }
    }

    get isLoggedIn() {
        return this._guestCheckDone && !this._isGuest;
    }

    get isGuest() {
        return this._guestCheckDone && this._isGuest;
    }

    get showDashboard() {
        return this.currentView === 'dashboard';
    }

    get showForm() {
        return this.currentView === 'form';
    }

    get showDetail() {
        return this.currentView === 'detail';
    }

    loadApplications() {
        this.isLoading = true;
        getMyApplications()
            .then(data => {
                this.applications = data.map(app => ({
                    ...app,
                    statusClass: STATUS_CLASS_MAP[app.Status__c] || ''
                }));
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body?.message || 'An error occurred while loading your applications.';
                this.applications = undefined;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get hasApplications() {
        return !this.isLoading && !this.error && this.applications && this.applications.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.error && (!this.applications || this.applications.length === 0);
    }

    handleNewApplication() {
        this.currentView = 'form';
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'view') {
            this.selectedRecordId = row.Id;
            this.currentView = 'detail';
        }
    }

    handleLogout() {
        window.location.href = '/grants/secur/logout.jsp';
    }

    handleFormComplete() {
        this.currentView = 'dashboard';
        this.loadApplications();
    }

    handleBackToDashboard() {
        this.currentView = 'dashboard';
        this.loadApplications();
    }
}
