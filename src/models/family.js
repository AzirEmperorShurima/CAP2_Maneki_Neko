import mongoose from "mongoose";

const familySchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Tên gia đình là bắt buộc'],
        trim: true,
        minlength: [2, 'Tên gia đình phải có ít nhất 2 ký tự'],
        maxlength: [50, 'Tên gia đình không được vượt quá 50 ký tự']
    },
    adminId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: [true, 'Cần có admin'],
        index: true
    },
    members: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    }],
    // Các tài nguyên được chia sẻ trong gia đình
    sharedResources: {
        budgets: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Budget' }],
        wallets: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Wallet' }],
        goals: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Goal' }]
    },
    // Cài đặt chia sẻ trong gia đình
    sharingSettings: {
        transactionVisibility: {
            type: String,
            enum: ['all', 'only_income', 'none'],
            default: 'all' // all: tất cả giao dịch, only_income: chỉ giao dịch thu nhập, none: không chia sẻ giao dịch
        },
        walletVisibility: {
            type: String,
            enum: ['all', 'owner_only', 'summary_only'],
            default: 'summary_only' // all: xem toàn bộ chi tiết ví, owner_only: chỉ chủ ví xem được, summary_only: chỉ xem tổng số dư
        },
        goalVisibility: {
            type: String,
            enum: ['all', 'owner_only'],
            default: 'all' // all: tất cả thành viên xem được mục tiêu, owner_only: chỉ người tạo mục tiêu xem được
        }
    },
    inviteCode: {
        type: String,
        default: "null",
        unique: true,
        index: true,
        trim: true
    },
    pendingInvites: [{
        email: {
            type: String,
            required: [true, 'Email là bắt buộc'],
            lowercase: true,
            match: [/^\S+@\S+\.\S+$/, 'Email không hợp lệ']
        },
        invitedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        expiresAt: {
            type: Date,
            required: [true, 'Thời gian hết hạn là bắt buộc'],
            expires: '7d'
        }
    }],
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Indexes
familySchema.index({ 'adminId': 1 });
familySchema.index({ 'members': 1 });
familySchema.index({ 'pendingInvites.email': 1 });

// Virtual để đếm số thành viên
familySchema.virtual('memberCount', {
    ref: 'User',
    localField: 'members',
    foreignField: '_id',
    count: true
});

// Phương thức kiểm tra quyền truy cập
familySchema.methods.isMember = function (userId) {
    return this.members.some(memberId => memberId.equals(userId));
};

familySchema.methods.isAdmin = function (userId) {
    return this.adminId.equals(userId);
};

// Phương thức để kiểm tra một tài nguyên có được chia sẻ trong family không
familySchema.methods.isSharedResource = function (resourceType, resourceId) {
    const resourceArray = this.sharedResources[resourceType];
    return resourceArray && resourceArray.some(id => id.equals(resourceId));
};

// Phương thức để thêm tài nguyên vào danh sách chia sẻ
familySchema.methods.addSharedResource = async function (resourceType, resourceId) {
    if (!this.sharedResources[resourceType]) {
        this.sharedResources[resourceType] = [];
    }

    if (!this.sharedResources[resourceType].some(id => id.equals(resourceId))) {
        this.sharedResources[resourceType].push(resourceId);
        await this.save();
        return true;
    }
    return false; // Tài nguyên đã được chia sẻ
};

// Phương thức để xóa tài nguyên khỏi danh sách chia sẻ
familySchema.methods.removeSharedResource = async function (resourceType, resourceId) {
    const resourceArray = this.sharedResources[resourceType];
    if (resourceArray) {
        const initialLength = resourceArray.length;
        this.sharedResources[resourceType] = resourceArray.filter(id => !id.equals(resourceId));
        await this.save();
        return resourceArray.length !== this.sharedResources[resourceType].length;
    }
    return false;
};

export default mongoose.model('Family', familySchema);
