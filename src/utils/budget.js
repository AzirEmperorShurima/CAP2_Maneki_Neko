// utils/budget.js
import Budget from '../models/budget.js';
import Goal from '../models/goal.js';
import dayjs from 'dayjs';
import isSameOrAfter from 'dayjs/plugin/isSameOrAfter.js';
import isSameOrBefore from 'dayjs/plugin/isSameOrBefore.js';

dayjs.extend(isSameOrAfter);
dayjs.extend(isSameOrBefore);

/**
 * Cập nhật spentAmount cho các budget liên quan đến một giao dịch chi tiêu
 */
export const updateBudgetSpentAmounts = async (userId, transaction) => {
    if (transaction.type !== 'expense') return;

    const transDate = dayjs(transaction.date);

    // Tìm tất cả budget đang hoạt động và thuộc kỳ của giao dịch
    const budgets = await Budget.find({
        $or: [
            { userId, familyId: null },
            { familyId: transaction.familyId }
        ],
        isActive: true,
        periodStart: { $lte: transDate.toDate() },
        periodEnd: { $gte: transDate.toDate() }
    });

    for (const budget of budgets) {
        // Kiểm tra xem giao dịch có thuộc budget này không
        const shouldIncludeTransaction = !budget.categoryId ||
            budget.categoryId.toString() === transaction.categoryId.toString();

        if (shouldIncludeTransaction) {
            budget.spentAmount += transaction.amount;
            await budget.save();
        }
    }
};

/**
 * Kiểm tra và tạo cảnh báo ngân sách cho một giao dịch
 */
export const checkBudgetWarning = async (userId, transaction) => {
    if (transaction.type !== 'expense') return '';

    const warnings = [];
    const transDate = dayjs(transaction.date);

    // Tìm tất cả budget đang hoạt động và thuộc kỳ của giao dịch
    const budgets = await Budget.find({
        $or: [
            { userId, familyId: null },
            { familyId: transaction.familyId }
        ],
        isActive: true,
        periodStart: { $lte: transDate.toDate() },
        periodEnd: { $gte: transDate.toDate() }
    });

    for (const budget of budgets) {
        const shouldIncludeTransaction = !budget.categoryId ||
            budget.categoryId.toString() === transaction.categoryId.toString();

        if (shouldIncludeTransaction) {
            const projectedSpent = budget.spentAmount + transaction.amount;
            const percentUsed = budget.amount > 0 ? (projectedSpent / budget.amount) * 100 : 0;

            const periodName = budget.type === 'daily' ? 'ngày' :
                budget.type === 'weekly' ? 'tuần' : 'tháng';

            if (projectedSpent > budget.amount) {
                warnings.push(`Vượt ngân sách ${periodName}: ${projectedSpent.toLocaleString()}đ / ${budget.amount.toLocaleString()}đ`);
            } else if (percentUsed >= 90) {
                warnings.push(`Sắp vượt ngân sách ${periodName}: ${Math.round(percentUsed)}% đã sử dụng`);
            } else if (percentUsed >= 80) {
                warnings.push(`Đã sử dụng ${Math.round(percentUsed)}% ngân sách ${periodName}`);
            }

            // Cảnh báo nếu giao dịch chiếm tỷ lệ lớn trong ngân sách
            if (transaction.amount >= budget.amount * 0.6) {
                warnings.push(`Chi lớn: ${transaction.amount.toLocaleString()}đ chiếm ${(transaction.amount / budget.amount * 100).toFixed(0)}% ngân sách ${periodName}`);
            }
        }
    }

    return warnings.length > 0 ? warnings.join('\n') : '';
};

/**
 * Tìm budget hiệu quả cho một ngày cụ thể và danh mục
 */
export const getEffectiveBudgetForDate = async (userId, categoryId, targetDate) => {
    const targetDayjs = dayjs(targetDate);

    // Tìm theo thứ tự ưu tiên: monthly -> weekly -> daily
    const budgetTypes = ['monthly', 'weekly', 'daily'];

    for (const type of budgetTypes) {
        let budget;

        // Tìm budget cụ thể cho danh mục trước
        if (categoryId) {
            budget = await Budget.findOne({
                userId,
                type,
                categoryId,
                isActive: true,
                periodStart: { $lte: targetDayjs.toDate() },
                periodEnd: { $gte: targetDayjs.toDate() }
            });
        }

        // Nếu không có budget cụ thể cho danh mục, tìm budget tổng quát
        if (!budget) {
            budget = await Budget.findOne({
                userId,
                type,
                categoryId: null,
                isActive: true,
                periodStart: { $lte: targetDayjs.toDate() },
                periodEnd: { $gte: targetDayjs.toDate() }
            });
        }

        if (budget) return budget;
    }

    return null;
};

/**
 * Tự động tạo hoặc cập nhật budget con dựa trên budget cha
 */
export const syncChildBudgets = async (parentBudget) => {
    const userId = parentBudget.userId;
    const childTypes = [];

    // Xác định các loại budget con cần tạo
    if (parentBudget.type === 'monthly') {
        childTypes.push('weekly', 'daily');
    } else if (parentBudget.type === 'weekly') {
        childTypes.push('daily');
    }

    for (const childType of childTypes) {
        const existingChild = await Budget.findOne({
            userId,
            type: childType,
            categoryId: parentBudget.categoryId,
            parentBudgetId: parentBudget._id,
            isActive: true
        });

        const { periodStart, periodEnd } = calculateBudgetPeriod(childType);

        // Tính số tiền cho budget con dựa trên budget cha
        let childAmount;
        if (childType === 'daily') {
            childAmount = parentBudget.amount / dayjs(parentBudget.periodEnd).diff(parentBudget.periodStart, 'day');
        } else if (childType === 'weekly') {
            childAmount = parentBudget.amount / 4; // Khoảng 4 tuần trong một tháng
        }

        if (existingChild) {
            // Cập nhật budget con hiện có nếu cần
            const shouldUpdate = existingChild.amount < childAmount ||
                !dayjs().isBetween(existingChild.periodStart, existingChild.periodEnd, null, '[]');

            if (shouldUpdate) {
                existingChild.amount = Math.max(childAmount, existingChild.amount);
                existingChild.periodStart = periodStart;
                existingChild.periodEnd = periodEnd;
                await existingChild.save();
            }
        } else {
            // Tạo budget con mới
            const childBudget = new Budget({
                userId,
                type: childType,
                amount: childAmount,
                parentBudgetId: parentBudget._id,
                isDerived: true,
                categoryId: parentBudget.categoryId,
                periodStart,
                periodEnd,
                familyId: parentBudget.familyId,
                isShared: parentBudget.isShared,
                spentAmount: 0
            });
            await childBudget.save();
        }
    }
};

/**
 * Xóa các budget đã hết kỳ
 */
export const deleteExpiredBudgets = async () => {
    const now = new Date();
    const result = await Budget.deleteMany({
        isActive: true,
        periodEnd: { $lt: now }
    });

    return result.deletedCount;
};

/**
 * Tính toán period cho budget theo loại
 */
export const calculateBudgetPeriod = (type, referenceDate = null) => {
    const now = referenceDate ? dayjs(referenceDate) : dayjs();

    let periodStart, periodEnd;

    switch (type) {
        case 'daily':
            periodStart = now.startOf('day').toDate();
            periodEnd = now.endOf('day').toDate();
            break;
        case 'weekly':
            periodStart = now.startOf('week').toDate();
            periodEnd = now.endOf('week').toDate();
            break;
        case 'monthly':
            periodStart = now.startOf('month').toDate();
            periodEnd = now.endOf('month').toDate();
            break;
        default:
            throw new Error('Loại kỳ không hợp lệ');
    }

    return { periodStart, periodEnd };
};

/**
 * Lấy tất cả budget đang hoạt động trong kỳ hiện tại
 */
export const getActiveBudgetsForCurrentPeriod = async (userId, familyId = null) => {
    const now = dayjs();
    const filter = {
        isActive: true,
        periodStart: { $lte: now.toDate() },
        periodEnd: { $gte: now.toDate() }
    };

    if (familyId) {
        filter.$or = [
            { userId, familyId: null },
            { familyId }
        ];
    } else {
        filter.userId = userId;
    }

    return await Budget.find(filter).populate('categoryId parentBudgetId');
};

/**
 * Cập nhật tiến độ goal từ transaction (giữ nguyên logic cũ)
 */
export const updateGoalProgressFromTransaction = async (transaction) => {
    try {
        const goals = await Goal.find({
            userId: transaction.userId,
            status: 'active',
            isActive: true,
            associatedWallets: transaction.walletId
        });

        if (goals.length === 0) return null;

        const messages = [];
        for (const goal of goals) {
            const oldProgress = goal.currentProgress;
            const newProgress = oldProgress + transaction.amount;
            const result = await goal.updateProgress(newProgress);

            const percent = Math.round(result.progressPercentage);

            if (result.isCompleted) {
                messages.push(`CHÚC MỪNG! Bạn đã hoàn thành mục tiêu "${goal.name}"!`);
            } else if (percent >= 90) {
                messages.push(`Mục tiêu "${goal.name}": Đã đạt ${percent}%! Sắp xong rồi, cố lên!`);
            } else if (percent >= 75 && oldProgress < goal.targetAmount * 0.75) {
                messages.push(`Mục tiêu "${goal.name}": Đã đạt ${percent}%`);
            }
        }

        return messages.length > 0 ? messages.join('\n') : null;
    } catch (error) {
        console.error('Lỗi cập nhật goal:', error);
        return null;
    }
};