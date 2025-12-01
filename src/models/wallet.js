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
    type: {
        type: String,
        trim: true,
        maxlength: [30, 'Loại ví không được vượt quá 30 ký tự']
    },
    balance: {
        type: Number,
        required: true,
        default: 0,
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
    description: {
        type: String,
        trim: true,
        maxlength: [500, 'Mô tả không được vượt quá 500 ký tự']
    },
    details: {
        bankName: { type: String, trim: true },
        accountNumber: { type: String, trim: true },
        cardNumber: { type: String, trim: true }
    },
    // Quyền truy cập cho ví gia đình
    accessControl: {
        canView: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }], // Danh sách user có thể xem
        canTransact: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }] // Danh sách user có thể giao dịch
    }
}, { timestamps: true });

// Indexes
walletSchema.index({ userId: 1, isActive: 1 });
walletSchema.index({ familyId: 1, isShared: 1 });
walletSchema.index({ userId: 1, isDefault: 1 });
walletSchema.index({ 'accessControl.canView': 1 });
walletSchema.index({ 'accessControl.canTransact': 1 });

// Virtual để kiểm tra loại ví
walletSchema.virtual('walletType').get(function() {
    return this.isShared ? 'family' : 'personal';
});

// Methods
walletSchema.methods.canUserView = function(userId) {
    // Owner luôn xem được
    if (this.userId.equals(userId)) return true;
    
    // Ví cá nhân chỉ owner xem được
    if (!this.isShared) return false;
    
    // Ví gia đình: check accessControl
    return this.accessControl.canView.some(id => id.equals(userId));
};

walletSchema.methods.canUserTransact = function(userId) {
    // Owner luôn giao dịch được
    if (this.userId.equals(userId)) return true;
    
    // Ví cá nhân chỉ owner giao dịch được
    if (!this.isShared) return false;
    
    // Ví gia đình: check accessControl
    return this.accessControl.canTransact.some(id => id.equals(userId));
};

walletSchema.methods.addBalance = async function(amount) {
    if (amount <= 0) throw new Error('Số tiền phải lớn hơn 0');
    this.balance += amount;
    return await this.save();
};

walletSchema.methods.subtractBalance = async function(amount) {
    if (amount <= 0) throw new Error('Số tiền phải lớn hơn 0');
    if (this.balance < amount) throw new Error('Số dư không đủ');
    this.balance -= amount;
    return await this.save();
};

// Thêm user vào quyền xem
walletSchema.methods.grantViewAccess = function(userId) {
    if (!this.accessControl.canView.some(id => id.equals(userId))) {
        this.accessControl.canView.push(userId);
    }
};

// Thêm user vào quyền giao dịch (tự động có quyền xem)
walletSchema.methods.grantTransactAccess = function(userId) {
    this.grantViewAccess(userId);
    if (!this.accessControl.canTransact.some(id => id.equals(userId))) {
        this.accessControl.canTransact.push(userId);
    }
};

// Thu hồi quyền
walletSchema.methods.revokeAccess = function(userId) {
    this.accessControl.canView = this.accessControl.canView.filter(id => !id.equals(userId));
    this.accessControl.canTransact = this.accessControl.canTransact.filter(id => !id.equals(userId));
};

export default mongoose.model("Wallet", walletSchema);