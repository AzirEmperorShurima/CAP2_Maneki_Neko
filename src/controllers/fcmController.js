import { registerFCMToken } from "../utils/fcm.js";
import user from "../models/user.js";

export const registerNewFCMToken = async (req, res) => {
    try {
        const { fcmToken, deviceId, platform } = req.body;

        if (!fcmToken || !deviceId || !platform) {
            return res.status(400).json({ error: 'Thiếu thông tin bắt buộc: fcmToken, deviceId, platform' });
        }

        const currentUser = await user.findById(req.userId);
        if (!currentUser) {
            return res.status(404).json({ error: 'Không tìm thấy người dùng' });
        }
        const fcmPayload = {
            fcmToken,
            deviceId,
            platform
        };

        const success = await registerFCMToken(currentUser, fcmPayload);

        if (success) {
            res.json({ success: true, message: 'Đăng ký FCM token thành công' });
        } else {
            res.status(400).json({ error: 'Không thể đăng ký FCM token' });
        }

    } catch (error) {
        console.error('Lỗi đăng ký FCM token:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};


export const removeFCMToken = async (req, res) => {
    try {
        const { deviceId } = req.body;

        if (!deviceId) {
            return res.status(400).json({ error: 'Thiếu deviceId' });
        }

        const result = await user.updateOne(
            { _id: req.userId },
            { $pull: { fcmTokens: { deviceId: deviceId } } }
        );

        if (result.modifiedCount > 0) {
            res.json({ success: true, message: 'Đã xóa FCM token' });
        } else {
            res.json({ success: true, message: 'Không tìm thấy token để xóa' });
        }

    } catch (error) {
        console.error('Lỗi xóa FCM token:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getFCMTokens = async (req, res) => {
    try {
        const userDoc = await user.findById(req.userId)
            .select('fcmTokens')
            .lean();

        if (!userDoc || !userDoc.fcmTokens || userDoc.fcmTokens.length === 0) {
            return res.json({
                success: true,
                tokens: []
            });
        }

        const tokens = userDoc.fcmTokens.map(token => ({
            deviceId: token.deviceId,
            platform: token.platform,
            lastUsed: token.lastUsed,
            // token: token.token
        }));

        res.json({
            success: true,
            tokens
        });

    } catch (error) {
        console.error('Lỗi lấy danh sách FCM tokens:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

/**
 * Xóa tất cả FCM tokens của user ngoại trừ token hiện tại
 */
export const clearAllAnotherFCMTokens = async (req, res) => {
    try {
        const { deviceId, fcmToken } = req.body;
        if (!deviceId && !fcmToken) {
            return res.status(400).json({ error: 'Thiếu deviceId hoặc fcmToken hiện tại' });
        }

        const userDoc = await user.findById(req.userId).select('fcmTokens');
        if (!userDoc) {
            return res.status(404).json({ error: 'Không tìm thấy user' });
        }

        const keep = (userDoc.fcmTokens || []).filter(t => {
            return (deviceId && t.deviceId === deviceId) || (fcmToken && t.token === fcmToken);
        }).map(t => ({ token: t.token, deviceId: t.deviceId, platform: t.platform, lastUsed: new Date() }));

        const result = await user.updateOne({ _id: req.userId }, { $set: { fcmTokens: keep } });

        res.json({
            success: true,
            kept: keep.length,
            message: keep.length > 0 ? 'Đã xóa các token khác, giữ lại token hiện tại' : 'Không tìm thấy token hiện tại, đã xóa tất cả'
        });

    } catch (error) {
        console.error('Lỗi xóa tất cả FCM tokens:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};
