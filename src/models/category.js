import mongoose from "mongoose";

const categorySchema = new mongoose.Schema({
    name: { type: String, required: true, trim: true },
    type: {
        type: String,
        enum: ['income', 'expense'],
        required: true
    },
    keywords: [{ type: String, lowercase: true }],
    scope: {
        type: String,
        enum: ['system', 'personal', 'family'],
        default: 'personal'
    },

    // Chủ sở hữu
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },
    familyId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Family',
        default: null,
        index: true
    },
    isDefault: { type: Boolean, default: false } // chỉ dùng cho scope: 'system'
}, { timestamps: true });

categorySchema.index({ scope: 1, userId: 1, familyId: 1 });
categorySchema.index({ userId: 1 });

export default mongoose.model('Category', categorySchema);