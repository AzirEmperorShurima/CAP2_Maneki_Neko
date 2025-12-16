import Wallet from "../models/wallet.js";
import Transaction from "../models/transaction.js";
import user from "../models/user.js";
import { validateCreateTransaction, validateUpdateTransaction, validateTransactionIdParam } from "../validations/transaction.js";
import Category from "../models/category.js";

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
// Thêm helper function parse date
// Helper function parse date - LUÔN parse từ raw input trước khi validation
const parseDate = (dateInput) => {
    if (!dateInput) return new Date();

    // Nếu đã là Date object, kiểm tra xem có phải do Joi parse sai không
    if (dateInput instanceof Date) {
        // Nếu date hợp lệ, return luôn
        if (!isNaN(dateInput.getTime())) return dateInput;
        return new Date();
    }

    const dateStr = String(dateInput).trim();

    // Format: DD-MM-YYYY hoặc D-M-YYYY (priority cao nhất)
    if (/^\d{1,2}-\d{1,2}-\d{4}$/.test(dateStr)) {
        const [day, month, year] = dateStr.split('-').map(Number);
        const parsed = new Date(year, month - 1, day);
        // Set giờ về 00:00:00 local time
        parsed.setHours(0, 0, 0, 0);
        return parsed;
    }

    // Format: YYYY-MM-DD (ISO)
    if (/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
        const [year, month, day] = dateStr.split('-').map(Number);
        const parsed = new Date(year, month - 1, day);
        parsed.setHours(0, 0, 0, 0);
        return parsed;
    }

    // Fallback: dùng Date constructor mặc định
    const parsed = new Date(dateStr);
    return isNaN(parsed.getTime()) ? new Date() : parsed;
};

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
        const { amount, type, expense_for, description, isShared, categoryId, walletId } = value;
        const originalDate = req.body.date;

        let wallet = null;
        let walletCreated = false;

        if (walletId) {
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

        let expense_for_type = "";
        if (type === 'expense') {
            expense_for_type = expense_for || 'Tôi';
        } else if (type === 'income') {
            expense_for_type = "";
        }

        // FIX: Parse date đúng format DD-MM-YYYY từ raw input
        const parsedDate = parseDate(originalDate);
        console.log('📅 Original date:', originalDate, '→ Parsed:', parsedDate.toISOString(), '(Local:', parsedDate.toLocaleString('vi-VN'), ')');

        const transaction = new Transaction({
            userId: req.userId,
            walletId: wallet._id,
            amount,
            type,
            expense_for: expense_for_type,
            date: parsedDate,
            description: description || '',
            isShared: isShared || false,
            categoryId: categoryId || null,
        });

        await transaction.save();

        if (type === 'expense') {
            wallet.balance -= amount;
            await wallet.save();

            const budgetUpdateCount = await updateBudgetSpentAmounts(req.userId, transaction);
            console.log(`✅ Updated ${budgetUpdateCount} budgets`);
            const budgetWarnings = await checkBudgetWarning(req.userId, transaction);

            const populatedTransaction = await Transaction.findById(transaction._id)
                .populate('categoryId', 'name image')
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

        const transaction = await Transaction.findOne({
            _id: transactionId,
            userId: req.userId
        });

        if (!transaction) {
            return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
        }

        // Parse date giống createTransaction
        if (value.date !== undefined) {
            const originalDate = req.body.date;
            const parsedDate = parseDate(originalDate); // giả sử bạn đã có hàm parseDate toàn cục như trong create
            if (parsedDate) {
                value.date = parsedDate;
            } else {
                return res.status(400).json({ error: 'Định dạng ngày không hợp lệ' });
            }
        }

        // Kiểm tra có thay đổi gì không
        const fieldsToCheck = ['amount', 'type', 'walletId', 'date', 'description', 'isShared', 'categoryId',
            'paymentMethod', 'expense_for', 'inputType', 'ocrText', 'voiceText', 'rawText',
            'confidence', 'isAutoCategorized', 'receiptImage', 'currency'];

        const hasAnyChanges = fieldsToCheck.some(field => {
            if (value[field] === undefined) return false;

            if (field === 'date' && value[field] instanceof Date && transaction[field] instanceof Date) {
                return value[field].getTime() !== transaction[field].getTime();
            }
            if (field === 'walletId' || field === 'categoryId') {
                const newVal = value[field] ? value[field].toString() : null;
                const oldVal = transaction[field] ? transaction[field].toString() : null;
                return newVal !== oldVal;
            }
            return value[field] !== transaction[field];
        });

        if (!hasAnyChanges) {
            // Populate đầy đủ giống create
            const populated = await Transaction.findById(transaction._id)
                .populate('categoryId', 'name image')
                .populate('walletId', 'name balance scope type icon');

            const normalized = normalizeTransaction(populated); // hàm helper bên dưới

            return res.json({
                message: 'Không có thay đổi nào được thực hiện',
                data: {
                    transaction: normalized,
                    walletInfo: {
                        id: populated.walletId._id.toString(),
                        name: populated.walletId.name,
                        balance: populated.walletId.balance
                    }
                }
            });
        }

        // Lưu giá trị cũ để hoàn nguyên
        const oldAmount = transaction.amount;
        const oldType = transaction.type;
        const oldWalletId = transaction.walletId.toString();

        const newAmount = value.amount !== undefined ? value.amount : oldAmount;
        const newType = value.type !== undefined ? value.type : oldType;
        const newWalletId = value.walletId !== undefined ? value.walletId.toString() : oldWalletId;

        const isWalletChanged = newWalletId !== oldWalletId;

        // B1: Hoàn nguyên ví cũ
        const oldWallet = await Wallet.findById(oldWalletId);
        if (oldWallet) {
            if (oldType === 'expense') oldWallet.balance += oldAmount;
            else if (oldType === 'income') oldWallet.balance -= oldAmount;
            await oldWallet.save();
        }

        // B2: Hoàn nguyên budget cũ (nếu là expense cũ)
        if (oldType === 'expense') {
            await updateBudgetSpentAmounts(req.userId, { ...transaction.toObject(), amount: -oldAmount });
        }

        // B3: Cập nhật transaction với tất cả các field mới
        Object.keys(value).forEach(key => {
            transaction[key] = value[key];
        });
        await transaction.save();

        // B4: Xử lý ví mới
        let finalWallet = await Wallet.findById(transaction.walletId);
        let lowBalanceWarning = null;

        if (!finalWallet) {
            // Tạo ví mặc định nếu cần
            if (transaction.type === 'income') {
                finalWallet = await getOrCreateDefaultWallet(req.userId);
            } else if (transaction.type === 'expense') {
                finalWallet = await getOrCreateDefaultExpenseWallet(req.userId);
            }
            if (finalWallet) {
                transaction.walletId = finalWallet._id;
                await transaction.save();
            }
        }

        if (finalWallet) {
            // Kiểm tra số dư chỉ khi đổi ví và là expense
            if (isWalletChanged && transaction.type === 'expense' && finalWallet.balance < transaction.amount) {
                // Rollback toàn bộ
                lowBalanceWarning = {
                    code: 'LOW_BALANCE',
                    walletId: finalWallet._id,
                    currentBalance: finalWallet.balance,
                    required: transaction.amount,
                    shortfall: transaction.amount - finalWallet.balance
                };

                // Hoàn nguyên transaction
                await transaction.deleteOne();

                // Hoàn nguyên ví cũ
                if (oldWallet) {
                    if (oldType === 'expense') oldWallet.balance -= oldAmount;
                    else if (oldType === 'income') oldWallet.balance += oldAmount;
                    await oldWallet.save();
                }

                return res.status(400).json({
                    error: 'Số dư ví mới không đủ',
                    lowBalanceWarning
                });
            }

            // Áp dụng thay đổi vào ví mới
            if (transaction.type === 'expense') {
                finalWallet.balance -= transaction.amount;
            } else if (transaction.type === 'income') {
                finalWallet.balance += transaction.amount;
            }
            await finalWallet.save();
        }

        // B5: Cập nhật budget mới (nếu là expense mới)
        let budgetWarnings = null;
        if (transaction.type === 'expense') {
            await updateBudgetSpentAmounts(req.userId, transaction);
            const warnings = await checkBudgetWarning(req.userId, transaction);
            if (warnings && warnings.length > 0) {
                budgetWarnings = {
                    count: warnings.length,
                    hasError: warnings.some(w => w.level === 'error'),
                    hasCritical: warnings.some(w => w.level === 'critical'),
                    warnings
                };
            }
        }

        // Populate đúng theo type (giống create)
        const populateOptions = [
            { path: 'walletId', select: 'name balance scope type icon' },
            transaction.type === 'expense'
                ? { path: 'categoryId', select: 'name image' }
                : { path: 'categoryId', select: 'name' }
        ];

        const populatedTransaction = await Transaction.findById(transaction._id).populate(populateOptions);

        const normalizedTransaction = normalizeTransaction(populatedTransaction);

        // Response giống hệt create
        return res.json({
            message: 'Cập nhật giao dịch thành công',
            data: {
                transaction: normalizedTransaction,
                budgetWarnings,
                lowBalanceWarning: lowBalanceWarning || null,
                walletInfo: {
                    id: finalWallet._id.toString(),
                    name: finalWallet.name,
                    balance: finalWallet.balance
                }
            }
        });

    } catch (err) {
        console.error('Update transaction error:', err);
        res.status(500).json({ error: 'Lỗi server', message: err.message });
    }
};

// Helper để normalize transaction (tránh lặp code)
function normalizeTransaction(populated) {
    const src = populated.toObject ? populated.toObject() : populated;
    const { _id, walletId, categoryId, __v, ...rest } = src;

    return {
        ...rest,
        id: _id.toString(),
        walletId: walletId ? { ...walletId, id: walletId._id.toString(), _id: undefined } : null,
        categoryId: categoryId ? { ...categoryId, id: categoryId._id.toString(), _id: undefined } : null
    };
}


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

        let wallet = null;
        if (transaction.walletId) {
            wallet = await Wallet.findById(transaction.walletId);
            if (wallet) {
                if (transaction.type === 'expense') {
                    wallet.balance += transaction.amount;
                } else if (transaction.type === 'income') {
                    wallet.balance -= transaction.amount;
                }
                await wallet.save();
            }
        }

        if (transaction.type === 'expense') {
            const restoreTransaction = {
                ...transaction.toObject(),
                amount: -transaction.amount
            };
            await updateBudgetSpentAmounts(req.userId, restoreTransaction);
        }

        await Transaction.deleteOne({ _id: transactionId });

        const category = transaction.categoryId
            ? await Category.findById(transaction.categoryId).select('name type scope')
            : null;

        const normalizedTransaction = {
            id: transaction._id.toString(),
            amount: transaction.amount,
            type: transaction.type,
            date: transaction.date,
            description: transaction.description || '',
            category: category ? {
                id: category._id.toString(),
                name: category.name,
                type: category.type,
                scope: category.scope
            } : null,
            walletId: transaction.walletId ? transaction.walletId.toString() : null
        };

        const normalizedWallet = wallet ? {
            id: wallet._id.toString(),
            name: wallet.name,
            balance: wallet.balance
        } : null;

        res.json({
            message: 'Đã xóa giao dịch thành công',
            data: {
                transaction: normalizedTransaction,
                wallet: normalizedWallet,
                restoredAmount: transaction.amount
            }
        });

    } catch (err) {
        console.error('Delete transaction error:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getTransactionById = async (req, res) => {
    try {
        const { error: paramError, value: paramValue } = validateTransactionIdParam(req.params);
        if (paramError) {
            return res.status(400).json({
                error: 'Invalid param',
                details: paramError.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }
        const { transactionId } = paramValue;
        console.log(req.userId, transactionId, req.params);
        const transaction = await Transaction.findOne({ _id: transactionId, userId: req.userId })
            .populate('categoryId', 'name image')
            .populate('walletId', 'name balance');

        if (!transaction) {
            return res.status(404).json({ error: 'Không tìm thấy giao dịch' });
        }

        const plain = typeof transaction.toObject === 'function' ? transaction.toObject() : transaction;
        const normalized = {
            id: plain._id,
            amount: plain.amount,
            type: plain.type,
            date: plain.date,
            description: plain.description || '',
            isShared: !!plain.isShared,
            category: plain.categoryId ? {
                id: plain.categoryId._id,
                name: plain.categoryId.name || ''
            } : {
                id: '',
                name: ''
            },
            wallet: plain.walletId ? {
                id: plain.walletId._id,
                name: plain.walletId.name || '',
                balance: plain.walletId.balance ?? 0
            } : {
                id: '',
                name: '',
                balance: 0
            }
        };

        res.json({ message: 'Lấy giao dịch thành công', data: normalized });
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

        const { type, search, startDate, endDate, month, walletId } = req.query;

        let match = {};

        const userFilter = [{ userId: _user._id }];
        if (_user.familyId) {
            userFilter.push({ familyId: _user.familyId, isShared: true });
        }
        match.$or = userFilter;

        // Thêm filter theo walletId
        if (walletId) {
            // Kiểm tra wallet tồn tại và user có quyền xem
            const wallet = await Wallet.findById(walletId);
            if (!wallet) {
                return res.status(404).json({ error: 'Không tìm thấy ví' });
            }
            if (!wallet.canUserView(req.userId)) {
                return res.status(403).json({ error: 'Bạn không có quyền xem giao dịch của ví này' });
            }
            match.walletId = wallet._id;
        }

        if (type && ['income', 'expense'].includes(type)) {
            match.type = type;
        }

        // Xử lý filter theo tháng
        const monthStr = typeof month === 'string' ? month.trim() : '';
        if (monthStr) {
            const parts = monthStr.split('-');
            const y = parseInt(parts[0], 10);
            const m = parseInt(parts[1], 10) - 1;
            if (!Number.isNaN(y) && !Number.isNaN(m) && m >= 0 && m < 12) {
                const start = new Date(y, m, 1);
                start.setHours(0, 0, 0, 0);

                const end = new Date(y, m + 1, 0);
                end.setHours(23, 59, 59, 999);

                match.date = { $gte: start, $lte: end };
            }
        }

        // Xử lý filter theo startDate và endDate (nếu không có month)
        if (!match.date && (startDate || endDate)) {
            match.date = {};
            if (startDate) {
                const start = new Date(startDate);
                start.setHours(0, 0, 0, 0);
                match.date.$gte = start;
            }
            if (endDate) {
                const end = new Date(endDate);
                end.setHours(23, 59, 59, 999);
                match.date.$lte = end;
            }
        }

        // Xử lý search
        if (search && search.trim()) {
            const regex = { $regex: search.trim(), $options: 'i' };
            const searchConditions = [
                { description: regex },
                { voiceText: regex },
                { ocrText: regex },
                { 'categoryId.name': regex },
                { expense_for: regex }
            ];

            const existingConditions = { ...match };
            match = {
                $and: [
                    existingConditions,
                    { $or: searchConditions }
                ]
            };
        }

        const [transactions, total] = await Promise.all([
            Transaction.find(match)
                .populate('categoryId', 'name image')
                .populate('userId', 'username avatar')
                .populate('walletId', 'name balance scope type icon')
                .sort({ date: -1 })
                .skip(skip)
                .limit(limit),

            Transaction.countDocuments(match)
        ]);

        console.log(`Found ${transactions.length} transactions${walletId ? ` for wallet ${walletId}` : ''}`);

        const result = transactions.map(t => {
            const plain = t.toObject();
            return {
                id: plain._id,
                amount: plain.amount,
                type: plain.type,
                expense_for: plain.expense_for || '',
                date: plain.date,
                description: plain.description || '',
                isShared: plain.isShared || false,
                isOwner: plain.userId._id.toString() === req.userId.toString(),
                owner: {
                    id: plain.userId._id,
                    username: plain.userId.username || 'Maneki Neko',
                    avatar: plain.userId.avatar || ""
                },
                category: plain.categoryId ? {
                    id: plain.categoryId._id,
                    name: plain.categoryId.name,
                    image: plain.categoryId.image || ""
                } : {
                    name: 'Không xác định',
                    image: ""
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

        // Nếu filter theo walletId, thêm thông tin ví vào response
        let walletInfo = null;
        if (walletId) {
            const wallet = await Wallet.findById(walletId).select('name balance type icon scope');
            if (wallet) {
                walletInfo = {
                    id: wallet._id,
                    name: wallet.name,
                    balance: wallet.balance,
                    type: wallet.type,
                    icon: wallet.icon,
                    scope: wallet.scope
                };
            }
        }

        res.json({
            message: 'Lấy danh sách giao dịch thành công',
            data: {
                transactions: result,
                wallet: walletInfo,
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
        res.status(500).json({ error: 'Lỗi server', message: error.message });
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
