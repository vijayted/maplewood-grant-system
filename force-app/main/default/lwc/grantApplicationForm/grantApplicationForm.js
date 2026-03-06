import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkEligibility from '@salesforce/apex/GrantEligibilityService.checkEligibility';
import createApplication from '@salesforce/apex/GrantApplicationController.createApplication';
import uploadFile from '@salesforce/apex/GrantApplicationController.uploadFile';

const DEBOUNCE_DELAY = 300;
const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024;

export default class GrantApplicationForm extends LightningElement {

    currentStep = 'section1';

    // Section 1 fields
    organizationName = '';
    ein = '';
    organizationType = '';
    yearFounded = null;
    annualBudget = null;
    numEmployees = null;
    contactName = '';
    contactEmail = '';
    contactPhone = '';
    organizationAddress = '';
    missionStatement = '';

    // Section 2 fields
    projectTitle = '';
    projectCategory = '';
    projectDescription = '';
    targetPopulation = '';
    numBeneficiaries = null;
    totalProjectCost = null;
    amountRequested = null;
    projectStartDate = '';
    projectEndDate = '';
    previouslyFunded = false;

    // File upload state
    uploadedFileName = '';
    uploadedFileData = '';
    uploadedFileType = '';

    // Eligibility & loading state
    eligibilityRules = [];
    isLoading = false;
    screenReaderMessage = '';

    // Internal
    _debounceTimer;
    _recordId;

    disconnectedCallback() {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
    }

    // -- Picklist options --

    organizationTypeOptions = [
        { label: '501(c)(3)', value: '501(c)(3)' },
        { label: '501(c)(4)', value: '501(c)(4)' },
        { label: 'Community-Based Organization', value: 'Community-Based Organization' },
        { label: 'Faith-Based Organization', value: 'Faith-Based Organization' },
        { label: 'For-Profit Business', value: 'For-Profit Business' },
        { label: 'Government Agency', value: 'Government Agency' },
        { label: 'Individual', value: 'Individual' }
    ];

    projectCategoryOptions = [
        { label: 'Youth Programs', value: 'Youth Programs' },
        { label: 'Senior Services', value: 'Senior Services' },
        { label: 'Public Health', value: 'Public Health' },
        { label: 'Neighborhood Safety', value: 'Neighborhood Safety' },
        { label: 'Arts & Culture', value: 'Arts & Culture' },
        { label: 'Workforce Development', value: 'Workforce Development' },
        { label: 'Other', value: 'Other' }
    ];

    // -- Computed properties --

    get currentYear() {
        return new Date().getFullYear();
    }

    get isSection1() {
        return this.currentStep === 'section1';
    }

    get isSection2() {
        return this.currentStep === 'section2';
    }

    get isReview() {
        return this.currentStep === 'review';
    }

    get step1Class() {
        if (this.isSection1) return 'step-item step-active';
        return 'step-item step-completed';
    }

    get step2Class() {
        if (this.isSection2) return 'step-item step-active';
        if (this.isReview) return 'step-item step-completed';
        return 'step-item step-upcoming';
    }

    get step3Class() {
        if (this.isReview) return 'step-item step-active';
        return 'step-item step-upcoming';
    }

    get connector1Class() {
        return this.isSection1 ? 'connector-line' : 'connector-line connector-filled';
    }

    get connector2Class() {
        return this.isReview ? 'connector-line connector-filled' : 'connector-line';
    }

    get hasEligibilityRules() {
        return this.eligibilityRules && this.eligibilityRules.length > 0;
    }

    get noEligibilityRules() {
        return !this.eligibilityRules || this.eligibilityRules.length === 0;
    }

    get eligibilitySummary() {
        if (!this.eligibilityRules || this.eligibilityRules.length === 0) {
            return '0 of 6 rules passing';
        }
        const passing = this.eligibilityRules.filter(r => r.evaluated && r.passed).length;
        return `${passing} of 6 rules passing`;
    }

    get isFullyEligible() {
        if (!this.eligibilityRules || this.eligibilityRules.length === 0) return false;
        return this.eligibilityRules.every(r => r.evaluated && r.passed);
    }

    get isPartiallyEligible() {
        if (!this.eligibilityRules || this.eligibilityRules.length === 0) return false;
        const evaluated = this.eligibilityRules.filter(r => r.evaluated);
        return evaluated.length > 0 && !this.isFullyEligible;
    }

    get showEligibilityWarning() {
        return this.hasEligibilityRules && !this.isFullyEligible;
    }

    get previouslyFundedLabel() {
        return this.previouslyFunded ? 'Yes' : 'No';
    }

    get formattedAnnualBudget() {
        return this._formatCurrency(this.annualBudget);
    }

    get formattedTotalProjectCost() {
        return this._formatCurrency(this.totalProjectCost);
    }

    get formattedAmountRequested() {
        return this._formatCurrency(this.amountRequested);
    }

    // -- Event handlers --

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        if (!field) return;

        if (field === 'previouslyFunded') {
            this[field] = event.target.checked;
        } else {
            const value = event.detail ? event.detail.value : event.target.value;
            this[field] = value;
        }

        this._debouncedEligibilityCheck();
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) {
            this.uploadedFileName = '';
            this.uploadedFileData = '';
            this.uploadedFileType = '';
            return;
        }

        if (file.size > MAX_FILE_SIZE_BYTES) {
            this._showToast('File Too Large', 'Maximum file size is 5 MB. Please choose a smaller file.', 'error');
            event.target.value = '';
            this.uploadedFileName = '';
            this.uploadedFileData = '';
            this.uploadedFileType = '';
            return;
        }

        const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
        if (!allowedTypes.includes(file.type)) {
            this._showToast('Invalid File Type', 'Only PDF, JPG, and PNG files are accepted.', 'error');
            event.target.value = '';
            this.uploadedFileName = '';
            this.uploadedFileData = '';
            this.uploadedFileType = '';
            return;
        }

        this.uploadedFileName = file.name;
        this.uploadedFileType = file.type;

        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            this.uploadedFileData = base64;
        };
        reader.onerror = () => {
            this._showToast('File Read Error', 'Could not read the file. Please try again.', 'error');
            this.uploadedFileName = '';
            this.uploadedFileData = '';
        };
        reader.readAsDataURL(file);
    }

    handleNext() {
        this.errorBanner = '';
        if (!this.validateSection1()) return;
        this.currentStep = 'section2';
        this._scrollToTop();
    }

    handleBack() {
        this.errorBanner = '';
        this.currentStep = 'section1';
        this._scrollToTop();
    }

    handleReview() {
        this.errorBanner = '';
        if (!this.validateSection2()) return;
        this.currentStep = 'review';
        this._scrollToTop();
    }

    handleEdit() {
        this.errorBanner = '';
        this.currentStep = 'section1';
        this._scrollToTop();
    }

    async handleSubmit() {
        this.isLoading = true;
        this.screenReaderMessage = 'Submitting your application, please wait...';

        try {
            const appId = await createApplication({
                appData: {
                    organizationName: this.organizationName,
                    ein: this.ein,
                    organizationType: this.organizationType,
                    yearFounded: this.yearFounded ? parseInt(this.yearFounded, 10) : null,
                    annualBudget: this.annualBudget ? parseFloat(this.annualBudget) : null,
                    numEmployees: this.numEmployees ? parseInt(this.numEmployees, 10) : null,
                    contactName: this.contactName,
                    contactEmail: this.contactEmail,
                    contactPhone: this.contactPhone,
                    organizationAddress: this.organizationAddress,
                    missionStatement: this.missionStatement,
                    projectTitle: this.projectTitle,
                    projectCategory: this.projectCategory,
                    projectDescription: this.projectDescription,
                    targetPopulation: this.targetPopulation,
                    numBeneficiaries: this.numBeneficiaries ? parseInt(this.numBeneficiaries, 10) : null,
                    totalProjectCost: this.totalProjectCost ? parseFloat(this.totalProjectCost) : null,
                    amountRequested: this.amountRequested ? parseFloat(this.amountRequested) : null,
                    projectStartDate: this.projectStartDate || null,
                    projectEndDate: this.projectEndDate || null,
                    previouslyFunded: this.previouslyFunded
                }
            });

            this._recordId = appId;

            if (this.uploadedFileData && this.uploadedFileName) {
                await uploadFile({
                    applicationId: appId,
                    fileName: this.uploadedFileName,
                    base64Data: this.uploadedFileData,
                    contentType: this.uploadedFileType
                });
            }

            this.screenReaderMessage = 'Application submitted successfully!';
            this._showToast(
                'Application Submitted',
                'Your grant application has been submitted successfully. You can track its status on your dashboard.',
                'success'
            );

            this.dispatchEvent(new CustomEvent('complete', { detail: { recordId: appId } }));
        } catch (error) {
            // #region agent log - capture full error details
            console.error('[DEBUG-f2ea7e] Full error object:', JSON.stringify(error));
            console.error('[DEBUG-f2ea7e] error.body:', error && error.body ? JSON.stringify(error.body) : 'no body');
            fetch('http://127.0.0.1:7612/ingest/3c3a827d-c306-44e8-ad89-480fc0a14d1e',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'f2ea7e'},body:JSON.stringify({sessionId:'f2ea7e',location:'grantApplicationForm.js:handleSubmit:catch',message:'createApplication error',data:{fullError:JSON.stringify(error),body:error&&error.body?error.body:null,message:error&&error.message?error.message:null},timestamp:Date.now()})}).catch(()=>{});
            // #endregion
            const errorMsg = this._extractErrorMessage(error);
            this.screenReaderMessage = 'Error submitting application: ' + errorMsg;
            this._showToast('Submission Error', errorMsg, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // -- Eligibility --

    _debouncedEligibilityCheck() {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._debounceTimer = setTimeout(() => {
            this._checkEligibilityRules();
        }, DEBOUNCE_DELAY);
    }

    async _checkEligibilityRules() {
        try {
            const result = await checkEligibility({
                organizationType: this.organizationType || null,
                yearFounded: this.yearFounded ? parseInt(this.yearFounded, 10) : null,
                annualBudget: this.annualBudget ? parseFloat(this.annualBudget) : null,
                amountRequested: this.amountRequested ? parseFloat(this.amountRequested) : null,
                totalProjectCost: this.totalProjectCost ? parseFloat(this.totalProjectCost) : null,
                numBeneficiaries: this.numBeneficiaries ? parseInt(this.numBeneficiaries, 10) : null
            });

            this.eligibilityRules = result.rules.map(rule => ({
                ...rule,
                iconName: this._getIconName(rule),
                iconClass: this._getIconClass(rule),
                statusText: this._getStatusText(rule)
            }));

            const passing = result.rulesPassed;
            this.screenReaderMessage = `Eligibility updated: ${passing} of ${result.totalRules} rules passing`;
        } catch (error) {
            // Silently handle eligibility check errors to avoid blocking the user
            console.error('Eligibility check error:', error);
        }
    }

    _getIconName(rule) {
        if (!rule.evaluated) return 'utility:dash';
        return rule.passed ? 'utility:check' : 'utility:close';
    }

    _getIconClass(rule) {
        if (!rule.evaluated) return 'eligibility-neutral';
        return rule.passed ? 'eligibility-pass' : 'eligibility-fail';
    }

    _getStatusText(rule) {
        if (!rule.evaluated) return 'Not yet evaluated';
        return rule.passed ? 'Passing' : 'Failing';
    }

    // -- Validation --

    validateSection1() {
        const inputs = this.template.querySelectorAll(
            'lightning-input[data-field="organizationName"],' +
            'lightning-input[data-field="ein"],' +
            'lightning-combobox[data-field="organizationType"],' +
            'lightning-input[data-field="yearFounded"],' +
            'lightning-input[data-field="annualBudget"],' +
            'lightning-input[data-field="numEmployees"],' +
            'lightning-input[data-field="contactName"],' +
            'lightning-input[data-field="contactEmail"],' +
            'lightning-input[data-field="contactPhone"],' +
            'lightning-textarea[data-field="organizationAddress"],' +
            'lightning-textarea[data-field="missionStatement"]'
        );
        return this._validateInputs(inputs);
    }

    validateSection2() {
        const inputs = this.template.querySelectorAll(
            'lightning-input[data-field="projectTitle"],' +
            'lightning-combobox[data-field="projectCategory"],' +
            'lightning-textarea[data-field="projectDescription"],' +
            'lightning-input[data-field="targetPopulation"],' +
            'lightning-input[data-field="numBeneficiaries"],' +
            'lightning-input[data-field="totalProjectCost"],' +
            'lightning-input[data-field="amountRequested"],' +
            'lightning-input[data-field="projectStartDate"],' +
            'lightning-input[data-field="projectEndDate"]'
        );

        const allValid = this._validateInputs(inputs);

        if (allValid) {
            if (this.projectStartDate && this.projectEndDate) {
                const start = new Date(this.projectStartDate);
                const end = new Date(this.projectEndDate);
                const today = new Date();
                const thirtyDaysFromNow = new Date();
                thirtyDaysFromNow.setDate(today.getDate() + 30);

                if (start < thirtyDaysFromNow) {
                    this._showToast('Validation Error', 'Project start date must be at least 30 days in the future.', 'error');
                    return false;
                }

                if (end <= start) {
                    this._showToast('Validation Error', 'Project end date must be after the start date.', 'error');
                    return false;
                }

                const maxEnd = new Date(start);
                maxEnd.setMonth(maxEnd.getMonth() + 24);
                if (end > maxEnd) {
                    this._showToast('Validation Error', 'Project end date must be within 24 months of the start date.', 'error');
                    return false;
                }
            }
        }

        return allValid;
    }

    _validateInputs(inputs) {
        let allValid = true;
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                allValid = false;
            }
        });
        if (!allValid) {
            this._showToast('Validation Error', 'Please fill in all required fields correctly before proceeding.', 'error');
        }
        return allValid;
    }

    // -- Utilities --

    _formatCurrency(value) {
        if (value === null || value === undefined || value === '') return '$0.00';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(value);
    }

    errorBanner = '';
    successBanner = '';

    _showToast(title, message, variant) {
        if (variant === 'error') {
            this.errorBanner = message;
            this.successBanner = '';
        } else if (variant === 'success') {
            this.successBanner = message;
            this.errorBanner = '';
        }
        this._scrollToTop();
        try {
            this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
        } catch (e) {
            // Toast not supported in Experience Cloud
        }
    }

    _scrollToTop() {
        const container = this.template.querySelector('lightning-card');
        if (container) {
            container.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    _extractErrorMessage(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        if (error && error.message) {
            return error.message;
        }
        return 'An unexpected error occurred. Please try again.';
    }
}
