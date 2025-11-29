import RefreshToken from "../models/refreshToken.js";

export const renewRefreshToken = async (userId, deviceId) => {
    await RefreshToken.deleteMany({ userId, deviceId });
    const refreshTokenValue = crypto.randomBytes(64).toString('hex');

    const refreshToken = new RefreshToken({
        token: refreshTokenValue,
        userId: userId,
        deviceId: deviceId,
        isValid: true,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 ngày
    });

    await refreshToken.save();
    return refreshTokenValue;
}