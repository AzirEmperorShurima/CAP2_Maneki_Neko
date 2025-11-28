// Wallet Schema
import mongoose from "mongoose";

const walletSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    familyId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Family',
        required: false
    }, // null nếu là wallet cá nhân
    name: {
        type: String,
        required: [true, 'Tên ví là bắt buộc'],
        trim: true,
        maxlength: [50, 'Tên ví không được vượt quá 50 ký tự']
    },
    type: {
        type: String,
        trim: true,
        maxlength: [30, 'Loại ví không được vượt quá 30 ký tự']
    }, // Không giới hạn enum, người dùng có thể tự đặt tên loại ví (ví dụ: "Ăn vặt", "Tiết kiệm", "Chi tiêu hàng ngày")
    balance: {
        type: Number,
        required: true,
        default: 0,
        min: 0
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isShared: {
        type: Boolean,
        default: false
    }, // true nếu wallet được chia sẻ với các thành viên khác trong family
    description: {
        type: String,
        trim: true,
        maxlength: [500, 'Mô tả không được vượt quá 500 ký tự']
    },
    details: {
        bankName: { type: String, trim: true },
        accountNumber: { type: String, trim: true },
        cardNumber: { type: String, trim: true }
    }
}, { timestamps: true });

walletSchema.index({ userId: 1 });
walletSchema.index({ familyId: 1, isShared: 1 });
walletSchema.index({ userId: 1, isActive: 1 });

export default mongoose.model("Wallet", walletSchema);