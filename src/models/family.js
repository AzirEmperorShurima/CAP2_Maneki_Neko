import mongoose from "mongoose";

// models/family.js
const familySchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Tên gia đình là bắt buộc'],
        trim: true,
        minlength: [2, 'Tên gia đình phải có ít nhất 2 ký tự']
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
        validate: {
            validator: function (v) {
                return v.length > 0; // Phải có ít nhất 1 thành viên
            },
            message: 'Gia đình phải có ít nhất 1 thành viên'
        }
    }],
    sharedBudgets: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Budget' }],
    inviteCode: { type: String, unique: true, sparse: true },
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
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

familySchema.index({ 'pendingInvites.email': 1 });

export default mongoose.model('Family', familySchema);