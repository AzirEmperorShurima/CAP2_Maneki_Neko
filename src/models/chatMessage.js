import mongoose from "mongoose";

const chatMessageSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    turn: {
        user: {
            content: { type: String, required: true },
            data: { type: mongoose.Schema.Types.Mixed, default: null }
        },
        assistant: {
            content: { type: String, default: '' },
            data: { type: mongoose.Schema.Types.Mixed, default: null }
        }
    },
    action: { type: String, default: 'none' },
    data: { type: mongoose.Schema.Types.Mixed, default: null },
    createdAt: { type: Date, default: Date.now }
});

export default mongoose.model("ChatMessage", chatMessageSchema);
