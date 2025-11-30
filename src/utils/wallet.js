import Wallet from "../models/wallet.js";
/**
 * Tìm ví mặc định của user hoặc tạo mới nếu chưa có
 */
export const getOrCreateDefaultWallet = async (userId) => {
    // Tìm ví mặc định đã tồn tại
    let wallet = await Wallet.findOne({
        userId,
        isDefault: true,
        isActive: true
    });

    if (!wallet) {
        // Nếu không có ví mặc định, tạo một ví mặc định mới
        wallet = new Wallet({
            userId,
            name: 'Ví mặc định',
            type: 'Chi tiêu hàng ngày',
            balance: 0,
            isActive: true,
            isDefault: true, // Đánh dấu là ví mặc định
            description: 'Ví mặc định được tạo tự động để ghi nhận các giao dịch thu nhập'
        });

        try {
            await wallet.save();
        } catch (error) {
            console.error('Lỗi khi tạo ví mặc định:', error);
            return null;
        }
    }

    return wallet;
};

/**
 * Cập nhật ví mặc định khi cần thiết
 */
export const setDefaultWallet = async (userId, walletId) => {
    // Đặt tất cả ví khác thành không phải mặc định
    await Wallet.updateMany(
        { userId, _id: { $ne: walletId } },
        { isDefault: false }
    );

    // Đặt ví được chỉ định thành ví mặc định
    const wallet = await Wallet.findOneAndUpdate(
        { _id: walletId, userId },
        { isDefault: true },
        { new: true }
    );

    return wallet;
};