import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getApplicationById from '@salesforce/apex/GrantApplicationController.getApplicationById';
import getApplicationFiles from '@salesforce/apex/GrantApplicationController.getApplicationFiles';
import updateStatus from '@salesforce/apex/GrantApplicationController.updateStatus';
import calculateAward from '@salesforce/apex/GrantAwardService.calculateAward';
import approveApplication from '@salesforce/apex/GrantAwardService.approveApplication';

const STATUS_BADGE_MAP = {
    'Submitted': 'slds-badge badge-submitted',
    'Under Review': 'slds-badge badge-underreview',
    'Approved': 'slds-badge badge-approved',
    'Rejected': 'slds-badge badge-rejected'
};

export default class ReviewerApplicationDetail extends NavigationMixin(LightningElement) {
    @api recordId;

    application;
    files = [];
    eligibilityRules = [];
    awardBreakdownData;
    rejectComments = '';

    error;
    isLoading = true;
    wiredApplicationResult;
    wiredFilesResult;

    showApproveModal = false;
    showRejectModal = false;
    isProcessing = false;

    @wire(getApplicationById, { applicationId: '$recordId' })
    wiredApplication(result) {
        this.wiredApplicationResult = result;
        const { error, data } = result;
        this.isLoading = false;
        if (data) {
            this.application = data;
            this.error = undefined;
            this.parseEligibilityResults();
        } else if (error) {
            this.error = error.body?.message || 'Failed to load application.';
            this.application = undefined;
        }
    }

    @wire(getApplicationFiles, { applicationId: '$recordId' })
    wiredFiles(result) {
        this.wiredFilesResult = result;
        const { error, data } = result;
        if (data) {
            this.files = data.map(cdl => ({
                id: cdl.Id,
                title: cdl.ContentDocument.Title,
                fileType: cdl.ContentDocument.FileType,
                size: this.formatFileSize(cdl.ContentDocument.ContentSize),
                versionId: cdl.ContentDocument.LatestPublishedVersionId,
                documentId: cdl.ContentDocumentId
            }));
        } else if (error) {
            this.files = [];
        }
    }

    parseEligibilityResults() {
        if (!this.application?.Eligibility_Results__c) {
            this.eligibilityRules = [];
            return;
        }
        try {
            const results = JSON.parse(this.application.Eligibility_Results__c);
            this.eligibilityRules = (results.rules || results).map((rule, idx) => ({
                ...rule,
                key: rule.ruleNumber || rule.ruleId || `rule-${idx}`,
                iconName: rule.passed ? 'utility:check' : 'utility:close',
                iconVariant: rule.passed ? 'success' : 'error',
                rowClass: rule.passed ? 'rule-pass' : 'rule-fail'
            }));
        } catch (e) {
            this.eligibilityRules = [];
        }
    }

    // Computed properties
    get hasApplication() {
        return this.application != null;
    }

    get appName() {
        return this.application?.Name || '';
    }

    get statusBadgeClass() {
        return STATUS_BADGE_MAP[this.application?.Status__c] || 'slds-badge';
    }

    get isSubmitted() {
        return this.application?.Status__c === 'Submitted';
    }

    get isUnderReview() {
        return this.application?.Status__c === 'Under Review';
    }

    get isApproved() {
        return this.application?.Status__c === 'Approved';
    }

    get isRejected() {
        return this.application?.Status__c === 'Rejected';
    }

    get canMarkUnderReview() {
        return this.isSubmitted;
    }

    get canApprove() {
        return this.isSubmitted || this.isUnderReview;
    }

    get canReject() {
        return this.isSubmitted || this.isUnderReview;
    }

    get showActionButtons() {
        return this.canMarkUnderReview || this.canApprove || this.canReject;
    }

    get eligibilityLabel() {
        return this.application?.Is_Eligible__c ? 'Eligible' : 'Not Eligible';
    }

    get eligibilityIconName() {
        return this.application?.Is_Eligible__c ? 'utility:check' : 'utility:warning';
    }

    get eligibilityIconVariant() {
        return this.application?.Is_Eligible__c ? 'success' : 'warning';
    }

    get eligibilityScoreLabel() {
        return `${this.application?.Eligibility_Score__c || 0} / 6 rules passed`;
    }

    get hasEligibilityRules() {
        return this.eligibilityRules && this.eligibilityRules.length > 0;
    }

    get hasFiles() {
        return this.files && this.files.length > 0;
    }

    get showAwardSection() {
        return this.isApproved && this.application?.Award_Breakdown__c;
    }

    get showReviewerComments() {
        return this.isRejected && this.application?.Reviewer_Comments__c;
    }

    get submittedDateFormatted() {
        if (!this.application?.CreatedDate) return '';
        return new Date(this.application.CreatedDate).toLocaleDateString('en-US', {
            year: 'numeric', month: 'short', day: 'numeric'
        });
    }

    get submittedByName() {
        return this.application?.CreatedBy?.Name || 'Unknown';
    }

    get reviewedDateFormatted() {
        if (!this.application?.Reviewed_Date__c) return '';
        return new Date(this.application.Reviewed_Date__c).toLocaleString();
    }

    get reviewerName() {
        return this.application?.Reviewer__r?.Name || 'Unknown';
    }

    get previouslyFundedLabel() {
        return this.application?.Previously_Funded__c ? 'Yes' : 'No';
    }

    get formattedAmountRequested() {
        return this.formatCurrency(this.application?.Amount_Requested__c);
    }

    get formattedTotalProjectCost() {
        return this.formatCurrency(this.application?.Total_Project_Cost__c);
    }

    get formattedAnnualBudget() {
        return this.formatCurrency(this.application?.Annual_Budget__c);
    }

    get formattedAwardAmount() {
        return this.formatCurrency(this.application?.Award_Amount__c);
    }

    get rejectCommentsValid() {
        return this.rejectComments && this.rejectComments.trim().length > 0;
    }

    // Action handlers
    async handleMarkUnderReview() {
        this.isProcessing = true;
        try {
            await updateStatus({ applicationId: this.recordId, newStatus: 'Under Review', comments: null });
            this.showToast('Success', 'Application marked as Under Review.', 'success');
            await refreshApex(this.wiredApplicationResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to update status.', 'error');
        } finally {
            this.isProcessing = false;
        }
    }

    async handleApproveClick() {
        this.isProcessing = true;
        try {
            const result = await calculateAward({ applicationId: this.recordId });
            this.awardBreakdownData = result;
            this.showApproveModal = true;
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to calculate award.', 'error');
        } finally {
            this.isProcessing = false;
        }
    }

    async handleConfirmApprove() {
        this.isProcessing = true;
        try {
            const awardJson = this.awardBreakdownData
                ? JSON.stringify(this.awardBreakdownData)
                : null;
            await approveApplication({
                applicationId: this.recordId,
                awardResultJson: awardJson
            });
            this.showApproveModal = false;
            this.showToast('Success', 'Application approved and award calculated.', 'success');
            await refreshApex(this.wiredApplicationResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to approve application.', 'error');
        } finally {
            this.isProcessing = false;
        }
    }

    handleRejectClick() {
        this.rejectComments = '';
        this.showRejectModal = true;
    }

    handleRejectCommentsChange(event) {
        this.rejectComments = event.detail.value;
    }

    async handleConfirmReject() {
        if (!this.rejectCommentsValid) {
            this.showToast('Error', 'Please provide rejection comments.', 'error');
            return;
        }

        this.isProcessing = true;
        try {
            await updateStatus({
                applicationId: this.recordId,
                newStatus: 'Rejected',
                comments: this.rejectComments.trim()
            });
            this.showRejectModal = false;
            this.showToast('Success', 'Application has been rejected.', 'success');
            await refreshApex(this.wiredApplicationResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to reject application.', 'error');
        } finally {
            this.isProcessing = false;
        }
    }

    handleCancelModal() {
        this.showApproveModal = false;
        this.showRejectModal = false;
        this.awardBreakdownData = null;
        this.rejectComments = '';
    }

    handleFilePreview(event) {
        const versionId = event.currentTarget.dataset.versionid;
        if (versionId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: versionId
                }
            });
        }
    }

    // Utility
    formatCurrency(value) {
        if (value == null) return '$0';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 2
        }).format(value);
    }

    formatFileSize(bytes) {
        if (!bytes) return '0 B';
        const units = ['B', 'KB', 'MB', 'GB'];
        let i = 0;
        let size = bytes;
        while (size >= 1024 && i < units.length - 1) {
            size /= 1024;
            i++;
        }
        return `${size.toFixed(1)} ${units[i]}`;
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
