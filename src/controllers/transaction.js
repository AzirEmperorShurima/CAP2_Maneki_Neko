import Category from "../models/category.js";
import Transaction from "../models/transaction.js";
import user from "../models/user.js";
import { validateCreateTransaction } from "../validations/transaction.js";

import * as transactionService from '../services/transactions/analytics/transactionAlalytics.js';

// for self learning AI module in future
export const correctTransaction = async (req, res) => {
    const { transactionId, newCategoryName } = req.body;
    const transaction = await Transaction.findById(transactionId);
    if (!transaction || transaction.userId.toString() !== req.userId) return res.status(404).json({ error: 'Not found' });

    let category = await Category.findOne({ name: newCategoryName, type: transaction.type });
    if (!category) {
        category = await new Category({
            name: newCategoryName,
            type: transaction.type,
            keywords: []  // Sẽ cập nhật sau
        }).save();
    }

    // SELF-LEARNING: Thêm keywords từ rawText vào category mới
    const keywords = transaction.rawText.split(/\s+/).filter(word => word.length > 2);
    const newKeywords = keywords.filter(kw => !category.keywords.includes(kw));
    category.keywords.push(...newKeywords);
    await category.save();

    transaction.categoryId = category._id;
    transaction.confidence = 1.0;  // User confirmed
    await transaction.save();

    res.json({ message: 'Đã sửa phân loại thành công.' });
};

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

        const { amount, type, date, description, isShared, categoryId } = value;
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

        res.json({ message: 'Tạo giao dịch thành công', transaction });
    } catch (err) {
        console.error('Create transaction error:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

// update a transaction
export const updateTransaction = async (req, res) => {
    try {
        const { transactionId, amount, type, date, description, isShared, categoryId } = req.body;
        const transaction = await Transaction.findById(transactionId);
        if (!transaction || transaction.userId.toString() !== req.userId) return res.status(404).json({ error: 'Not found' });

        transaction.amount = amount;
        transaction.type = type;
        transaction.date = date;
        transaction.description = description;
        transaction.isShared = isShared;
        transaction.categoryId = categoryId;
        await transaction.save();

        res.json({ message: 'Cập nhật giao dịch thành công', transaction });
    } catch (err) {
        console.error('Update transaction error:', err);
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

        const match = {
            $or: [
                { userId: user._id },
                { familyId: user.familyId, isShared: true }
            ]
        };

        if (type && ['income', 'expense'].includes(type)) match.type = type;
        if (startDate) match.date = { ...match.date, $gte: new Date(startDate) };
        if (endDate) match.date = { ...match.date, $lte: new Date(endDate) };
        if (search) {
            const regex = { $regex: search.trim(), $options: 'i' };
            match.$or = [
                { description: regex },
                { voiceText: regex },
                { ocrText: regex }
            ];
        }

        const [transactions, total] = await Promise.all([
            Transaction.find(match)
                .populate('categoryId', 'name icon color')
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
                    icon: plain.categoryId.icon || 'HelpCircle',
                    color: plain.categoryId.color || '#94a3b8'
                } : {
                    name: 'Không xác định',
                    icon: 'HelpCircle',
                    color: '#94a3b8'
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
