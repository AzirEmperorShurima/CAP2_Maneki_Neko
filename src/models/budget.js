import mongoose from "mongoose";

const budgetSchema = new mongoose.Schema({
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
    }, // Budget cha (ví dụ: daily budget có parent là monthly budget)
    isDerived: {
        type: Boolean,
        default: false
    }, // Budget này có được tự động tạo từ budget cha không
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
    } // Số tiền đã chi trong kỳ hiện tại
}, { timestamps: true });

// Index
budgetSchema.index({ userId: 1, type: 1, isActive: 1 });
budgetSchema.index({ userId: 1, parentBudgetId: 1 });
budgetSchema.index({ familyId: 1 });

export default mongoose.model("Budget", budgetSchema);