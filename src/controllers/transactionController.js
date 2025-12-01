import Wallet from "../models/wallet.js";
import Transaction from "../models/transaction.js";
import user from "../models/user.js";
import { validateCreateTransaction } from "../validations/transaction.js";

import * as transactionService from '../services/transactions/analytics/transactionAlalytics.js';
import { checkBudgetWarning, updateBudgetSpentAmounts } from "../utils/budget.js";
import { getOrCreateDefaultWallet } from "../utils/wallet.js";

// for self learning AI module in future
// export const correctTransaction = async (req, res) => {
//     const { transactionId, newCategoryName } = req.body;
//     const transaction = await Transaction.findById(transactionId);
//     if (!transaction || transaction.userId.toString() !== req.userId) return res.status(404).json({ error: 'Not found' });

//     let category = await Category.findOne({ name: newCategoryName, type: transaction.type });
//     if (!category) {
//         category = await new Category({
//             name: newCategoryName,
//             type: transaction.type,
//             keywords: []  // Sẽ cập nhật sau
//         }).save();
//     }

//     // SELF-LEARNING: Thêm keywords từ rawText vào category mới
//     const keywords = transaction.rawText.split(/\s+/).filter(word => word.length > 2);
//     const newKeywords = keywords.filter(kw => !category.keywords.includes(kw));
//     category.keywords.push(...newKeywords);
//     await category.save();

//     transaction.categoryId = category._id;
//     transaction.confidence = 1.0;  // User confirmed
//     await transaction.save();

//     res.json({ message: 'Đã sửa phân loại thành công.' });
// };

// create new a transaction in basic type
export const createTransaction = async (req, res) => {
    try {
        const { error, value } = validateCreateTransaction(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }

        const { amount, type, date, description, isShared, categoryId, walletId } = value;
        let wallet = null;
        if (walletId) {
            wallet = await Wallet.findOne({ _id: walletId, userId: req.userId, isActive: true });
            if (!wallet) {
                return res.status(404).json({ error: 'Ví không tồn tại hoặc không có quyền truy cập' });
            }
        } else if (type === 'income') {
            wallet = await getOrCreateDefaultWallet(req.userId);
            if (!wallet) {
                return res.status(500).json({ error: 'Không thể tạo hoặc tìm ví mặc định' });
            }
        }
        const _user = await user.findById(req.userId);
        if (!_user) return res.status(404).json({ error: 'User không tồn tại' });

        const transaction = await new Transaction({
            userId: _user._id,
            amount,
            type,
            date,
            description,
            isShared,
            categoryId,
        }).save();
        if (type === 'expense') {
            // Với giao dịch chi tiêu: cập nhật spentAmount trong budget và trừ tiền từ wallet
            await updateBudgetSpentAmounts(req.userId, transaction);

            if (wallet) {
                wallet.balance -= amount;
                await wallet.save();
            }
        } else if (type === 'income') {
            // Với giao dịch thu nhập: chỉ cộng tiền vào wallet
            if (wallet) {
                wallet.balance += amount;
                await wallet.save();
            }
        }
        const budgetWarning = type === 'expense' ? await checkBudgetWarning(req.userId, transaction) : null;

        const populatedTransaction = await Transaction.findById(transaction._id)
            .populate('categoryId', 'name')
            .populate('walletId', 'name balance');

        res.json({
            message: 'Tạo giao dịch thành công',
            transaction: populatedTransaction,
            budgetWarning: budgetWarning || null,
            walletCreated: wallet && wallet.isDefault ? true : false
        });

    } catch (err) {
        console.error('Create transaction error:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

// update a transaction
export const updateTransaction = async (req, res) => {
    try {
        const { transactionId } = req.params;
        const { amount, type, date, description, isShared, categoryId, walletId } = req.body;

        const transaction = await Transaction.findOne({ _id: transactionId, userId: req.userId });
        if (!transaction) {
            return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
        }

        const oldAmount = transaction.amount;
        const oldType = transaction.type;
        const oldWalletId = transaction.walletId;

        // Cập nhật thông tin giao dịch
        if (amount !== undefined) transaction.amount = amount;
        if (type !== undefined) transaction.type = type;
        if (date !== undefined) transaction.date = date;
        if (description !== undefined) transaction.description = description;
        if (isShared !== undefined) transaction.isShared = isShared;
        if (categoryId !== undefined) transaction.categoryId = categoryId;
        if (walletId !== undefined) transaction.walletId = walletId;

        await transaction.save();

        // Xử lý cập nhật wallet và budget
        if (oldType === 'expense' || type === 'expense') {
            if (oldType === 'expense') {
                const restoreTransaction = { ...transaction.toObject(), amount: -oldAmount };
                await updateBudgetSpentAmounts(req.userId, restoreTransaction);
            }

            if (type === 'expense') {
                await updateBudgetSpentAmounts(req.userId, transaction);
            }
        }

        // Xử lý cập nhật số dư wallet
        if (oldWalletId) {
            const oldWallet = await Wallet.findById(oldWalletId);
            if (oldWallet) {
                if (oldType === 'expense') {
                    oldWallet.balance += oldAmount;
                } else if (oldType === 'income') {
                    oldWallet.balance -= oldAmount;
                }
                await oldWallet.save();
            }
        }

        if (transaction.walletId) {
            let currentWallet = await Wallet.findById(transaction.walletId);

            // Nếu không tìm thấy wallet và là giao dịch thu nhập, tạo wallet mặc định
            if (!currentWallet && type === 'income') {
                currentWallet = await getOrCreateDefaultWallet(req.userId);
                if (currentWallet) {
                    transaction.walletId = currentWallet._id;
                    await transaction.save();
                }
            }

            if (currentWallet) {
                if (type === 'expense') {
                    currentWallet.balance -= transaction.amount;
                } else if (type === 'income') {
                    currentWallet.balance += transaction.amount;
                }
                await currentWallet.save();
            }
        }

        const populatedTransaction = await Transaction.findById(transaction._id)
            .populate('categoryId', 'name')
            .populate('walletId', 'name balance');

        res.json({ message: 'Cập nhật giao dịch thành công', transaction: populatedTransaction });

    } catch (err) {
        console.error('Update transaction error:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const deleteTransaction = async (req, res) => {
    try {
        const { transactionId } = req.params;
        const transaction = await Transaction.findOne({ _id: transactionId, userId: req.userId });

        if (!transaction) {
            return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
        }

        // Nếu là giao dịch chi tiêu, khôi phục số tiền trong budget và wallet
        if (transaction.type === 'expense') {
            // Khôi phục số tiền trong budget
            const restoreTransaction = { ...transaction.toObject(), amount: -transaction.amount };
            await updateBudgetSpentAmounts(req.userId, restoreTransaction);

            // Khôi phục số tiền trong wallet nếu có
            if (transaction.walletId) {
                const wallet = await Wallet.findById(transaction.walletId);
                if (wallet) {
                    wallet.balance += transaction.amount;
                    await wallet.save();
                }
            }
        }

        await Transaction.deleteOne({ _id: transactionId, userId: req.userId });

        res.json({ message: 'Đã xóa giao dịch thành công' });

    } catch (err) {
        console.error('Delete transaction error:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

// get Transaction by user
export const getTransactions = async (req, res) => {
    try {
        const _user = await user.findById(req.userId);
        if (!_user) return res.status(404).json({ error: 'User không tồn tại' });

        const page = Math.max(1, parseInt(req.query.page) || 1);
        const limit = Math.min(100, parseInt(req.query.limit) || 20);
        const skip = (page - 1) * limit;

        const { type, search, startDate, endDate } = req.query;

        // Base match để lấy tất cả transaction của user và transaction chia sẻ trong family
        let match = {
            $or: [
                { userId: _user._id },
                { familyId: _user.familyId, isShared: true }
            ]
        };

        // Chỉ thêm các điều kiện lọc khi chúng được cung cấp và có giá trị hợp lệ
        if (type && ['income', 'expense'].includes(type)) {
            match.type = type;
        }

        if (startDate || endDate) {
            match.date = {};
            if (startDate) {
                match.date.$gte = new Date(startDate);
            }
            if (endDate) {
                match.date.$lte = new Date(endDate);
            }
        }

        // Xử lý tìm kiếm
        if (search && search.trim()) {
            const regex = { $regex: search.trim(), $options: 'i' };
            const searchCondition = {
                $or: [
                    { description: regex },
                    { voiceText: regex },
                    { ocrText: regex }
                ]
            };

            // Nếu đã có điều kiện khác, thêm search condition vào match
            // Nếu chưa có điều kiện khác, chỉ sử dụng search condition
            if (Object.keys(match).length > 1) { // > 1 vì đã có $or base
                match.$and = [
                    match,
                    searchCondition
                ];
            } else {
                match = searchCondition;
            }
        }

        const [transactions, total] = await Promise.all([
            Transaction.find(match)
                .populate('categoryId', 'name')
                .populate('userId', 'username avatar')
                .sort({ date: -1 })
                .skip(skip)
                .limit(limit),

            Transaction.countDocuments(match)
        ]);

        const result = transactions.map(t => {
            const plain = t.toObject();
            return {
                id: plain._id,
                amount: plain.amount,
                type: plain.type,
                date: plain.date,
                description: plain.description || '',
                isShared: plain.isShared || false,
                isOwner: plain.userId._id.toString() === req.userId.toString(),
                owner: {
                    id: plain.userId._id,
                    username: plain.userId.username || 'Không tên',
                    avatar: plain.userId.avatar || null
                },
                category: plain.categoryId ? {
                    id: plain.categoryId._id,
                    name: plain.categoryId.name,
                } : {
                    name: 'Không xác định',
                }
            };
        });

        res.json({
            success: true,
            transactions: result,
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit),
                hasNext: page < Math.ceil(total / limit)
            }
        });

    } catch (error) {
        console.error('Lỗi lấy transactions:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getTransactionChartData = async (req, res) => {
    try {
        const _user = await user.findById(req.userId);
        if (!_user) return res.status(404).json({ error: 'User không tồn tại' });

        const { month, type } = req.body;
        const chartData = await transactionService.getTransactionChartData(_user._id, month, type);

        res.json({ success: true, chartData });
    } catch (error) {
        console.error('Lỗi lấy chart data:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};
