// models/transaction.js
import mongoose from "mongoose";

const transactionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    walletId: { // THÊM TRƯỜNG NÀY
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Wallet',
        required: false // Không bắt buộc, vì có thể ghi giao dịch không từ ví cụ thể
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
    paymentMethod: {
        type: String,
        enum: ["cash", "card", "transfer"],
        default: "cash"
    },
    // Voice & OCR input
    inputType: {
        type: String,
        enum: ["manual", "voice", "ocr", "ai"],
        default: 'manual'
    },
    ocrText: { type: String },
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

// Indexes để tối ưu truy vấn
transactionSchema.index({ userId: 1, date: -1 });
transactionSchema.index({ userId: 1, categoryId: 1, date: -1 });
transactionSchema.index({ userId: 1, type: 1, date: -1 });
transactionSchema.index({ walletId: 1 }); // Index cho walletId
transactionSchema.index({ date: 1 });

export default mongoose.model("Transaction", transactionSchema);