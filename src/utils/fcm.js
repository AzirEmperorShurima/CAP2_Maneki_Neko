// utils/fcmTokenHandler.js

/**
 * Hàm xử lý đăng ký FCM token
 * @param {Object} user - Đối tượng user cần cập nhật token
 * @param {Object} payload - Object chứa thông tin token
 * @param {String} payload.fcmToken - FCM token từ client
 * @param {String} payload.deviceId - Device identifier
 * @param {String} payload.platform - Platform của thiết bị (android/ios)
 * @returns {Promise<boolean>} - Trả về true nếu xử lý thành công
 */
export const registerFCMToken = async (user, payload) => {
    try {
        const { fcmToken, deviceId, platform } = payload;

        if (!fcmToken || !deviceId || !platform) {
            console.warn('Thiếu thông tin bắt buộc để đăng ký FCM token:', {
                hasFcmToken: !!fcmToken,
                hasDeviceId: !!deviceId,
                hasPlatform: !!platform
            });
            return false;
        }

        if (!['android', 'ios'].includes(platform)) {
            console.warn('Platform không hợp lệ:', platform);
            return false;
        }

        await user.updateOne({
            $pull: { fcmTokens: { deviceId: deviceId } }
        });
        const tokenData = {
            token: fcmToken,
            deviceId: deviceId,
            platform: platform,
            lastUsed: new Date()
        };

        await user.updateOne({
            $push: { fcmTokens: tokenData }
        });

        return true;

    } catch (error) {
        console.error('Lỗi khi đăng ký FCM token:', error);
        return false;
    }
};