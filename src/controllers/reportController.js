// filename: controllers/reports.js
import Transaction from '../models/transaction.js';
import Budget from '../models/budget.js';
import dayjs from 'dayjs';
import weekday from 'dayjs/plugin/weekday.js';
import weekOfYear from 'dayjs/plugin/weekOfYear.js';
import User from '../models/user.js';

dayjs.extend(weekday);
dayjs.extend(weekOfYear);

export const getReport = async (req, res) => {
    const { period = 'monthly', scope = 'personal' } = req.query; // personal | family
    const user = await User.findById(req.userId).lean();

    const now = dayjs();
    let startDate, endDate;

    if (period === 'daily') {
        startDate = now.startOf('day');
        endDate = now.endOf('day');
    } else if (period === 'weekly') {
        startDate = now.startOf('week');
        endDate = now.endOf('week').endOf('day');
    } else {
        startDate = now.startOf('month');
        endDate = now.endOf('month');
    }

    const prevStart = startDate.subtract(1, period === 'weekly' ? 'week' : period);
    const prevEnd = endDate.subtract(1, period === 'weekly' ? 'week' : period);

    const matchBase = {
        date: { $gte: startDate.toDate(), $lte: endDate.toDate() }
    };

    const matchExpenses = scope === 'family' && user.familyId
        ? { ...matchBase, familyId: user.familyId, isShared: true, type: 'expense' }
        : { ...matchBase, userId: req.userId, type: 'expense' };

    const matchIncomes = scope === 'family' && user.familyId
        ? { ...matchBase, familyId: user.familyId, isShared: true, type: 'income' }
        : { ...matchBase, userId: req.userId, type: 'income' };

    const expenses = await Transaction.aggregate([
        { $match: matchExpenses },
        {
            $group: {
                _id: '$categoryId',
                total: { $sum: '$amount' },
                count: { $sum: 1 }
            }
        },
        {
            $lookup: {
                from: 'categories',
                localField: '_id',
                foreignField: '_id',
                as: 'category'
            }
        },
        { $unwind: '$category' },
        {
            $project: {
                category: '$category.name',
                total: 1,
                count: 1
            }
        },
        { $sort: { total: -1 } }
    ]);

    const incomes = await Transaction.aggregate([
        { $match: matchIncomes },
        {
            $group: {
                _id: '$categoryId',
                total: { $sum: '$amount' }
            }
        },
        {
            $lookup: {
                from: 'categories',
                localField: '_id',
                foreignField: '_id',
                as: 'category'
            }
        },
        { $unwind: '$category' },
        {
            $project: {
                category: '$category.name',
                total: 1
            }
        }
    ]);

    const totalExpenses = expenses.reduce((sum, e) => sum + e.total, 0);
    const totalIncomes = incomes.reduce((sum, i) => sum + i.total, 0);

    const prevTotal = await Transaction.aggregate([
        {
            $match: {
                ...(scope === 'family' && user.familyId
                    ? { familyId: user.familyId, isShared: true }
                    : { userId: req.userId }),
                type: 'expense',
                date: { $gte: prevStart.toDate(), $lte: prevEnd.toDate() }
            }
        },
        { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    const change = prevTotal[0]?.total
        ? ((totalExpenses - prevTotal[0].total) / prevTotal[0].total * 100).toFixed(1)
        : null;

    // Budget status
    const budgetMatch = scope === 'family' && user.familyId
        ? { familyId: user.familyId }
        : { userId: req.userId };

    const budgets = await Budget.find(budgetMatch).populate('categoryId');

    const budgetStatus = budgets.map(b => {
        const spent = expenses.find(e =>
            b.categoryId && e.category === b.categoryId.name
        )?.total || 0;

        return {
            type: b.type,
            category: b.categoryId?.name || 'Tổng',
            budget: b.amount,
            spent,
            percent: b.amount > 0 ? Math.round(spent / b.amount * 100) : 0,
            goal: b.goal ? {
                name: b.goal.name,
                target: b.goal.targetAmount,
                progress: b.goal.currentProgress,
                percent: Math.round(b.goal.currentProgress / b.goal.targetAmount * 100),
                deadline: dayjs(b.goal.deadline).format('DD/MM/YYYY')
            } : null
        };
    });

    const data = {
        period,
        scope,
        dateRange: `${startDate.format('DD/MM')} - ${endDate.format('DD/MM/YYYY')}`,
        totalExpenses,
        totalIncomes,
        net: totalIncomes - totalExpenses,
        changePercent: change,
        topExpenses: expenses.slice(0, 5),
        topIncomes: incomes.slice(0, 3),
        budgetStatus
    };

    const insights = await geminiAnalyze(JSON.stringify(data, null, 2));

    res.json({
        message: 'Lấy báo cáo thành công',
        data: {
            data,
            insights
        }
    });
};
