// utils/familyHelpers.js
import Family from '../models/family.js';
import User from '../models/user.js';

export const familyHelpers = {
    // Kiểm tra user có quyền admin trong family không
    isFamilyAdmin: async (userId, familyId) => {
        const family = await Family.findById(familyId);
        return family && family.adminId.toString() === userId.toString();
    },

    // Kiểm tra user có phải là thành viên của family không
    isFamilyMember: async (userId, familyId) => {
        const family = await Family.findById(familyId);
        return family && family.members.some(memberId => memberId.toString() === userId.toString());
    },

    // Lấy tất cả thành viên của family (không bao gồm user hiện tại)
    getOtherFamilyMembers: async (familyId, excludeUserId) => {
        const family = await Family.findById(familyId)
            .populate('members', 'username email avatar fcmTokens');

        if (!family) return [];

        return family.members.filter(member =>
            member._id.toString() !== excludeUserId.toString()
        );
    },

    // Kiểm tra lời mời còn hiệu lực không
    isValidPendingInvite: (family, email) => {
        const invite = family.pendingInvites.find(i => i.email === email);
        return invite && new Date(invite.expiresAt) > new Date();
    },

    // Dọn dẹp các lời mời đã hết hạn
    cleanupExpiredInvites: async (familyId) => {
        const result = await Family.updateMany(
            { _id: familyId },
            { $pull: { pendingInvites: { expiresAt: { $lt: new Date() } } } }
        );
        return result.modifiedCount > 0;
    }
};