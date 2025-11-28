// utils/budget.js
import Transaction from '../models/transaction.js';
import Budget from '../models/budget.js';
import Goal from '../models/goal.js';
import Category from '../models/category.js';
import dayjs from 'dayjs';
import isSameOrAfter from 'dayjs/plugin/isSameOrAfter.js';
import isSameOrBefore from 'dayjs/plugin/isSameOrBefore.js';
import weekday from 'dayjs/plugin/weekday.js';
import weekOfYear from 'dayjs/plugin/weekOfYear.js';

dayjs.extend(isSameOrAfter);
dayjs.extend(isSameOrBefore);
dayjs.extend(weekday);
dayjs.extend(weekOfYear);

/**
 * Kiểm tra cảnh báo ngân sách + cập nhật tiến độ goal
 * @param {String} userId
 * @param {Object} transaction - transaction đã lưu (có walletId nếu cần)
 * @returns {String} - chuỗi cảnh báo (có thể rỗng)
 */
export const checkBudgetWarning = async (userId, transaction) => {
    let warnings = [];

    // ===== 1. CẢNH BÁO NGÂN SÁCH (chỉ cho chi tiêu) =====
    if (transaction.type === 'expense') {
        const budgetWarning = await getBudgetWarning(userId, transaction);
        if (budgetWarning) warnings.push(budgetWarning);
    }

    // ===== 2. CẬP NHẬT TIẾN ĐỘ GOAL (chỉ cho thu nhập từ ví liên kết) =====
    if (transaction.type === 'income' && transaction.walletId) {
        const goalMessage = await updateGoalProgressFromTransaction(transaction);
        if (goalMessage) warnings.push(goalMessage);
    }

    return warnings.length > 0 ? warnings.join('\n') : '';
};

// ------------------- Hàm phụ trợ -------------------

async function getBudgetWarning(userId, transaction) {
    const transDate = dayjs(transaction.date);
    const amount = transaction.amount;
    const familyId = transaction.familyId;

    // Lấy tất cả budget (cá nhân + gia đình)
    const budgets = await Budget.find({
        $or: [
            { userId, familyId: null },
            { familyId: familyId || null }
        ]
    }).lean();

    if (budgets.length === 0) return '';

    // Tính tổng chi tiêu theo từng kỳ
    const periodTotals = await calculatePeriodTotals(userId, transDate, familyId);

    // Lấy tên danh mục
    const categoryNameMap = await getCategoryNameMap(budgets);

    const warnings = [];
    for (const budget of budgets) {
        const periodData = periodTotals.find(p => p.period === budget.type);
        if (!periodData) continue;

        const currentTotal = (budget.categoryId
            ? (periodData.totalMap[budget.categoryId?.toString()] || 0)
            : periodData.totalMap.overall || 0) + amount;

        const percentUsed = budget.amount > 0 ? (currentTotal / budget.amount) * 100 : 0;
        const categoryName = budget.categoryId
            ? categoryNameMap[budget.categoryId.toString()] || 'Không xác định'
            : 'tổng chi';
        const periodVi = budget.type === 'daily' ? 'ngày' : budget.type === 'weekly' ? 'tuần' : 'tháng';

        if (currentTotal > budget.amount) {
            warnings.push(`Vượt ngân sách ${periodVi} ${categoryName}: ${currentTotal.toLocaleString()}đ / ${budget.amount.toLocaleString()}đ`);
        } else if (percentUsed >= 90) {
            warnings.push(`Sắp vượt ngân sách ${periodVi} ${categoryName}: ${Math.round(percentUsed)}% dùng rồi!`);
        } else if (percentUsed >= 80) {
            warnings.push(`Đã dùng ${Math.round(percentUsed)}% ngân sách ${periodVi} ${categoryName}`);
        }

        if (amount >= budget.amount * 0.6) {
            warnings.push(`Chi lớn: ${amount.toLocaleString()}đ chiếm ${(amount / budget.amount * 100).toFixed(0)}% ngân sách ${periodVi}!`);
        }
    }

    return warnings.length > 0 ? warnings.join('\n') : '';
}

async function calculatePeriodTotals(userId, transDate, familyId) {
    const periods = ['daily', 'weekly', 'monthly'];
    const pipelines = periods.map(period => {
        let start, end;
        if (period === 'daily') {
            start = transDate.startOf('day');
            end = transDate.endOf('day');
        } else if (period === 'weekly') {
            start = transDate.startOf('week');
            end = transDate.endOf('week').endOf('day');
        } else {
            start = transDate.startOf('month');
            end = transDate.endOf('month');
        }

        const match = {
            type: 'expense',
            date: { $gte: start.toDate(), $lte: end.toDate() },
            $or: [{ userId }, { familyId }]
        };

        return {
            period,
            pipeline: [
                { $match: match },
                { $group: { _id: '$categoryId', total: { $sum: '$amount' } } }
            ]
        };
    });

    const results = await Promise.all(
        pipelines.map(async ({ period, pipeline }) => {
            const data = await Transaction.aggregate(pipeline);
            const totalMap = {};
            let overall = 0;
            data.forEach(r => {
                totalMap[r._id?.toString() || 'overall'] = r.total;
                overall += r.total;
            });
            totalMap.overall = overall;
            return { period, totalMap };
        })
    );

    return results;
}

async function getCategoryNameMap(budgets) {
    const categoryIds = budgets.map(b => b.categoryId).filter(Boolean);
    if (categoryIds.length === 0) return {};
    const categories = await Category.find({ _id: { $in: categoryIds } }).lean();
    const map = {};
    categories.forEach(cat => map[cat._id.toString()] = cat.name);
    return map;
}

async function updateGoalProgressFromTransaction(transaction) {
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
}