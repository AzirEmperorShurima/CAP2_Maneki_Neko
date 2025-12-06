import Wallet from "../models/wallet.js";

/**
 * Tìm ví mặc định nhận tiền của user hoặc tạo mới nếu chưa có
 * Sử dụng static method từ Wallet model
 */
export const getOrCreateDefaultWallet = async (userId) => {
    try {
        // Sử dụng static method từ model để tạo/lấy ví nhận tiền mặc định
        const wallet = await Wallet.getOrCreateDefaultWallet(
            userId,
            'default_receive', // scope cho ví nhận tiền
            null // không có familyId (personal wallet)
        );

        return wallet;
    } catch (error) {
        console.error('Lỗi khi tạo/lấy ví mặc định:', error);
        return null;
    }
};

/**
 * Lấy hoặc tạo ví tiết kiệm mặc định
 */
export const getOrCreateSavingsWallet = async (userId, familyId = null) => {
    try {
        const wallet = await Wallet.getOrCreateDefaultWallet(
            userId,
            'default_savings',
            familyId
        );
        return wallet;
    } catch (error) {
        console.error('Lỗi khi tạo/lấy ví tiết kiệm:', error);
        return null;
    }
};

/**
 * Lấy hoặc tạo ví ghi nợ mặc định
 */
export const getOrCreateDebtWallet = async (userId, familyId = null) => {
    try {
        const wallet = await Wallet.getOrCreateDefaultWallet(
            userId,
            'default_debt',
            familyId
        );
        return wallet;
    } catch (error) {
        console.error('Lỗi khi tạo/lấy ví ghi nợ:', error);
        return null;
    }
};

/**
 * Cập nhật ví mặc định khi cần thiết
 * CHÚ Ý: Với schema mới, isDefault được dùng cho system wallets
 * Function này giờ set ví "ưa thích" của user cho transactions
 */
export const setDefaultWallet = async (userId, walletId) => {
    try {
        // Kiểm tra wallet có tồn tại và thuộc về user không
        const wallet = await Wallet.findOne({
            _id: walletId,
            userId,
            isSystemWallet: false // Không cho set system wallet làm default
        });

        if (!wallet) {
            throw new Error('Không tìm thấy ví hoặc không có quyền truy cập');
        }

        // Bỏ isDefault của tất cả ví personal khác
        await Wallet.updateMany(
            {
                userId,
                _id: { $ne: walletId },
                scope: 'personal', // Chỉ update personal wallets
                isSystemWallet: false
            },
            { isDefault: false }
        );

        // Set ví này làm default
        wallet.isDefault = true;
        await wallet.save();

        return wallet;
    } catch (error) {
        console.error('Lỗi khi set ví mặc định:', error);
        throw error;
    }
};

/**
 * Lấy ví mặc định của user cho transactions (không phải system wallet)
 */
export const getUserDefaultWallet = async (userId) => {
    try {
        // Tìm ví personal được đánh dấu là default
        let wallet = await Wallet.findOne({
            userId,
            scope: 'personal',
            isDefault: true,
            isActive: true,
            isSystemWallet: false
        });

        // Nếu không có, lấy ví personal đầu tiên
        if (!wallet) {
            wallet = await Wallet.findOne({
                userId,
                scope: 'personal',
                isActive: true,
                isSystemWallet: false
            }).sort({ createdAt: 1 });
        }

        // Nếu vẫn không có, tạo ví mặc định nhận tiền
        if (!wallet) {
            wallet = await getOrCreateDefaultWallet(userId);
        }

        return wallet;
    } catch (error) {
        console.error('Lỗi khi lấy ví mặc định:', error);
        return null;
    }
};

/**
 * Kiểm tra user có đủ số dư trong wallet không
 */
export const checkWalletBalance = async (walletId, amount) => {
    try {
        const wallet = await Wallet.findById(walletId);
        if (!wallet) return false;

        return wallet.balance >= amount;
    } catch (error) {
        console.error('Lỗi kiểm tra số dư ví:', error);
        return false;
    }
};

/**
 * Lấy tổng số dư của user (không bao gồm ví nợ)
 */
export const getUserTotalBalance = async (userId) => {
    try {
        const wallets = await Wallet.find({
            userId,
            isActive: true,
            scope: { $nin: ['default_debt'] } // Không tính ví nợ
        });

        const totalBalance = wallets.reduce((sum, wallet) => sum + wallet.balance, 0);
        return totalBalance;
    } catch (error) {
        console.error('Lỗi tính tổng số dư:', error);
        return 0;
    }
};

export const getOrCreateDefaultExpenseWallet = async (userId, familyId = null) => {
    try {
        const wallet = await Wallet.getOrCreateDefaultWallet(
            userId,
            'default_expense',
            familyId
        );
        return wallet;
    } catch (error) {
        console.error('Lỗi khi tạo/lấy ví chi tiêu mặc định:', error);
        return null;
    }
};
