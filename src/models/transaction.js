import mongoose from "mongoose";

const transactionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    amount: { type: Number, required: true, min: [0, 'Số tiền phải >= 0'] },
    currency: { type: String, default: "VND" },
    familyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Family' },  // New: Nếu transaction thuộc family (shared)
    isShared: { type: Boolean, default: false },  // New: Có phải transaction chia sẻ trong family không
    categoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
        required: true
    },
    date: { type: Date, default: Date.now },
    description: { type: String }, // Mô tả (từ voice hoặc OCR)
    type: {
        type: String,
        enum: ['income', 'expense'],
        required: true,
        default: "expense"
    },
    paymentMethod: { type: String, enum: ["cash", "card", "transfer"], default: "cash" },
    // Voice & OCR input
    inputType: {
        type: String,
        enum: ["manual", "voice", "ocr", "ai"],
        default: 'manual'
    },
    ocrText: { type: String },
    voiceText: { type: String },
    rawText: { type: String }, // bản gốc
    confidence: { type: Number, min: 0, max: 1, default: 1.0 },
    isAutoCategorized: {
        type: Boolean,
        default: false
    },
    receiptImage: {
        type: String
    },
});

transactionSchema.index({ userId: 1, date: -1 });
transactionSchema.index({ userId: 1, categoryId: 1, date: -1 });
transactionSchema.index({ userId: 1, type: 1, date: -1 });
transactionSchema.index({ date: 1 });

export default mongoose.model("Transactions", transactionSchema);
