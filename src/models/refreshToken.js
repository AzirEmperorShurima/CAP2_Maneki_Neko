import mongoose from "mongoose";

const refreshTokenSchema = new mongoose.Schema({
    token: {
        type: String,
        required: true,
        unique: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
        index: true
    },
    deviceId: {
        type: String,
        required: true,
        index: true
    },
    isValid: {
        type: Boolean,
        default: true
    },
    expiresAt: {
        type: Date,
        required: true
    }
}, { timestamps: true });

// Tự động xóa các refresh token đã hết hạn
refreshTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export default mongoose.model("RefreshToken", refreshTokenSchema);