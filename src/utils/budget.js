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

    // Query base
    const query = {
        isActive: true,
        periodStart: { $lte: transDate.toDate() },
        periodEnd: { $gte: transDate.toDate() }
    };

    // Xác định scope (personal/family)
    if (transaction.isShared && transaction.familyId) {
        query.familyId = transaction.familyId;
        query.isShared = true;
    } else {
        query.userId = userId;
        query.$or = [
            { familyId: null },
            { familyId: { $exists: false } }
        ];
    }

    // Tìm tất cả budgets matching, sort by createdAt descending (newest first)
    const allBudgets = await Budget.find(query).sort({ createdAt: -1 });

    // ✅ Deduplicate: chỉ lấy budget mới nhất cho mỗi group
    const budgetGroups = new Map();

    for (const budget of allBudgets) {
        const categoryKey = budget.categoryId?.toString() || 'null';
        const parentKey = budget.parentBudgetId?.toString() || 'null';
        const groupKey = `${budget.type}_${categoryKey}_${parentKey}`;

        // Chỉ lấy budget đầu tiên (newest) cho mỗi group
        if (!budgetGroups.has(groupKey)) {
            budgetGroups.set(groupKey, budget);
        }
    }

    const budgetsToUpdate = Array.from(budgetGroups.values());

    console.log(`📊 Found ${allBudgets.length} budgets, deduped to ${budgetsToUpdate.length}`);

    // Batch update
    const bulkOps = [];

    for (const budget of budgetsToUpdate) {
        // So sánh categoryId an toàn
        const transactionCategoryId = transaction.categoryId?.toString();
        const budgetCategoryId = budget.categoryId?.toString();

        const shouldInclude = !budgetCategoryId ||
            (transactionCategoryId && budgetCategoryId === transactionCategoryId);

        if (shouldInclude) {
            // Hỗ trợ cả số dương (add) và số âm (refund/delete)
            const newSpent = Math.max(0, budget.spentAmount + transaction.amount);

            bulkOps.push({
                updateOne: {
                    filter: { _id: budget._id },
                    update: { $set: { spentAmount: newSpent } }
                }
            });
        }
    }

    if (bulkOps.length > 0) {
        await Budget.bulkWrite(bulkOps);
    }

    return {
        totalFound: allBudgets.length,
        updated: bulkOps.length,
        deduped: allBudgets.length - budgetsToUpdate.length
    };
};


/**
 * Kiểm tra và tạo cảnh báo ngân sách cho một giao dịch
 */
export const checkBudgetWarning = async (userId, transaction) => {
    if (transaction.type !== 'expense') return null;

    const warnings = [];
    const transDate = dayjs(transaction.date);

    // Query base
    const query = {
        isActive: true,
        periodStart: { $lte: transDate.toDate() },
        periodEnd: { $gte: transDate.toDate() }
    };

    // Xác định scope
    if (transaction.isShared && transaction.familyId) {
        query.familyId = transaction.familyId;
        query.isShared = true;
    } else {
        query.userId = userId;
        query.$or = [
            { familyId: null },
            { familyId: { $exists: false } }
        ];
    }

    // Populate và sort by createdAt descending
    const allBudgets = await Budget.find(query)
        .populate('categoryId', 'name')
        .sort({ createdAt: -1 });

    // ✅ Deduplicate
    const budgetGroups = new Map();

    for (const budget of allBudgets) {
        const categoryKey = budget.categoryId?._id?.toString() || 'null';
        const parentKey = budget.parentBudgetId?.toString() || 'null';
        const groupKey = `${budget.type}_${categoryKey}_${parentKey}`;

        if (!budgetGroups.has(groupKey)) {
            budgetGroups.set(groupKey, budget);
        }
    }

    const budgetsToCheck = Array.from(budgetGroups.values());

    console.log(`⚠️ Checking warnings for ${budgetsToCheck.length} budgets (deduped from ${allBudgets.length})`);

    for (const budget of budgetsToCheck) {
        // So sánh categoryId an toàn
        const transactionCategoryId = transaction.categoryId?.toString();
        const budgetCategoryId = budget.categoryId?._id?.toString();

        const shouldInclude = !budgetCategoryId ||
            (transactionCategoryId && budgetCategoryId === transactionCategoryId);

        if (shouldInclude) {
            const currentSpent = budget.spentAmount;
            const budgetAmount = budget.amount;
            const remaining = budgetAmount - currentSpent;
            const percentUsed = budgetAmount > 0 ?
                (currentSpent / budgetAmount) * 100 : 0;

            const categoryName = budget.categoryId?.name || 'Tổng chi tiêu';
            const periodName = {
                'daily': 'ngày',
                'weekly': 'tuần',
                'monthly': 'tháng'
            }[budget.type] || budget.type;

            const warningBase = {
                budgetId: budget._id,
                budgetType: budget.type,
                category: categoryName,
                spent: currentSpent,
                total: budgetAmount,
                remaining,
                percentUsed: Math.round(percentUsed)
            };

            // Phân loại warning
            if (currentSpent > budgetAmount) {
                warnings.push({
                    ...warningBase,
                    level: 'error',
                    type: 'over_budget',
                    message: `🚨 Vượt ngân sách ${categoryName} (${periodName}): ${currentSpent.toLocaleString()}đ / ${budgetAmount.toLocaleString()}đ`,
                    overage: currentSpent - budgetAmount
                });
            } else if (percentUsed >= 95) {
                warnings.push({
                    ...warningBase,
                    level: 'critical',
                    type: 'near_limit',
                    message: `⚠️ Gần vượt ngân sách ${categoryName} (${periodName}): ${Math.round(percentUsed)}% (còn ${remaining.toLocaleString()}đ)`
                });
            } else if (percentUsed >= 80) {
                warnings.push({
                    ...warningBase,
                    level: 'warning',
                    type: 'high_usage',
                    message: `⚡ Đã dùng ${Math.round(percentUsed)}% ngân sách ${categoryName} (${periodName})`
                });
            } else if (percentUsed >= 50) {
                warnings.push({
                    ...warningBase,
                    level: 'info',
                    type: 'half_used',
                    message: `💡 Đã dùng ${Math.round(percentUsed)}% ngân sách ${categoryName} (${periodName})`
                });
            }

            // Cảnh báo giao dịch lớn
            if (transaction.amount >= budgetAmount * 0.5) {
                warnings.push({
                    ...warningBase,
                    level: 'warning',
                    type: 'large_transaction',
                    message: `💰 Chi lớn: ${transaction.amount.toLocaleString()}đ chiếm ${Math.round(transaction.amount / budgetAmount * 100)}% ngân sách ${periodName}`,
                    transactionPercent: Math.round(transaction.amount / budgetAmount * 100)
                });
            }
        }
    }

    return warnings.length > 0 ? warnings : null;
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