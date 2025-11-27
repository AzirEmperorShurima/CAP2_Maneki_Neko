// Update file: models/user.js
import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
    username: { type: String, unique: true, sparse: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    googleId: { type: String, unique: true, sparse: true },
    avatar: { type: String },
    familyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Family' },
    isFamilyAdmin: { type: Boolean, default: false }
}, { timestamps: true });

userSchema.statics.comparePassword = async function (password, receivedPassword) {
    return await bcrypt.compare(password, receivedPassword);
};
userSchema.methods.comparePassword = async function (password) {
    if (!password) throw new Error('Mật khẩu bị thiếu, không thể so sánh!');
    try {
        return await password == this.password;
    } catch (error) {
        console.error('Lỗi khi so sánh mật khẩu!', error.message);
        throw new Error('Lỗi khi so sánh mật khẩu');
    }
};

export default mongoose.model("User", userSchema);