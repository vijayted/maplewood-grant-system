import { LightningElement, api } from 'lwc';

export default class EligibilityPanel extends LightningElement {
    @api eligibilityData;
    @api compact = false;

    get results() {
        if (!this.eligibilityData) return [];
        let data = this.eligibilityData;
        if (typeof data === 'string') {
            try { data = JSON.parse(data); } catch (e) { return []; }
        }
        const rules = data.rules || data;
        if (!Array.isArray(rules)) return [];
        return rules.map(rule => ({
            ...rule,
            ruleId: rule.ruleNumber || rule.ruleId,
            iconName: this.getIconName(rule),
            iconVariant: this.getIconVariant(rule),
            cssClass: this.getCssClass(rule)
        }));
    }

    get hasResults() {
        return this.results.length > 0;
    }

    get rulesPassed() {
        return this.results.filter(r => r.passed).length;
    }

    get totalRules() {
        return this.results.length || 6;
    }

    get summaryText() {
        return `${this.rulesPassed} of ${this.totalRules} rules passed`;
    }

    get isFullyEligible() {
        return this.results.length > 0 && this.results.every(r => r.passed);
    }

    get overallBadgeClass() {
        return this.isFullyEligible
            ? 'slds-badge slds-badge_success'
            : 'slds-badge slds-badge_warning';
    }

    get overallLabel() {
        return this.isFullyEligible ? 'Eligible' : 'Not Fully Eligible';
    }

    getIconName(rule) {
        if (rule.evaluated === false) return 'utility:dash';
        return rule.passed ? 'utility:check' : 'utility:close';
    }

    getIconVariant(rule) {
        if (rule.evaluated === false) return '';
        return rule.passed ? 'success' : 'error';
    }

    getCssClass(rule) {
        if (rule.evaluated === false) return 'rule-row rule-neutral';
        return rule.passed ? 'rule-row rule-pass' : 'rule-row rule-fail';
    }
}
