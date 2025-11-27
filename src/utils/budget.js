import Transaction from '../models/transaction.js';
import Budget from '../models/budget.js';
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
 * Kiểm tra cảnh báo ngân sách + tiến độ goal
 * @param {String} userId
 * @param {Object} transaction - đã save hoặc chưa save đều được
 * @returns {String} - chuỗi cảnh báo (có thể rỗng)
 */
export const checkBudgetWarning = async (userId, transaction) => {
    if (!transaction || transaction.type !== 'expense') {

        if (transaction?.type === 'income') {
            await updateGoalProgress(userId, transaction.amount, transaction.familyId);
        }
        return '';
    }

    const transDate = dayjs(transaction.date);
    const amount = transaction.amount;
    const categoryId = transaction.categoryId;
    const familyId = transaction.familyId;

    // 1. Lấy tất cả budget liên quan (cả cá nhân + gia đình)
    const budgetFilter = {
        $or: [
            { userId, familyId: null },
            { familyId: familyId || null }
        ]
    };

    const budgets = await Budget.find(budgetFilter).lean();

    if (budgets.length === 0) return '';

    const periods = ['daily', 'weekly', 'monthly'];
    const matchStages = periods.map(period => {
        let start, end;
        if (period === 'daily') {
            start = transDate.startOf('day');
            end = transDate.endOf('day');
        } else if (period === 'weekly') {
            start = transDate.startOf('week'); // Thứ 2
            end = transDate.endOf('week').endOf('day');
        } else {
            start = transDate.startOf('month');
            end = transDate.endOf('month');
        }

        const baseMatch = {
            type: 'expense',
            date: { $gte: start.toDate(), $lte: end.toDate() },
        };

        // Cá nhân hoặc gia đình
        const userOrFamilyMatch = familyId
            ? { $or: [{ userId }, { familyId }] }
            : { userId };

        return {
            period,
            start,
            end,
            pipeline: [
                {
                    $match: {
                        ...baseMatch,
                        ...userOrFamilyMatch,
                    },
                },
                {
                    $group: {
                        _id: '$categoryId',
                        total: { $sum: '$amount' },
                    },
                },
            ],
        };
    });

    const aggregatePromises = matchStages.map(async ({ period, pipeline }) => {
        const results = await Transaction.aggregate(pipeline);
        const totalMap = {};
        let overallTotal = 0;

        results.forEach(r => {
            totalMap[r._id?.toString() || 'overall'] = r.total;
            overallTotal += r.total;
        });

        totalMap.overall = overallTotal;

        return { period, totalMap };
    });

    const periodTotals = await Promise.all(aggregatePromises);

    const categoryIds = budgets.map(b => b.categoryId).filter(Boolean);
    const categories = await Category.find({ _id: { $in: categoryIds } }).lean();
    const categoryNameMap = {};
    categories.forEach(cat => {
        categoryNameMap[cat._id.toString()] = cat.name;
    });

    // 4. Tạo cảnh báo
    const warnings = [];

    for (const budget of budgets) {
        const periodData = periodTotals.find(p => p.period === budget.type);
        if (!periodData) continue;

        const currentTotal =
            (budget.categoryId
                ? periodData.totalMap[budget.categoryId?.toString()] || 0
                : periodData.totalMap.overall || 0) + amount;

        const budgetAmount = budget.amount;
        const percentUsed = budgetAmount > 0 ? (currentTotal / budgetAmount) * 100 : 0;

        const categoryName = budget.categoryId
            ? categoryNameMap[budget.categoryId.toString()] || 'Không xác định'
            : 'tổng chi';

        const periodVi = budget.type === 'daily' ? 'ngày' : budget.type === 'weekly' ? 'tuần' : 'tháng';

        if (currentTotal > budgetAmount) {
            warnings.push(`Vượt ngân sách ${periodVi} ${categoryName}: ${currentTotal.toLocaleString()}đ / ${budgetAmount.toLocaleString()}đ`);
        } else if (percentUsed >= 90) {
            warnings.push(`Sắp vượt ngân sách ${periodVi} ${categoryName}: ${Math.round(percentUsed)}% dùng rồi!`);
        } else if (percentUsed >= 80) {
            warnings.push(`Đã dùng ${Math.round(percentUsed)}% ngân sách ${periodVi} ${categoryName}`);
        }

        // Cảnh báo chi tiêu lớn (1 lần duy nhất)
        if (amount >= budgetAmount * 0.6) {
            warnings.push(`Chi lớn: ${amount.toLocaleString()}đ chiếm ${(amount / budgetAmount * 100).toFixed(0)}% ngân sách ${periodVi}!`);
        }
    }

    if (transaction.type === 'income') {
        const goalMsg = await updateGoalProgress(userId, amount, familyId);
        if (goalMsg) warnings.push(goalMsg);
    }

    return warnings.length > 0 ? warnings.join('\n') : '';
};

async function updateGoalProgress(userId, incomeAmount, familyId) {
    const filter = familyId
        ? { $or: [{ userId, familyId: null }, { familyId }] }
        : { userId };

    const budgetWithGoal = await Budget.findOne({
        ...filter,
        'goal.targetAmount': { $gt: 0 },
        'goal.deadline': { $gte: new Date() },
    });

    if (!budgetWithGoal) return null;

    const updated = await Budget.findOneAndUpdate(
        { _id: budgetWithGoal._id },
        { $inc: { 'goal.currentProgress': incomeAmount } },
        { new: true }
    );

    const { goal } = updated;
    const progressPercent = Math.round((goal.currentProgress / goal.targetAmount) * 100);

    if (goal.currentProgress >= goal.targetAmount) {
        return `CHÚC MỪNG! Bạn đã hoàn thành goal "${goal.name}"!`;
    } else if (progressPercent >= 90) {
        return `Goal "${goal.name}": Đã đạt ${progressPercent}%! Sắp xong rồi, cố lên!`;
    } else if (progressPercent >= 75) {
        return `Goal "${goal.name}": ${progressPercent}% hoàn thành`;
    }

    return null;
}