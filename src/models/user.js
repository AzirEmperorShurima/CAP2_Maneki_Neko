import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const userSchema = new mongoose.Schema({
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true,
        match: [/^\S+@\S+\.\S+$/, 'Email không hợp lệ']
    },
    username: {
        type: String,
        trim: true,
        maxlength: 50
    },
    password: {
        type: String,
        // Không required vì có thể đăng ký bằng Google
    },
    googleId: {
        type: String,
        unique: true,
        sparse: true
    },
    avatar: {
        type: String
    },
    familyId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Family'
    },
    isFamilyAdmin: {
        type: Boolean,
        default: false
    },
    authProvider: {
        type: String,
        enum: ['local', 'google', 'both'],
        default: 'local'
    }, // Track authentication method
    fcmTokens: [{
        token: { type: String, required: true },
        deviceId: { type: String, required: true },
        platform: { type: String, enum: ['android', 'ios'], required: true },
        lastUsed: { type: Date, default: Date.now }
    }]
}, { timestamps: true });

// Indexes
// userSchema.index({ googleId: 1 });
userSchema.index({ familyId: 1 });

// Virtual for display name
userSchema.virtual('displayName').get(function () {
    return this.username || this.email.split('@')[0];
});

// Methods
userSchema.methods.hasPassword = function () {
    return this.password && this.password.length > 0;
};

userSchema.methods.isGoogleLinked = function () {
    return !!this.googleId;
};

userSchema.methods.canLoginWithPassword = function () {
    return this.hasPassword();
};

userSchema.methods.canLoginWithGoogle = function () {
    return this.isGoogleLinked();
};

// Static method để hash password
userSchema.statics.hashPassword = async function (password) {
    return await bcrypt.hash(password, await bcrypt.genSalt(10));
};

// Pre-save middleware
userSchema.pre('save', async function (next) {
    // Auto-generate username nếu chưa có
    if (!this.username && this.email) {
        this.username = this.email.split('@')[0];
    }

    // Hash password nếu được thay đổi và không rỗng
    if (this.isModified('password') && this.password && this.password.length > 0) {
        try {
            this.password = await this.constructor.hashPassword(this.password);
        } catch (error) {
            return next(error);
        }
    }

    return next();
});

// Instance method để so sánh password
userSchema.methods.comparePassword = async function (password) {
    if (!password) throw new Error('Mật khẩu bị thiếu, không thể so sánh!');

    if (!this.hasPassword()) {
        throw new Error('Tài khoản này không có mật khẩu');
    }

    try {
        return await bcrypt.compare(password, this.password);
    } catch (error) {
        console.error('Lỗi khi so sánh mật khẩu!', error.message);
        throw new Error('Lỗi khi so sánh mật khẩu');
    }
};

export default mongoose.model("User", userSchema);
