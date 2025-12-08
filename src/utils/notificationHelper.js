import User from "../models/user.js";
import PushNotificationService from "../services/pushNotificationService.js";
import { removeInvalidTokensFromUser } from "../utils/fcm.js"
/**
 * Gửi thông báo đến một user và tự động xử lý invalid tokens
 * @param {String} userId - User ID
 * @param {String} title - Notification title
 * @param {String} body - Notification body
 * @param {Object} data - Additional data
 */
export const sendNotificationToUserId = async (userId, title, body, data = {}) => {
    try {
        const user = await User.findById(userId);
        if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
            console.log(`⚠️ User ${userId} không có FCM token`);
            return { success: false, error: 'No tokens' };
        }

        const result = await PushNotificationService.sendNotificationToUser(
            user,
            title,
            body,
            data
        );

        // Xử lý invalid tokens
        if (result.failedTokens && result.failedTokens.length > 0) {
            setImmediate(async () => {
                await removeInvalidTokensFromUser(userId, result.failedTokens);
            });
        }

        return result;

    } catch (error) {
        console.error('Error sending notification to user:', error);
        return { success: false, error: error.message };
    }
};

/**
 * Gửi thông báo đến nhiều users
 * @param {Array} userIds - Array of user IDs
 * @param {String} title - Notification title
 * @param {String} body - Notification body
 * @param {Object} data - Additional data
 */
export const sendNotificationToMultipleUsers = async (userIds, title, body, data = {}) => {
    try {
        const users = await User.find({
            _id: { $in: userIds },
            'fcmTokens.0': { $exists: true }
        });

        if (users.length === 0) {
            console.log('⚠️ Không có user nào có FCM token');
            return { success: false, error: 'No users with tokens' };
        }

        const result = await PushNotificationService.sendNotificationToUsers(
            users,
            title,
            body,
            data
        );

        // Xử lý invalid tokens cho từng user
        if (result.failedTokens && result.failedTokens.length > 0) {
            setImmediate(async () => {
                for (const user of users) {
                    const userFailedTokens = result.failedTokens.filter(token =>
                        user.fcmTokens.some(t => t.token === token)
                    );
                    if (userFailedTokens.length > 0) {
                        await removeInvalidTokensFromUser(user._id, userFailedTokens);
                    }
                }
            });
        }

        return result;

    } catch (error) {
        console.error('Error sending notification to multiple users:', error);
        return { success: false, error: error.message };
    }
};

/**
 * Gửi thông báo đến tất cả members trong family
 * @param {String} familyId - Family ID
 * @param {String} title - Notification title
 * @param {String} body - Notification body
 * @param {Object} data - Additional data
 * @param {String} excludeUserId - User ID to exclude (optional)
 */
export const sendNotificationToFamily = async (familyId, title, body, data = {}, excludeUserId = null) => {
    try {
        const query = { familyId, 'fcmTokens.0': { $exists: true } };
        if (excludeUserId) {
            query._id = { $ne: excludeUserId };
        }

        const users = await User.find(query);

        if (users.length === 0) {
            console.log(`⚠️ Không có member nào trong family ${familyId} có FCM token`);
            return { success: false, error: 'No family members with tokens' };
        }

        return await PushNotificationService.sendNotificationToUsers(
            users,
            title,
            body,
            { ...data, familyId }
        );

    } catch (error) {
        console.error('Error sending notification to family:', error);
        return { success: false, error: error.message };
    }
};

/**
 * Template thông báo cho các event khác nhau
 */
export const NotificationTemplates = {
    // Family invitations
    familyInvite: (familyName, senderName) => ({
        title: '🏠 Lời mời gia nhập gia đình',
        body: `${senderName} đã mời bạn tham gia "${familyName}"`,
        data: { type: 'family_invite' }
    }),

    // Family updates
    memberJoined: (username, familyName) => ({
        title: '👋 Thành viên mới',
        body: `${username} đã tham gia "${familyName}"`,
        data: { type: 'member_joined' }
    }),

    memberLeft: (username, familyName) => ({
        title: '👋 Thành viên rời đi',
        body: `${username} đã rời khỏi "${familyName}"`,
        data: { type: 'member_left' }
    }),

    // Task notifications (ví dụ)
    taskAssigned: (taskName, assignerName) => ({
        title: '📋 Nhiệm vụ mới',
        body: `${assignerName} đã giao nhiệm vụ "${taskName}" cho bạn`,
        data: { type: 'task_assigned' }
    }),

    taskCompleted: (taskName, userName) => ({
        title: '✅ Hoàn thành nhiệm vụ',
        body: `${userName} đã hoàn thành "${taskName}"`,
        data: { type: 'task_completed' }
    }),

    // Reminder notifications
    reminder: (message) => ({
        title: '⏰ Nhắc nhở',
        body: message,
        data: { type: 'reminder' }
    }),

    // General notification
    general: (title, message) => ({
        title,
        body: message,
        data: { type: 'general' }
    })
};

export const sendFamilyInviteNotification = async (userId, familyName, senderName, familyId) => {
    const notification = NotificationTemplates.familyInvite(familyName, senderName);
    return await sendNotificationToUserId(
        userId,
        notification.title,
        notification.body,
        { ...notification.data, familyId }
    );
};

export const sendMemberJoinedNotification = async (familyId, username, familyName, excludeUserId) => {
    const notification = NotificationTemplates.memberJoined(username, familyName);
    return await sendNotificationToFamily(
        familyId,
        notification.title,
        notification.body,
        notification.data,
        excludeUserId
    );
};