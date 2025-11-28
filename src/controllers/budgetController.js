// controllers/budgetController.js
import Budget from '../models/budget.js';
import Family from '../models/family.js';
import dayjs from 'dayjs';

export const createBudget = async (req, res) => {
    try {
        const { type, amount, categoryId, isShared } = req.body;

        if (!type || !amount) {
            return res.status(400).json({ error: 'Loại kỳ và số tiền ngân sách là bắt buộc' });
        }

        if (!['daily', 'weekly', 'monthly'].includes(type)) {
            return res.status(400).json({ error: 'Loại kỳ không hợp lệ. Phải là daily, weekly hoặc monthly' });
        }

        if (amount <= 0) {
            return res.status(400).json({ error: 'Số tiền ngân sách phải lớn hơn 0' });
        }

        // Nếu tạo ngân sách chia sẻ, kiểm tra quyền admin của family
        let familyId = null;
        if (isShared) {
            const user = await Family.findOne({ _id: req.body.familyId, adminId: req.userId });
            if (!user) {
                return res.status(403).json({ error: 'Chỉ admin của gia đình mới có thể tạo ngân sách chia sẻ' });
            }
            familyId = req.body.familyId;
        }

        const budget = new Budget({
            userId: req.userId,
            type,
            amount,
            categoryId: categoryId || null,
            familyId,
            isShared: isShared || false
        });

        // Tự động tính toán periodStart và periodEnd
        const now = dayjs();
        let periodStart, periodEnd;

        if (type === 'daily') {
            periodStart = now.startOf('day').toDate();
            periodEnd = now.endOf('day').toDate();
        } else if (type === 'weekly') {
            periodStart = now.startOf('week').toDate();
            periodEnd = now.endOf('week').toDate();
        } else {
            periodStart = now.startOf('month').toDate();
            periodEnd = now.endOf('month').toDate();
        }

        budget.periodStart = periodStart;
        budget.periodEnd = periodEnd;

        await budget.save();

        const populatedBudget = await Budget.findById(budget._id);

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
        const { isActive, isShared } = req.query;
        const filter = { userId: req.userId };

        if (isActive !== undefined) {
            filter.isActive = isActive === 'true';
        }

        if (isShared !== undefined) {
            filter.isShared = isShared === 'true';
        }

        const budgets = await Budget.find(filter).sort({ createdAt: -1 });

        res.json({ budgets });
    } catch (error) {
        console.error('Lỗi lấy danh sách ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getBudgetById = async (req, res) => {
    try {
        const { id } = req.params;
        const budget = await Budget.findOne({ _id: id, userId: req.userId });

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
        const { type, amount, categoryId, isActive, isShared } = req.body;

        const budget = await Budget.findOne({ _id: id, userId: req.userId });
        if (!budget) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách' });
        }

        // Nếu thay đổi isShared, cần kiểm tra quyền
        if (isShared !== undefined && isShared !== budget.isShared) {
            if (isShared) {
                const family = await Family.findOne({ _id: req.body.familyId, adminId: req.userId });
                if (!family) {
                    return res.status(403).json({ error: 'Chỉ admin của gia đình mới có thể chia sẻ ngân sách' });
                }
                budget.familyId = req.body.familyId;
            } else {
                budget.familyId = null;
            }
            budget.isShared = isShared;
        }

        if (type !== undefined) {
            if (!['daily', 'weekly', 'monthly'].includes(type)) {
                return res.status(400).json({ error: 'Loại kỳ không hợp lệ' });
            }
            budget.type = type;

            // Cập nhật lại periodStart và periodEnd khi thay đổi type
            const now = dayjs();
            let periodStart, periodEnd;

            if (type === 'daily') {
                periodStart = now.startOf('day').toDate();
                periodEnd = now.endOf('day').toDate();
            } else if (type === 'weekly') {
                periodStart = now.startOf('week').toDate();
                periodEnd = now.endOf('week').toDate();
            } else {
                periodStart = now.startOf('month').toDate();
                periodEnd = now.endOf('month').toDate();
            }

            budget.periodStart = periodStart;
            budget.periodEnd = periodEnd;
        }

        if (amount !== undefined) {
            if (amount <= 0) {
                return res.status(400).json({ error: 'Số tiền ngân sách phải lớn hơn 0' });
            }
            budget.amount = amount;
        }

        if (categoryId !== undefined) {
            budget.categoryId = categoryId || null;
        }

        if (isActive !== undefined) {
            budget.isActive = isActive;
        }

        await budget.save();

        const populatedBudget = await Budget.findById(budget._id);
        res.json({ message: 'Cập nhật ngân sách thành công', budget: populatedBudget });
    } catch (error) {
        console.error('Lỗi cập nhật ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const deleteBudget = async (req, res) => {
    try {
        const { id } = req.params;
        const budget = await Budget.findOne({ _id: id, userId: req.userId });

        if (!budget) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách' });
        }

        await Budget.deleteOne({ _id: id, userId: req.userId });
        res.json({ message: 'Đã xóa ngân sách' });
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

        if (!budget.isActive) {
            return res.status(400).json({ error: 'Không thể gia hạn ngân sách đã bị vô hiệu hóa' });
        }

        // Tính toán kỳ mới
        const now = dayjs();
        let periodStart, periodEnd;

        if (budget.type === 'daily') {
            periodStart = now.startOf('day').toDate();
            periodEnd = now.endOf('day').toDate();
        } else if (budget.type === 'weekly') {
            periodStart = now.startOf('week').toDate();
            periodEnd = now.endOf('week').toDate();
        } else {
            periodStart = now.startOf('month').toDate();
            periodEnd = now.endOf('month').toDate();
        }

        budget.periodStart = periodStart;
        budget.periodEnd = periodEnd;

        await budget.save();

        const updatedBudget = await Budget.findById(budget._id);
        res.json({
            message: 'Đã gia hạn ngân sách cho kỳ mới',
            budget: updatedBudget
        });
    } catch (error) {
        console.error('Lỗi gia hạn ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};