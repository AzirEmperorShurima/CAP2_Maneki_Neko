// controllers/budgetController.js
import Budget from '../models/budget.js';
import Family from '../models/family.js';
import dayjs from 'dayjs';
import { validateCreateBudget, validateUpdateBudget, validateGetBudgetsQuery } from '../validations/budget.js';
import { calculateBudgetPeriod, syncChildBudgets } from '../utils/budget.js';

export const createBudget = async (req, res) => {
    try {
        const { error, value } = validateCreateBudget(req.body);
        if (error) {
            return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
        }
        const { type, amount, categoryId, isShared, familyId: bodyFamilyId } = value;

        // Nếu tạo ngân sách chia sẻ, kiểm tra quyền admin của family
        let familyId = null;
        if (isShared) {
            const user = await Family.findOne({ _id: req.body.familyId, adminId: req.userId });
            if (!user) {
                return res.status(403).json({ error: 'Chỉ admin của gia đình mới có thể tạo ngân sách chia sẻ' });
            }
            familyId = bodyFamilyId;
        }

        // Tính toán periodStart và periodEnd
        const { periodStart, periodEnd } = calculateBudgetPeriod(type);

        const budget = new Budget({
            userId: req.userId,
            type,
            amount,
            categoryId: categoryId || null,
            familyId: familyId || null,
            isShared: isShared || false,
            periodStart,
            periodEnd,
            spentAmount: 0
        })
        await budget.save();
        if (type === 'monthly') {
            await syncChildBudgets(budget);
        }
        const populatedBudget = await Budget.findById(budget._id)
            .populate('parentBudgetId categoryId');

        res.status(201).json({
            message: 'Tạo ngân sách thành công',
            budget: populatedBudget
        });
    } catch (error) {
        console.error('Lỗi tạo ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getBudgets = async (req, res) => {
    try {
        const { error, value } = validateGetBudgetsQuery(req.query);
        if (error) {
            return res.status(400).json({
                error: 'Invalid query',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }

        const { isActive, isShared } = value;
        const filter = { userId: req.userId };


        const now = dayjs();
        filter.$and = [
            { periodStart: { $lte: now.toDate() } },
            { periodEnd: { $gte: now.toDate() } }
        ];

        if (isActive !== undefined) {
            filter.isActive = isActive === 'true';
        }

        if (isShared !== undefined) {
            filter.isShared = isShared === 'true';
        }

        const budgets = await Budget.find(filter)
            .populate('categoryId parentBudgetId')
            .sort({ type: 1, periodStart: -1 });

        res.json({ budgets });
    } catch (error) {
        console.error('Lỗi lấy danh sách ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getBudgetById = async (req, res) => {
    try {
        const { id } = req.params;
        const budget = await Budget.findOne({ _id: id, userId: req.userId })
            .populate('categoryId parentBudgetId');

        if (!budget) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách' });
        }

        res.json({ budget });
    } catch (error) {
        console.error('Lỗi lấy thông tin ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const updateBudget = async (req, res) => {
    try {
        const { id } = req.params;
        const { error, value } = validateUpdateBudget(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }

        const { amount, categoryId, isActive, isShared, familyId: bodyFamilyId } = value;

        const budget = await Budget.findOne({ _id: id, userId: req.userId });
        if (!budget) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách' });
        }

        // Xử lý thay đổi trạng thái chia sẻ
        if (isShared !== undefined && isShared !== budget.isShared) {
            if (isShared) {
                const family = await Family.findOne({ _id: bodyFamilyId, adminId: req.userId });
                if (!family) {
                    return res.status(403).json({ error: 'Chỉ admin của gia đình mới có thể chia sẻ ngân sách' });
                }
                budget.familyId = bodyFamilyId;
            } else {
                budget.familyId = null;
            }
            budget.isShared = isShared;
        }

        // Cập nhật các trường được phép thay đổi
        if (amount !== undefined && amount > 0) {
            budget.amount = amount;
        }

        if (categoryId !== undefined) {
            budget.categoryId = categoryId || null;
        }

        if (isActive !== undefined) {
            budget.isActive = isActive;
        }

        await budget.save();

        const populatedBudget = await Budget.findById(budget._id)
            .populate('categoryId parentBudgetId');

        res.json({
            message: 'Cập nhật ngân sách thành công',
            budget: populatedBudget
        });
    } catch (error) {
        console.error('Lỗi cập nhật ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const deleteBudget = async (req, res) => {
    try {
        const { id } = req.params;

        // Thực hiện xóa budget khỏi database
        const result = await Budget.deleteOne({ _id: id, userId: req.userId });

        if (result.deletedCount === 0) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách hoặc không có quyền xóa' });
        }

        res.json({ message: 'Đã xóa ngân sách thành công' });
    } catch (error) {
        console.error('Lỗi xóa ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const renewBudget = async (req, res) => {
    try {
        const { id } = req.params;
        const budget = await Budget.findOne({ _id: id, userId: req.userId });

        if (!budget) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách' });
        }

        // Kiểm tra xem budget có còn trong kỳ hiện tại không
        const now = dayjs();
        const isCurrentPeriodValid = now.isBetween(budget.periodStart, budget.periodEnd, null, '[]');

        if (isCurrentPeriodValid) {
            return res.status(400).json({
                error: 'Ngân sách hiện tại vẫn còn trong kỳ, không cần gia hạn'
            });
        }

        // Tạo kỳ mới cho budget
        const { periodStart, periodEnd } = calculateBudgetPeriod(budget.type);

        // Tạo một budget mới với cùng thông tin nhưng kỳ mới
        const newBudget = new Budget({
            userId: budget.userId,
            type: budget.type,
            amount: budget.amount,
            categoryId: budget.categoryId,
            parentBudgetId: budget.parentBudgetId,
            isDerived: budget.isDerived,
            familyId: budget.familyId,
            isShared: budget.isShared,
            periodStart,
            periodEnd,
            spentAmount: 0,
            isActive: true
        });

        await newBudget.save();

        // Xóa budget cũ sau khi đã tạo budget mới thành công
        await Budget.deleteOne({ _id: budget._id });

        const populatedNewBudget = await Budget.findById(newBudget._id)
            .populate('categoryId parentBudgetId');

        res.json({
            message: 'Đã gia hạn ngân sách cho kỳ mới',
            budget: populatedNewBudget
        });
    } catch (error) {
        console.error('Lỗi gia hạn ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getActiveBudgetsForCurrentPeriod = async (req, res) => {
    try {
        const now = dayjs();
        const budgets = await Budget.find({
            userId: req.userId,
            isActive: true,
            periodStart: { $lte: now.toDate() },
            periodEnd: { $gte: now.toDate() }
        })
            .populate('categoryId parentBudgetId')
            .sort({ type: 1 });

        res.json({ budgets });
    } catch (error) {
        console.error('Lỗi lấy danh sách ngân sách hiện tại:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};