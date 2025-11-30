import { firebase } from '../config/firebase.js';

export class PushNotificationService {
    static async sendNotificationToTokens(tokens, title, body, data = {}) {
        if (!tokens || tokens.length === 0) {
            return { success: 0, failure: 0, failedTokens: [] };
        }

        const message = {
            notification: {
                title,
                body
            },
            data,
            tokens
        };

        try {
            const response = await firebase.messaging().sendMulticast(message);

            if (response.failureCount > 0) {
                const failedTokens = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        failedTokens.push(tokens[idx]);
                    }
                });

                console.warn(`Push notification failed for ${failedTokens.length} tokens`);
                return {
                    success: response.successCount,
                    failure: response.failureCount,
                    failedTokens
                };
            }

            return {
                success: response.successCount,
                failure: 0,
                failedTokens: []
            };
        } catch (error) {
            console.error('Error sending push notifications:', error);
            throw error;
        }
    }

    static async sendNotificationToUser(user, title, body, data = {}) {
        if (!user.fcmTokens || user.fcmTokens.length === 0) {
            return { success: 0, failure: 0, failedTokens: [] };
        }

        const tokens = user.fcmTokens.map(tokenObj => tokenObj.token);
        return this.sendNotificationToTokens(tokens, title, body, data);
    }

    static async sendNotificationToUsers(users, title, body, data = {}) {
        const allTokens = [];
        users.forEach(user => {
            if (user.fcmTokens && user.fcmTokens.length > 0) {
                allTokens.push(...user.fcmTokens.map(tokenObj => tokenObj.token));
            }
        });

        if (allTokens.length === 0) {
            return { success: 0, failure: 0, failedTokens: [] };
        }

        return this.sendNotificationToTokens(allTokens, title, body, data);
    }

    static async sendNotificationToSpecificTokens(tokens, title, body, data = {}) {
        /**
         * Gửi thông báo đến một tập hợp token cụ thể
         * Có thể sử dụng khi cần gửi đến một số token không liên quan đến user nào
         */
        return this.sendNotificationToTokens(tokens, title, body, data);
    }

    static async sendSingleNotification(token, title, body, data = {}) {
        /**
         * Gửi thông báo đến một token duy nhất
         */
        if (!token) {
            return { success: false, error: 'Token is required' };
        }

        try {
            const message = {
                notification: {
                    title,
                    body
                },
                data,
                token
            };

            const response = await firebase.messaging().send(message);
            return { success: true, messageId: response };
        } catch (error) {
            console.error('Error sending single notification:', error);
            return {
                success: false,
                error: error.message,
                errorCode: error.code
            };
        }
    }

    static async removeInvalidTokens(tokens) {
        /**
         * Xóa các token không hợp lệ khỏi database
         * Nên gọi sau khi có các token bị báo lỗi từ sendMulticast
         */
        if (!tokens || tokens.length === 0) return;

        try {
            const batchResponse = await firebase.messaging().sendMulticast({ tokens });
            const invalidTokens = [];

            batchResponse.responses.forEach((resp, idx) => {
                if (!resp.success && resp.error?.code === 'messaging/registration-token-not-registered') {
                    invalidTokens.push(tokens[idx]);
                }
            });

            return invalidTokens;
        } catch (error) {
            console.error('Error validating tokens:', error);
            return [];
        }
    }
}

// Export các hàm tiện ích để sử dụng
export const sendNotificationToTokens = PushNotificationService.sendNotificationToTokens;
export const sendNotificationToUser = PushNotificationService.sendNotificationToUser;
export const sendNotificationToUsers = PushNotificationService.sendNotificationToUsers;
export const sendSingleNotification = PushNotificationService.sendSingleNotification;

export default PushNotificationService;