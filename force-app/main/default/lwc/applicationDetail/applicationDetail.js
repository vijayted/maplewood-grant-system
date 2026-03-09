import { LightningElement, api, track } from 'lwc';
import getApplicationById from '@salesforce/apex/GrantApplicationController.getApplicationById';
import getApplicationFiles from '@salesforce/apex/GrantApplicationController.getApplicationFiles';

const STATUS_CONFIG = {
    Submitted:      { class: 'status-badge status-submitted',    label: 'Submitted' },
    'Under Review': { class: 'status-badge status-underreview',  label: 'Under Review' },
    Approved:       { class: 'status-badge status-approved',     label: 'Approved' },
    Rejected:       { class: 'status-badge status-rejected',     label: 'Rejected' }
};

export default class ApplicationDetail extends LightningElement {
    _recordId;
    @track application = {};
    @track eligibilityResults = [];
    @track awardBreakdown = {};
    @track files = [];
    isLoading = true;
    error;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadApplication();
            this.loadFiles();
        }
    }

    loadApplication() {
        this.isLoading = true;
        getApplicationById({ applicationId: this._recordId })
            .then(data => {
                this.application = data;
                this.parseEligibilityResults(data.Eligibility_Results__c);
                this.parseAwardBreakdown(data.Award_Breakdown__c);
                this.error = undefined;
            })
            .catch(error => {
                this.error = this.reduceError(error);
                this.application = {};
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadFiles() {
        getApplicationFiles({ applicationId: this._recordId })
            .then(data => {
                this.files = data.map(link => ({
                    id: link.ContentDocumentId,
                    title: link.ContentDocument.Title,
                    fileType: link.ContentDocument.FileType,
                    size: this.formatFileSize(link.ContentDocument.ContentSize),
                    versionId: link.ContentDocument.LatestPublishedVersionId
                }));
            })
            .catch(() => {
                this.files = [];
            });
    }

    parseEligibilityResults(jsonString) {
        if (!jsonString) {
            this.eligibilityResults = [];
            return;
        }
        try {
            const parsed = JSON.parse(jsonString);
            this.eligibilityResults = (parsed.results || parsed).map(rule => ({
                ...rule,
                iconName: rule.passed ? 'utility:check' : 'utility:close',
                iconClass: rule.passed ? 'eligibility-pass' : 'eligibility-fail',
                iconAlt: rule.passed ? 'Passed' : 'Failed'
            }));
        } catch (e) {
            this.eligibilityResults = [];
        }
    }

    parseAwardBreakdown(jsonString) {
        if (!jsonString) {
            this.awardBreakdown = {};
            return;
        }
        try {
            const parsed = JSON.parse(jsonString);
            if (parsed.factors) {
                parsed.factors = parsed.factors.map(f => ({
                    ...f,
                    key: f.factorName
                }));
            }
            this.awardBreakdown = parsed;
        } catch (e) {
            this.awardBreakdown = {};
        }
    }

    get applicationName() {
        return this.application.Name || '';
    }

    get status() {
        return this.application.Status__c || '';
    }

    get statusBadgeClass() {
        const config = STATUS_CONFIG[this.status];
        return config ? config.class : 'status-badge';
    }

    get statusLabel() {
        const config = STATUS_CONFIG[this.status];
        return config ? config.label : this.status;
    }

    get isApproved() {
        return this.status === 'Approved';
    }

    get isRejected() {
        return this.status === 'Rejected';
    }

    get formattedCreatedDate() {
        if (!this.application.CreatedDate) return '';
        return new Date(this.application.CreatedDate).toLocaleDateString('en-US', {
            year: 'numeric', month: 'long', day: 'numeric'
        });
    }

    get formattedReviewedDate() {
        if (!this.application.Reviewed_Date__c) return '';
        return new Date(this.application.Reviewed_Date__c).toLocaleDateString('en-US', {
            year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit'
        });
    }

    get formattedAwardAmount() {
        if (this.application.Award_Amount__c == null) return '$0';
        return new Intl.NumberFormat('en-US', {
            style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0
        }).format(this.application.Award_Amount__c);
    }

    get formattedAmountRequested() {
        if (this.application.Amount_Requested__c == null) return '';
        return new Intl.NumberFormat('en-US', {
            style: 'currency', currency: 'USD', minimumFractionDigits: 0
        }).format(this.application.Amount_Requested__c);
    }

    get formattedTotalProjectCost() {
        if (this.application.Total_Project_Cost__c == null) return '';
        return new Intl.NumberFormat('en-US', {
            style: 'currency', currency: 'USD', minimumFractionDigits: 0
        }).format(this.application.Total_Project_Cost__c);
    }

    get formattedAnnualBudget() {
        if (this.application.Annual_Budget__c == null) return '';
        return new Intl.NumberFormat('en-US', {
            style: 'currency', currency: 'USD', minimumFractionDigits: 0
        }).format(this.application.Annual_Budget__c);
    }

    get formattedProjectStartDate() {
        if (!this.application.Project_Start_Date__c) return '';
        return new Date(this.application.Project_Start_Date__c + 'T00:00:00').toLocaleDateString('en-US', {
            year: 'numeric', month: 'long', day: 'numeric'
        });
    }

    get formattedProjectEndDate() {
        if (!this.application.Project_End_Date__c) return '';
        return new Date(this.application.Project_End_Date__c + 'T00:00:00').toLocaleDateString('en-US', {
            year: 'numeric', month: 'long', day: 'numeric'
        });
    }

    get previouslyFundedLabel() {
        return this.application.Previously_Funded__c ? 'Yes' : 'No';
    }

    get hasEligibilityResults() {
        return this.eligibilityResults && this.eligibilityResults.length > 0;
    }

    get eligibilityScoreLabel() {
        const score = this.application.Eligibility_Score__c;
        if (score == null) return '';
        return `${score} of 6 rules passed`;
    }

    get eligibilityStatusIcon() {
        return this.application.Is_Eligible__c ? 'utility:check' : 'utility:warning';
    }

    get eligibilityStatusClass() {
        return this.application.Is_Eligible__c ? 'eligibility-pass' : 'eligibility-fail';
    }

    get eligibilityStatusLabel() {
        return this.application.Is_Eligible__c ? 'Fully Eligible' : 'Not Fully Eligible';
    }

    get hasAwardBreakdown() {
        return this.awardBreakdown && this.awardBreakdown.factors && this.awardBreakdown.factors.length > 0;
    }

    get awardFactors() {
        return this.awardBreakdown.factors || [];
    }

    get awardPercentageLabel() {
        if (this.awardBreakdown.awardPercentage != null) {
            return `${Math.round(this.awardBreakdown.awardPercentage * 100)}%`;
        }
        return '';
    }

    get awardTotalScoreLabel() {
        if (this.awardBreakdown.totalScore != null && this.awardBreakdown.maxScore != null) {
            return `${this.awardBreakdown.totalScore} / ${this.awardBreakdown.maxScore}`;
        }
        return '';
    }

    get hasFiles() {
        return this.files && this.files.length > 0;
    }

    get reviewerComments() {
        return this.application.Reviewer_Comments__c || '';
    }

    get pageTitle() {
        const name = this.applicationName;
        const title = this.application.Project_Title__c;
        if (name && title) return `${name} — ${title}`;
        if (name) return name;
        return 'Application Detail';
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleDownloadFile(event) {
        const versionId = event.currentTarget.dataset.versionId;
        window.open(`/sfc/servlet.shepherd/version/download/${versionId}`, '_blank');
    }

    formatFileSize(bytes) {
        if (bytes == null || bytes === 0) return '0 B';
        const units = ['B', 'KB', 'MB', 'GB'];
        let i = 0;
        let size = bytes;
        while (size >= 1024 && i < units.length - 1) {
            size /= 1024;
            i++;
        }
        return `${size.toFixed(i === 0 ? 0 : 1)} ${units[i]}`;
    }

    reduceError(error) {
        if (typeof error === 'string') return error;
        if (error.body) {
            if (typeof error.body.message === 'string') return error.body.message;
            if (Array.isArray(error.body)) return error.body.map(e => e.message).join(', ');
        }
        if (error.message) return error.message;
        return 'An unknown error occurred.';
    }
}
