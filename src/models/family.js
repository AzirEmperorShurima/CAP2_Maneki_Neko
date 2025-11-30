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

// Kiểm tra xem lời mời có tồn tại và còn hiệu lực cho một email cụ thể không
familySchema.methods.hasValidPendingInvite = function (email) {
    const invite = this.pendingInvites.find(pendingInvite =>
        pendingInvite.email === email &&
        new Date(pendingInvite.expiresAt) > new Date()
    );
    return !!invite;
};

// Xóa một lời mời đang chờ xử lý theo email
familySchema.methods.removePendingInvite = function (email) {
    const initialLength = this.pendingInvites.length;
    this.pendingInvites = this.pendingInvites.filter(invite => invite.email !== email);
    return this.pendingInvites.length < initialLength;
};

// Thêm hoặc cập nhật một lời mời
familySchema.methods.upsertPendingInvite = function (email, invitedBy, expiresAt) {
    const existingIndex = this.pendingInvites.findIndex(invite => invite.email === email);

    if (existingIndex !== -1) {
        // Cập nhật lời mời hiện có
        this.pendingInvites[existingIndex].invitedBy = invitedBy;
        this.pendingInvites[existingIndex].expiresAt = expiresAt;
        return false; // Đã tồn tại và được cập nhật
    } else {
        // Tạo lời mời mới
        this.pendingInvites.push({ email, invitedBy, expiresAt });
        return true; // Lời mời mới được tạo
    }
};

// Thêm một thành viên vào family
familySchema.methods.addMember = function (userId) {
    if (this.members.some(memberId => memberId.equals(userId))) {
        return false; // Đã là thành viên
    }
    this.members.push(userId);
    return true;
};

// Xóa một thành viên khỏi family
familySchema.methods.removeMember = function (userId) {
    const initialLength = this.members.length;
    this.members = this.members.filter(memberId => !memberId.equals(userId));
    return this.members.length < initialLength;
};

// Dọn dẹp các lời mời đã hết hạn
familySchema.methods.cleanupExpiredInvites = function () {
    const initialLength = this.pendingInvites.length;
    this.pendingInvites = this.pendingInvites.filter(invite =>
        new Date(invite.expiresAt) > new Date()
    );
    return this.pendingInvites.length < initialLength;
};

// Kiểm tra xem có thể tạo lời mời cho email này không
familySchema.methods.canCreateInvite = function (email) {
    return !this.members.some(member => member.email === email) &&
        !this.pendingInvites.some(invite => invite.email === email);
};

export default mongoose.model('Family', familySchema);
