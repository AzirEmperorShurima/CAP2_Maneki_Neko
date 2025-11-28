// Goal Schema
import mongoose from "mongoose";

const goalSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    familyId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Family',
        required: false
    }, // null nếu là goal cá nhân
    name: {
        type: String,
        required: [true, 'Tên mục tiêu là bắt buộc'],
        trim: true,
        maxlength: [100, 'Tên mục tiêu không được vượt quá 100 ký tự']
    },
    description: {
        type: String,
        trim: true,
        maxlength: [500, 'Mô tả không được vượt quá 500 ký tự']
    },
    targetAmount: {
        type: Number,
        required: [true, 'Số tiền mục tiêu là bắt buộc'],
        min: [0, 'Số tiền mục tiêu phải lớn hơn hoặc bằng 0']
    },
    currentProgress: {
        type: Number,
        default: 0,
        min: 0
    },
    deadline: {
        type: Date,
        required: [true, 'Ngày hết hạn là bắt buộc']
    },
    isActive: {
        type: Boolean,
        default: true
    },
    status: {
        type: String,
        enum: ['active', 'completed', 'expired', 'cancelled'],
        default: 'active'
    },
    associatedWallets: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Wallet'
    }], // Các ví được liên kết với mục tiêu này
    isShared: {
        type: Boolean,
        default: false
    } // true nếu goal được chia sẻ với các thành viên khác trong family
}, { timestamps: true });

// Middleware tự động kiểm tra và cập nhật trạng thái khi lưu
goalSchema.pre('save', function (next) {
    const now = new Date();

    if (this.isModified('deadline') || this.isNew) {
        if (this.deadline && this.deadline <= now && this.isActive && this.status === 'active') {
            this.status = this.currentProgress >= this.targetAmount ? 'completed' : 'expired';
            this.isActive = false;
        }
    }

    next();
});

// Phương thức kiểm tra và cập nhật trạng thái mục tiêu
goalSchema.methods.checkStatus = function () {
    const now = new Date();
    if (!this.isActive) return this.status;

    if (this.currentProgress >= this.targetAmount) {
        this.status = 'completed';
        this.isActive = false;
    } else if (this.deadline <= now) {
        this.status = 'expired';
        this.isActive = false;
    }

    return this.status;
};

// Phương thức cập nhật tiến độ mục tiêu
goalSchema.methods.updateProgress = async function (newProgress) {
    this.currentProgress = Math.min(newProgress, this.targetAmount);
    await this.checkStatus();
    await this.save();

    return {
        isCompleted: this.status === 'completed',
        progressPercentage: this.targetAmount > 0 ? (this.currentProgress / this.targetAmount) * 100 : 0
    };
};

goalSchema.index({ userId: 1 });
goalSchema.index({ familyId: 1, isShared: 1 });
goalSchema.index({ userId: 1, status: 1 });
goalSchema.index({ deadline: 1 });

export default mongoose.model("Goal", goalSchema);