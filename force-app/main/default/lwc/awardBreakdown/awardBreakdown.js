import { LightningElement, api } from 'lwc';

export default class AwardBreakdown extends LightningElement {
    @api breakdownData;

    get breakdown() {
        if (!this.breakdownData) return null;
        if (typeof this.breakdownData === 'string') {
            try {
                return JSON.parse(this.breakdownData);
            } catch (e) {
                return null;
            }
        }
        return this.breakdownData;
    }

    get factors() {
        return this.breakdown ? this.breakdown.factors : [];
    }

    get totalScore() {
        return this.breakdown ? this.breakdown.totalScore : 0;
    }

    get maxScore() {
        return this.breakdown ? this.breakdown.maxScore : 15;
    }

    get awardPercentage() {
        return this.breakdown ? Math.round(this.breakdown.awardPercentage * 100) : 0;
    }

    get finalAward() {
        return this.breakdown ? this.breakdown.finalAward : 0;
    }

    get formattedFinalAward() {
        const amount = this.finalAward;
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    }

    get hasData() {
        return this.breakdown != null;
    }

    get scoreBarWidth() {
        if (!this.breakdown) return 'width: 0%';
        const pct = Math.round((this.totalScore / this.maxScore) * 100);
        return `width: ${pct}%`;
    }
}
