import mongoose from "mongoose";

const walletSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    familyId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Family',
        default: null
    },
    name: {
        type: String,
        required: [true, 'Tên ví là bắt buộc'],
        trim: true,
        maxlength: [50, 'Tên ví không được vượt quá 50 ký tự']
    },
    scope: {
        type: String,
        enum: ['personal', 'family', 'default_receive', 'default_savings', 'default_debt'],
        default: 'personal',
        required: true
    }, // Phạm vi ví: cá nhân, gia đình, hoặc system wallet
    type: {
        type: String,
        trim: true,
        maxlength: [100, 'Loại ví không được vượt quá 100 ký tự'],
        default: ''
    }, // Mục đích ví do user tự định nghĩa: "Ăn vặt", "Mua sắm", "Du lịch", etc.
    balance: {
        type: Number,
        required: true,
        default: 0
        // Không có min: 0, cho phép âm cho debt wallet
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isShared: {
        type: Boolean,
        default: false
    }, // true = ví gia đình, false = ví cá nhân
    isDefault: {
        type: Boolean,
        default: false
    },
    isSystemWallet: {
        type: Boolean,
        default: false
    }, // Ví hệ thống (default_receive, default_savings, default_debt)
    canDelete: {
        type: Boolean,
        default: true
    }, // Có thể xóa được không (false cho system wallets)
    description: {
        type: String,
        trim: true,
        maxlength: [500, 'Mô tả không được vượt quá 500 ký tự']
    },
    icon: {
        type: String,
        default: '💰'
    }, // Icon/emoji cho ví
    details: {
        bankName: { type: String, trim: true },
        accountNumber: { type: String, trim: true },
        cardNumber: { type: String, trim: true }
    },
    accessControl: {
        canView: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }],
        canTransact: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }]
    }
}, { timestamps: true });

// Indexes
walletSchema.index({ userId: 1, scope: 1, isDefault: 1 });
walletSchema.index({ userId: 1, isActive: 1 });
walletSchema.index({ familyId: 1, isShared: 1 });
walletSchema.index({ userId: 1, isSystemWallet: 1 });
walletSchema.index({ userId: 1, type: 1 }); // Index cho việc tìm kiếm theo mục đích

// Virtual để kiểm tra loại ví
walletSchema.virtual('walletCategory').get(function () {
    if (this.isSystemWallet) return 'system';
    return this.isShared ? 'family' : 'personal';
});

// Statics - Tạo hoặc lấy ví mặc định
walletSchema.statics.getOrCreateDefaultWallet = async function (userId, scope, familyId = null) {
    const walletConfig = {
        'default_receive': {
            name: 'Ví Nhận Tiền Mặc Định',
            description: 'Ví tự động nhận tiền từ gia đình',
            icon: '💰',
            type: 'Nhận tiền'
        },
        'default_savings': {
            name: 'Quỹ Tiết Kiệm',
            description: 'Ví lưu trữ số dư khi xóa ví',
            icon: '🏦',
            type: 'Tiết kiệm'
        },
        'default_debt': {
            name: 'Ví Ghi Nợ',
            description: 'Ghi nhận các khoản chi vượt quá số dư',
            icon: '📋',
            type: 'Ghi nợ'
        }
    };

    const config = walletConfig[scope];
    if (!config) throw new Error('Invalid wallet scope');

    // Tìm ví mặc định hiện có
    const query = {
        userId,
        scope,
        isSystemWallet: true
    };
    if (familyId) query.familyId = familyId;

    let wallet = await this.findOne(query);

    if (!wallet) {
        // Tạo ví mới
        wallet = new this({
            userId,
            familyId,
            name: config.name,
            scope,
            type: config.type,
            balance: 0,
            icon: config.icon,
            isDefault: true,
            isSystemWallet: true,
            canDelete: false,
            isShared: !!familyId,
            description: config.description,
            accessControl: familyId ? {
                canView: [],
                canTransact: []
            } : undefined
        });

        await wallet.save();
        console.log(`✅ Created ${scope} wallet for user ${userId}`);
    }

    return wallet;
};

// Methods
walletSchema.methods.canUserView = function (userId) {
    if (this.userId.equals(userId)) return true;
    if (!this.isShared) return false;
    return this.accessControl.canView.some(id => id.equals(userId));
};

walletSchema.methods.canUserTransact = function (userId) {
    if (this.userId.equals(userId)) return true;
    if (!this.isShared) return false;
    return this.accessControl.canTransact.some(id => id.equals(userId));
};

walletSchema.methods.canUserDelete = function (userId) {

    if (this.isSystemWallet && !this.canDelete) return false;

    if (this.isShared && this.familyId) {
        return false;
    }
    return this.userId.equals(userId);
};

walletSchema.methods.addBalance = async function (amount) {
    this.balance += amount;
    return await this.save();
};

walletSchema.methods.subtractBalance = async function (amount) {
    this.balance -= amount;
    return await this.save();
};

export default mongoose.model("Wallet", walletSchema);
