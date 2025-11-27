import mongoose from "mongoose";

const budgetSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, enum: ['daily', 'weekly', 'monthly'], required: true },
    amount: { type: Number, required: true },
    familyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Family' },
    isShared: { type: Boolean, default: false },
    categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' },
    goal: {
        name: { type: String },  // e.g., "Tiết kiệm du lịch"
        targetAmount: { type: Number },
        deadline: { type: Date },
        currentProgress: { type: Number, default: 0 }
    }
}, { timestamps: true });

export default mongoose.model("Budget", budgetSchema);