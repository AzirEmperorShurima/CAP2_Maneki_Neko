import mongoose from "mongoose";
import bcrypt from "bcrypt";

const userSchema = new mongoose.Schema({
    accountName: { type: String, required: true, unique: true }, // for login without google
    username: { type: String, unique: true, sparse: true },
    email: { type: String, required: true, unique: true },
    password: { type: String }, // Bỏ required vì có user chỉ dùng Google không có password
    googleId: { type: String, unique: true, sparse: true },
    avatar: { type: String },
    familyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Family' },
    isFamilyAdmin: { type: Boolean, default: false },
    fcmTokens: [{
        token: {
            type: String,
            required: true
        },
        deviceId: {
            type: String,
            required: true
        },
        platform: {
            type: String,
            enum: ['android', 'ios'],
            required: true
        },
        lastUsed: {
            type: Date,
            default: Date.now
        }
    }]
}, { timestamps: true });

// Index User Schema
userSchema.index({ accountName: 1 });
userSchema.index({ email: 1, username: 1 });
userSchema.index({ familyId: 1 });

// Phương thức kiểm tra xem user có mật khẩu hay không
userSchema.methods.hasPassword = function () {
    return this.password && this.password.length > 0;
};

// Phương thức kiểm tra xem user có được liên kết với Google hay không
userSchema.methods.isGoogleLinked = function () {
    return !!this.googleId;
};

// Static method để hash password
userSchema.statics.hashPassword = async function (password) {
    return await bcrypt.hash(password, await bcrypt.genSalt(10));
};

userSchema.methods.hasPassword = function () {
    return this.password && this.password.length > 0;
};

// Pre-save middleware chỉ hash password nếu password được thay đổi và không rỗng
userSchema.pre('save', async function (next) {
    // Chỉ hash password nếu password được thay đổi và không rỗng
    if (this.isModified('password') && this.password && this.password.length > 0) {
        try {
            this.password = await this.constructor.hashPassword(this.password);
        } catch (error) {
            return next(error);
        }
    }
    return next();
});

// Static method để so sánh password
userSchema.statics.comparePassword = async function (password, receivedPassword) {
    return await bcrypt.compare(password, receivedPassword);
};

// Instance method để so sánh password
userSchema.methods.comparePassword = async function (password) {
    if (!password) throw new Error('Mật khẩu bị thiếu, không thể so sánh!');

    // Kiểm tra xem user có password không
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