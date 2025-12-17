import mongoose from "mongoose";

const budgetSchema = new mongoose.Schema({
    name: {
        type: String,
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    type: {
        type: String,
        enum: ['daily', 'weekly', 'monthly'],
        required: true
    },
    amount: {
        type: Number,
        required: true,
        min: 0
    },
    parentBudgetId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Budget',
        default: null
    },
    isDerived: {
        type: Boolean,
        default: false
    },
    familyId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Family'
    },
    isShared: {
        type: Boolean,
        default: false
    },
    categoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category'
    },
    isActive: {
        type: Boolean,
        default: true
    },
    periodStart: {
        type: Date,
        required: true
    },
    periodEnd: {
        type: Date,
        required: true
    },
    spentAmount: {
        type: Number,
        default: 0
    },
    expireAt: {
        type: Date,
    }
}, { timestamps: true });

budgetSchema.index({ expireAt: 1 }, { expireAfterSeconds: 0 });

budgetSchema.index({ userId: 1, type: 1, isActive: 1 });
budgetSchema.index({ userId: 1, parentBudgetId: 1 });
budgetSchema.index({ familyId: 1 });

budgetSchema.pre('save', function (next) {
    if (this.isModified('periodEnd')) {
        this.expireAt = this.periodEnd;
    }
    next();
});


budgetSchema.methods.extendPeriod = function (newEndDate) {
    this.periodEnd = newEndDate;
    this.expireAt = newEndDate;
    return this.save();
};

export default mongoose.model("Budget", budgetSchema);