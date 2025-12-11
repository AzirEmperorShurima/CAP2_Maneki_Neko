// models/transaction.js
import mongoose from "mongoose";

const transactionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    walletId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Wallet',
        required: false
    },
    amount: {
        type: Number,
        required: true,
        min: [0, 'Số tiền phải >= 0']
    },
    currency: {
        type: String,
        default: "VND"
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
        ref: 'Category',
        required: false,
        default: null
    },
    expense_for: {
        type: String,
        default: "Tôi"
    },
    date: {
        type: Date,
        default: Date.now
    },
    description: {
        type: String
    },
    type: {
        type: String,
        enum: ['income', 'expense'],
        required: true,
        default: "expense"
    },
    isDeleted: {
        type: Boolean,
        default: false
    },
    deletedAt: {
        type: Date,
        default: null
    },
    paymentMethod: {
        type: String,
        enum: ["cash", "card", "transfer"],
        default: "cash"
    },
    // Voice & OCR input
    inputType: {
        type: String,
        enum: ["manual", "voice", "bill_scan", "ai", "manual_corrected"],
        default: 'manual'
    },
    billMetadata: {
        imageUrl: String,
        thumbnail: String,
        publicId: String,

        merchant: String,
        items: [{
            name: String,
            quantity: Number,
            price: Number
        }],
        confidence: Number,
        voiceUrl: String,
        voicePublicId: String,
        voiceTranscript: String,

        analyzedAt: Date,
        correctedManually: {
            type: Boolean,
            default: false
        }
    },
    voiceText: { type: String },
    rawText: { type: String }, // bản gốc
    confidence: {
        type: Number,
        min: 0,
        max: 1,
        default: 1.0
    },
    isAutoCategorized: {
        type: Boolean,
        default: false
    },
    receiptImage: {
        type: String
    },
}, { timestamps: true });

transactionSchema.index({ userId: 1, date: -1 });
transactionSchema.index({ userId: 1, categoryId: 1, date: -1 });
transactionSchema.index({ userId: 1, type: 1, date: -1 });
transactionSchema.index({ walletId: 1 });
transactionSchema.index({ date: 1 });
transactionSchema.index({ userId: 1, isDeleted: 1, date: -1 });

export default mongoose.model("Transaction", transactionSchema);