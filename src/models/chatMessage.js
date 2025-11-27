import mongoose from "mongoose";

const chatMessageSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    role: { type: String, enum: ['user', 'assistant'], required: true },
    content: { type: String, required: true },
    transactionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Transaction' },
    createdAt: { type: Date, default: Date.now }
});

export default mongoose.model("ChatMessage", chatMessageSchema);
