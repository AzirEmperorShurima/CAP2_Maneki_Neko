import Wallet from "../models/wallet.js";
import Transaction from "../models/transaction.js";
import user from "../models/user.js";
import { validateCreateTransaction, validateUpdateTransaction, validateTransactionIdParam } from "../validations/transaction.js";

import * as transactionService from '../services/transactions/analytics/transactionAlalytics.js';
import { checkBudgetWarning, updateBudgetSpentAmounts } from "../utils/budget.js";
import { checkWalletBalance, getOrCreateDefaultWallet, getUserDefaultWallet, getOrCreateDefaultExpenseWallet } from "../utils/wallet.js";

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
                details: error.details.map(d => ({
                    field: d.path.join('.'),
                    message: d.message
                }))
            });
        }

        const { amount, type, expense_for, date, description, isShared, categoryId, walletId } = value;

        // Tìm hoặc tạo wallet
        let wallet = null;
        let walletCreated = false;

        if (walletId) {
            // Nếu có chỉ định walletId, tìm wallet đó
            wallet = await Wallet.findOne({
                _id: walletId,
                userId: req.userId,
                isActive: true
            });

            if (!wallet) {
                return res.status(404).json({
                    error: 'Ví không tồn tại hoặc không có quyền truy cập'
                });
            }

            // Kiểm tra quyền giao dịch
            if (!wallet.canUserTransact(req.userId)) {
                return res.status(403).json({
                    error: 'Bạn không có quyền giao dịch với ví này'
                });
            }
        } else {
            if (type === 'income') {
                wallet = await getOrCreateDefaultWallet(req.userId);
                walletCreated = true;
            } else if (type === 'expense') {
                wallet = await getOrCreateDefaultExpenseWallet(req.userId);
                walletCreated = true;
            }
        }

        if (!wallet) {
            return res.status(500).json({
                error: 'Không thể tạo hoặc tìm ví để ghi nhận giao dịch'
            });
        }

        let lowBalanceWarning = null;
        if (type === 'expense') {
            const hasEnoughBalance = await checkWalletBalance(wallet._id, amount);
            if (!hasEnoughBalance) {
                lowBalanceWarning = {
                    code: 'LOW_BALANCE',
                    walletId: wallet._id,
                    currentBalance: wallet.balance,
                    required: amount,
                    shortfall: amount - wallet.balance
                };
            }
        }

        // Tạo transaction
        const transaction = new Transaction({
            userId: req.userId,
            walletId: wallet._id,
            amount,
            type,
            expense_for: type === 'expense' ? expense_for : 'cá nhân',
            date: date || new Date(),
            description: description || '',
            isShared: isShared || false,
            categoryId: categoryId || null,
        });

        await transaction.save();

        // Cập nhật số dư wallet
        if (type === 'expense') {
            wallet.balance -= amount;
            await wallet.save();

            // Cập nhật budget
            const budgetUpdateCount = await updateBudgetSpentAmounts(req.userId, transaction);
            console.log(`✅ Updated ${budgetUpdateCount} budgets`);
            const budgetWarnings = await checkBudgetWarning(req.userId, transaction);
            const populatedTransaction = await Transaction.findById(transaction._id)
                .populate('categoryId', 'name')
                .populate('walletId', 'name balance scope type icon');
            const normalizedTransaction = (() => {
                const src = typeof populatedTransaction.toObject === 'function' ? populatedTransaction.toObject() : populatedTransaction;
                const { _id, walletId, categoryId, __v, ...rest } = src;
                return {
                    ...rest,
                    id: _id && _id.toString ? _id.toString() : String(_id),
                    walletId: walletId && walletId._id ? { ...walletId, id: walletId._id.toString(), _id: undefined } : walletId,
                    categoryId: categoryId && categoryId._id ? { ...categoryId, id: categoryId._id.toString(), _id: undefined } : categoryId
                };
            })();
            return res.status(201).json({
                message: 'Tạo giao dịch thành công',
                data: {
                    transaction: normalizedTransaction,
                    budgetWarnings: budgetWarnings ? {
                        count: budgetWarnings.length,
                        hasError: budgetWarnings.some(w => w.level === 'error'),
                        hasCritical: budgetWarnings.some(w => w.level === 'critical'),
                        warnings: budgetWarnings
                    } : null,
                    lowBalanceWarning,
                    walletInfo: {
                        id: wallet._id,
                        name: wallet.name,
                        balance: wallet.balance
                    }
                }
            });
        } else if (type === 'income') {
            wallet.balance += amount;
            await wallet.save();

            const populatedTransaction = await Transaction.findById(transaction._id)
                .populate('categoryId', 'name')
                .populate('walletId', 'name balance scope type icon');
            const normalizedTransaction = (() => {
                const src = typeof populatedTransaction.toObject === 'function' ? populatedTransaction.toObject() : populatedTransaction;
                const { _id, walletId, categoryId, __v, ...rest } = src;
                return {
                    ...rest,
                    id: _id && _id.toString ? _id.toString() : String(_id),
                    walletId: walletId && walletId._id ? { ...walletId, id: walletId._id.toString(), _id: undefined } : walletId,
                    categoryId: categoryId && categoryId._id ? { ...categoryId, id: categoryId._id.toString(), _id: undefined } : categoryId
                };
            })();
            return res.status(201).json({
                message: 'Tạo giao dịch thành công',
                data: {
                    transaction: normalizedTransaction,
                    walletInfo: {
                        id: wallet._id,
                        name: wallet.name,
                        balance: wallet.balance
                    }
                }
            });
        }

    } catch (err) {
        console.error('Create transaction error:', err);
        res.status(500).json({ error: 'Lỗi server', message: err.message });
    }
};

// update a transaction
export const updateTransaction = async (req, res) => {
    try {
        const { error: paramError, value: paramValue } = validateTransactionIdParam(req.params);
        if (paramError) {
            return res.status(400).json({
                error: 'Invalid param',
                details: paramError.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }
        const { transactionId } = paramValue;

        const { error, value } = validateUpdateTransaction(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }

        // Tìm transaction
        const transaction = await Transaction.findOne({
            _id: transactionId,
            userId: req.userId
        });

        if (!transaction) {
            return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
        }

        // Phân loại các trường cần update
        const criticalFields = ['amount', 'type', 'walletId'];
        const secondaryFields = [
            'date', 'description', 'isShared', 'categoryId',
            'paymentMethod', 'expense_for', 'inputType',
            'ocrText', 'voiceText', 'rawText', 'confidence',
            'isAutoCategorized', 'receiptImage', 'currency'
        ];

        // Kiểm tra xem có thay đổi critical fields không
        const hasCriticalChanges = criticalFields.some(field =>
            value[field] !== undefined && value[field] !== transaction[field]
        );

        // === FAST PATH: Chỉ update các trường phụ ===
        if (!hasCriticalChanges) {
            // Cập nhật trực tiếp các trường phụ
            secondaryFields.forEach(field => {
                if (value[field] !== undefined) {
                    transaction[field] = value[field];
                }
            });

            await transaction.save();

            // Populate và return
            const populatedTransaction = await Transaction.findById(transaction._id)
                .populate('categoryId', 'name')
                .populate('walletId', 'name balance scope type icon');

            return res.json({
                message: 'Cập nhật giao dịch thành công',
                data: populatedTransaction
            });
        }

        // === SLOW PATH: Có thay đổi amount/type/wallet - cần xử lý phức tạp ===
        const { amount, type, walletId } = value;

        // Lưu giá trị cũ
        const oldAmount = transaction.amount;
        const oldType = transaction.type;
        const oldWalletId = transaction.walletId;

        // BƯỚC 1: Hoàn nguyên ví cũ
        if (oldWalletId) {
            const oldWallet = await Wallet.findById(oldWalletId);
            if (oldWallet) {
                if (oldType === 'expense') {
                    oldWallet.balance += oldAmount; // Hoàn tiền
                } else if (oldType === 'income') {
                    oldWallet.balance -= oldAmount; // Trừ tiền
                }
                await oldWallet.save();
            }
        }

        // BƯỚC 2: Hoàn nguyên budget (nếu là expense)
        if (oldType === 'expense') {
            const restoreTransaction = {
                ...transaction.toObject(),
                amount: -oldAmount
            };
            await updateBudgetSpentAmounts(req.userId, restoreTransaction);
        }

        // BƯỚC 3: Cập nhật TẤT CẢ các thông tin transaction
        // Update critical fields
        if (amount !== undefined) transaction.amount = amount;
        if (type !== undefined) transaction.type = type;
        if (walletId !== undefined) transaction.walletId = walletId;

        // Update secondary fields
        secondaryFields.forEach(field => {
            if (value[field] !== undefined) {
                transaction[field] = value[field];
            }
        });

        await transaction.save();

        // BƯỚC 4: Xử lý ví mới
        let newWallet = null;
        if (transaction.walletId) {
            newWallet = await Wallet.findById(transaction.walletId);

            if (!newWallet) {
                if (transaction.type === 'income') {
                    newWallet = await getOrCreateDefaultWallet(req.userId);
                } else if (transaction.type === 'expense') {
                    newWallet = await getOrCreateDefaultExpenseWallet(req.userId);
                }
                if (newWallet) {
                    transaction.walletId = newWallet._id;
                    await transaction.save();
                }
            }

            if (newWallet) {
                // Kiểm tra số dư cho expense
                if (transaction.type === 'expense') {
                    if (newWallet.balance < transaction.amount) {
                        // Rollback
                        await transaction.deleteOne();
                        if (oldWalletId) {
                            const rollbackWallet = await Wallet.findById(oldWalletId);
                            if (rollbackWallet) {
                                if (oldType === 'expense') {
                                    rollbackWallet.balance -= oldAmount;
                                } else {
                                    rollbackWallet.balance += oldAmount;
                                }
                                await rollbackWallet.save();
                            }
                        }

                        return res.status(400).json({
                            error: 'Số dư ví mới không đủ',
                            currentBalance: newWallet.balance,
                            required: transaction.amount
                        });
                    }

                    newWallet.balance -= transaction.amount;
                } else if (transaction.type === 'income') {
                    newWallet.balance += transaction.amount;
                }

                await newWallet.save();
            }
        }

        // BƯỚC 5: Cập nhật budget mới (nếu là expense)
        if (transaction.type === 'expense') {
            await updateBudgetSpentAmounts(req.userId, transaction);
        }

        // Populate và return
        const populatedTransaction = await Transaction.findById(transaction._id)
            .populate('categoryId', 'name')
            .populate('walletId', 'name balance scope type icon');

        res.json({
            message: 'Cập nhật giao dịch thành công',
            data: populatedTransaction
        });

    } catch (err) {
        console.error('Update transaction error:', err);
        res.status(500).json({ error: 'Lỗi server', message: err.message });
    }
};


export const deleteTransaction = async (req, res) => {
    try {
        const { transactionId } = req.params;

        const transaction = await Transaction.findOne({
            _id: transactionId,
            userId: req.userId
        });

        if (!transaction) {
            return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
        }

        // Hoàn nguyên wallet
        if (transaction.walletId) {
            const wallet = await Wallet.findById(transaction.walletId);
            if (wallet) {
                if (transaction.type === 'expense') {
                    wallet.balance += transaction.amount; // Hoàn tiền
                } else if (transaction.type === 'income') {
                    wallet.balance -= transaction.amount; // Trừ tiền
                }
                await wallet.save();
            }
        }

        // Hoàn nguyên budget (nếu là expense)
        if (transaction.type === 'expense') {
            const restoreTransaction = {
                ...transaction.toObject(),
                amount: -transaction.amount
            };
            await updateBudgetSpentAmounts(req.userId, restoreTransaction);
        }

        // Xóa transaction
        await Transaction.deleteOne({ _id: transactionId });

        res.json({
            message: 'Đã xóa giao dịch thành công',
            data: {
                restoredBalance: transaction.amount
            }
        });

    } catch (err) {
        console.error('Delete transaction error:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getTransactionById = async (req, res) => {
    try {
        const { transactionId } = req.params;
        console.log(req.userId, transactionId, req.params);
        const transaction = await Transaction.findOne({ _id: transactionId, userId: req.userId })
            .populate('categoryId', 'name')
            .populate('walletId', 'name balance');

        if (!transaction) {
            return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
        }

        res.json({ message: 'Lấy giao dịch thành công', data: transaction });
    } catch (err) {
        console.error('Get transaction by ID error:', err);
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
                .populate('userId', 'username')
                .populate('walletId', 'name balance scope type icon')
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
                },
                wallet: plain.walletId ? {
                    id: plain.walletId._id,
                    name: plain.walletId.name,
                    balance: plain.walletId.balance,
                    scope: plain.walletId.scope,
                    type: plain.walletId.type,
                    icon: plain.walletId.icon
                } : null
            };
        });

        res.json({
            message: 'Lấy danh sách giao dịch thành công',
            data: {
                transactions: result,
                pagination: {
                    page,
                    limit,
                    total,
                    totalPages: Math.ceil(total / limit),
                    hasNext: page < Math.ceil(total / limit)
                }
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

        res.json({ message: 'Lấy dữ liệu biểu đồ giao dịch thành công', data: chartData });
    } catch (error) {
        console.error('Lỗi lấy chart data:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const softDeleteTransaction = async (req, res) => {
    try {
        const { error: paramError, value: paramValue } = validateTransactionIdParam(req.params);
        if (paramError) {
            return res.status(400).json({
                error: 'Invalid param',
                details: paramError.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }
        const { transactionId } = paramValue;

        const transaction = await Transaction.findOne({
            _id: transactionId,
            userId: req.userId,
            isDeleted: { $ne: true } // Chưa bị xóa
        });

        if (!transaction) {
            return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
        }

        // Refund wallet
        if (transaction.walletId) {
            const wallet = await Wallet.findById(transaction.walletId);
            if (wallet) {
                if (transaction.type === 'expense') {
                    wallet.balance += transaction.amount;
                } else if (transaction.type === 'income') {
                    wallet.balance -= transaction.amount;
                }
                await wallet.save();
            }
        }

        // Reverse budget
        if (transaction.type === 'expense') {
            const reverseTransaction = {
                ...transaction.toObject(),
                amount: -transaction.amount
            };
            await updateBudgetSpentAmounts(req.userId, reverseTransaction);
        }

        transaction.isDeleted = true;
        transaction.deletedAt = new Date();
        await transaction.save();

        res.json({
            message: 'Xóa giao dịch thành công (có thể khôi phục)',
            data: {
                id: transaction._id,
                canRestore: true
            }
        });

    } catch (err) {
        console.error('Soft delete transaction error:', err);
        res.status(500).json({
            error: 'Lỗi server',
            message: err.message
        });
    }
};
export const restoreTransaction = async (req, res) => {
    try {
        const { error: paramError, value: paramValue } = validateTransactionIdParam(req.params);
        if (paramError) {
            return res.status(400).json({
                error: 'Invalid param',
                details: paramError.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }
        const { transactionId } = paramValue;

        const transaction = await Transaction.findOne({
            _id: transactionId,
            userId: req.userId,
            isDeleted: true
        });

        if (!transaction) {
            return res.status(404).json({ error: 'Không tìm thấy giao dịch đã xóa' });
        }

        // Áp dụng lại vào wallet
        if (transaction.walletId) {
            const wallet = await Wallet.findById(transaction.walletId);
            if (wallet) {
                if (transaction.type === 'expense') {
                    if (wallet.balance < transaction.amount) {
                        return res.status(400).json({
                            error: 'Không đủ số dư để khôi phục giao dịch',
                            currentBalance: wallet.balance,
                            required: transaction.amount
                        });
                    }
                    wallet.balance -= transaction.amount;
                } else if (transaction.type === 'income') {
                    wallet.balance += transaction.amount;
                }
                await wallet.save();
            }
        }

        // Áp dụng lại vào budget
        if (transaction.type === 'expense') {
            await updateBudgetSpentAmounts(req.userId, transaction);
        }

        // Khôi phục
        transaction.isDeleted = false;
        transaction.deletedAt = null;
        await transaction.save();

        const populatedTransaction = await Transaction.findById(transaction._id)
            .populate('categoryId', 'name')
            .populate('walletId', 'name balance scope type icon');

        res.json({
            message: 'Khôi phục giao dịch thành công',
            data: populatedTransaction
        });

    } catch (err) {
        console.error('Restore transaction error:', err);
        res.status(500).json({
            error: 'Lỗi server',
            message: err.message
        });
    }
};
