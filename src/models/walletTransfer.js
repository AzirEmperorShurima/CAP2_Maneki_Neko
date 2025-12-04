import mongoose from "mongoose";

const walletTransferSchema = new mongoose.Schema({
    fromWalletId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Wallet',
        required: true
    },
    toWalletId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Wallet',
        required: true
    },
    amount: {
        type: Number,
        required: true,
        min: [0.01, 'Số tiền phải lớn hơn 0']
    },
    initiatedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    type: {
        type: String,
        enum: ['personal_to_personal', 'family_to_personal', 'personal_to_family', 'system_auto_transfer'],
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'completed', 'failed', 'cancelled'],
        default: 'completed'
    },
    note: {
        type: String,
        trim: true,
        maxlength: [500, 'Ghi chú không được vượt quá 500 ký tự']
    },
    isSystemTransfer: {
        type: Boolean,
        default: false
    }, // Transfer tự động bởi hệ thống
    metadata: {
        fromWalletName: String,
        toWalletName: String,
        fromWalletBalance: Number,
        toWalletBalance: Number,
        reason: String // 'wallet_deletion', 'auto_receive', 'debt_record'
    }
}, { timestamps: true });

walletTransferSchema.index({ fromWalletId: 1, createdAt: -1 });
walletTransferSchema.index({ toWalletId: 1, createdAt: -1 });
walletTransferSchema.index({ initiatedBy: 1, createdAt: -1 });

export const WalletTransfer = mongoose.model("WalletTransfer", walletTransferSchema);
