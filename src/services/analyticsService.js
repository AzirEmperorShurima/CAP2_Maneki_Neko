import { models_list } from "../models/models_list.js";
import mongoose from "mongoose";

const { Transaction, Wallet, Budget, Goal, Category, Family, User } = models_list;

class AnalyticsService {
    /**
     * Lấy tổng quan tài chính của user
     */
    async getFinancialOverview(userId, options = {}) {
        const { 
            startDate = new Date(new Date().getFullYear(), new Date().getMonth(), 1),
            endDate = new Date(),
            includeFamily = false,
            familyId = null
        } = options;

        const query = { userId, date: { $gte: startDate, $lte: endDate } };
        
        if (includeFamily && familyId) {
            query.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete query.userId;
        }

        // Tổng thu nhập và chi tiêu
        const [incomeTotal, expenseTotal] = await Promise.all([
            Transaction.aggregate([
                { $match: { ...query, type: 'income' } },
                { $group: { _id: null, total: { $sum: '$amount' } } }
            ]),
            Transaction.aggregate([
                { $match: { ...query, type: 'expense' } },
                { $group: { _id: null, total: { $sum: '$amount' } } }
            ])
        ]);

        const income = incomeTotal[0]?.total || 0;
        const expense = expenseTotal[0]?.total || 0;
        const balance = income - expense;

        // Tổng số dư các ví
        const walletQuery = { userId, isActive: true };
        if (includeFamily && familyId) {
            walletQuery.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete walletQuery.userId;
        }

        const wallets = await Wallet.find(walletQuery);
        const totalWalletBalance = wallets.reduce((sum, w) => sum + w.balance, 0);

        return {
            period: { startDate, endDate },
            income,
            expense,
            balance,
            savingsRate: income > 0 ? ((balance / income) * 100).toFixed(2) : 0,
            totalWalletBalance,
            walletCount: wallets.length
        };
    }

    /**
     * Phân tích chi tiêu theo danh mục
     */
    async getExpenseByCategory(userId, options = {}) {
        const {
            startDate = new Date(new Date().getFullYear(), new Date().getMonth(), 1),
            endDate = new Date(),
            includeFamily = false,
            familyId = null,
            limit = 10
        } = options;

        const query = {
            userId,
            type: 'expense',
            date: { $gte: startDate, $lte: endDate }
        };

        if (includeFamily && familyId) {
            query.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete query.userId;
        }

        const result = await Transaction.aggregate([
            { $match: query },
            {
                $group: {
                    _id: '$categoryId',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 },
                    avgAmount: { $avg: '$amount' }
                }
            },
            { $sort: { total: -1 } },
            { $limit: limit },
            {
                $lookup: {
                    from: 'categories',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'category'
                }
            },
            { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } }
        ]);

        const totalExpense = result.reduce((sum, item) => sum + item.total, 0);

        return result.map(item => ({
            categoryId: item._id,
            categoryName: item.category?.name || 'Không phân loại',
            total: item.total,
            count: item.count,
            avgAmount: Math.round(item.avgAmount),
            percentage: totalExpense > 0 ? ((item.total / totalExpense) * 100).toFixed(2) : 0
        }));
    }

    /**
     * Phân tích thu nhập theo danh mục
     */
    async getIncomeByCategory(userId, options = {}) {
        const {
            startDate = new Date(new Date().getFullYear(), new Date().getMonth(), 1),
            endDate = new Date(),
            includeFamily = false,
            familyId = null
        } = options;

        const query = {
            userId,
            type: 'income',
            date: { $gte: startDate, $lte: endDate }
        };

        if (includeFamily && familyId) {
            query.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete query.userId;
        }

        const result = await Transaction.aggregate([
            { $match: query },
            {
                $group: {
                    _id: '$categoryId',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            },
            { $sort: { total: -1 } },
            {
                $lookup: {
                    from: 'categories',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'category'
                }
            },
            { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } }
        ]);

        const totalIncome = result.reduce((sum, item) => sum + item.total, 0);

        return result.map(item => ({
            categoryId: item._id,
            categoryName: item.category?.name || 'Không phân loại',
            total: item.total,
            count: item.count,
            percentage: totalIncome > 0 ? ((item.total / totalIncome) * 100).toFixed(2) : 0
        }));
    }

    /**
     * Xu hướng chi tiêu theo thời gian (daily, weekly, monthly)
     */
    async getSpendingTrend(userId, options = {}) {
        const {
            startDate = new Date(new Date().getFullYear(), new Date().getMonth(), 1),
            endDate = new Date(),
            groupBy = 'day', // 'day', 'week', 'month'
            includeFamily = false,
            familyId = null
        } = options;

        const query = {
            userId,
            type: 'expense',
            date: { $gte: startDate, $lte: endDate }
        };

        if (includeFamily && familyId) {
            query.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete query.userId;
        }

        let groupFormat;
        switch (groupBy) {
            case 'day':
                groupFormat = {
                    year: { $year: '$date' },
                    month: { $month: '$date' },
                    day: { $dayOfMonth: '$date' }
                };
                break;
            case 'week':
                groupFormat = {
                    year: { $year: '$date' },
                    week: { $week: '$date' }
                };
                break;
            case 'month':
                groupFormat = {
                    year: { $year: '$date' },
                    month: { $month: '$date' }
                };
                break;
            default:
                groupFormat = {
                    year: { $year: '$date' },
                    month: { $month: '$date' },
                    day: { $dayOfMonth: '$date' }
                };
        }

        const result = await Transaction.aggregate([
            { $match: query },
            {
                $group: {
                    _id: groupFormat,
                    total: { $sum: '$amount' },
                    count: { $sum: 1 },
                    avgAmount: { $avg: '$amount' }
                }
            },
            { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1, '_id.week': 1 } }
        ]);

        return result.map(item => ({
            period: item._id,
            total: item.total,
            count: item.count,
            avgAmount: Math.round(item.avgAmount)
        }));
    }

    /**
     * So sánh với kỳ trước
     */
    async getComparisonWithPreviousPeriod(userId, options = {}) {
        const {
            currentStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1),
            currentEnd = new Date(),
            includeFamily = false,
            familyId = null
        } = options;

        // Tính kỳ trước
        const periodDuration = currentEnd - currentStart;
        const previousStart = new Date(currentStart.getTime() - periodDuration);
        const previousEnd = new Date(currentStart);

        const [currentPeriod, previousPeriod] = await Promise.all([
            this.getFinancialOverview(userId, {
                startDate: currentStart,
                endDate: currentEnd,
                includeFamily,
                familyId
            }),
            this.getFinancialOverview(userId, {
                startDate: previousStart,
                endDate: previousEnd,
                includeFamily,
                familyId
            })
        ]);

        return {
            current: currentPeriod,
            previous: previousPeriod,
            comparison: {
                incomeChange: this._calculatePercentageChange(previousPeriod.income, currentPeriod.income),
                expenseChange: this._calculatePercentageChange(previousPeriod.expense, currentPeriod.expense),
                balanceChange: this._calculatePercentageChange(previousPeriod.balance, currentPeriod.balance)
            }
        };
    }

    /**
     * Trạng thái ngân sách
     */
    async getBudgetStatus(userId, options = {}) {
        const {
            startDate = new Date(new Date().getFullYear(), new Date().getMonth(), 1),
            endDate = new Date(),
            includeFamily = false,
            familyId = null
        } = options;

        const budgetQuery = {
            userId,
            isActive: true,
            periodStart: { $lte: endDate },
            periodEnd: { $gte: startDate }
        };

        if (includeFamily && familyId) {
            budgetQuery.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete budgetQuery.userId;
        }

        const budgets = await Budget.find(budgetQuery).populate('categoryId');

        const budgetStatus = await Promise.all(
            budgets.map(async (budget) => {
                const transactionQuery = {
                    userId,
                    type: 'expense',
                    date: { $gte: budget.periodStart, $lte: budget.periodEnd }
                };

                if (budget.categoryId) {
                    transactionQuery.categoryId = budget.categoryId._id;
                }

                if (includeFamily && familyId) {
                    transactionQuery.$or = [
                        { userId, isShared: false },
                        { familyId, isShared: true }
                    ];
                    delete transactionQuery.userId;
                }

                const spent = await Transaction.aggregate([
                    { $match: transactionQuery },
                    { $group: { _id: null, total: { $sum: '$amount' } } }
                ]);

                const spentAmount = spent[0]?.total || 0;
                const remaining = budget.amount - spentAmount;
                const percentage = budget.amount > 0 ? (spentAmount / budget.amount) * 100 : 0;

                return {
                    budgetId: budget._id,
                    type: budget.type,
                    categoryName: budget.categoryId?.name || 'Tổng quát',
                    amount: budget.amount,
                    spent: spentAmount,
                    remaining,
                    percentage: percentage.toFixed(2),
                    status: percentage >= 100 ? 'exceeded' : percentage >= 80 ? 'warning' : 'safe',
                    period: {
                        start: budget.periodStart,
                        end: budget.periodEnd
                    }
                };
            })
        );

        return budgetStatus;
    }

    /**
     * Tiến độ mục tiêu
     */
    async getGoalsProgress(userId, options = {}) {
        const {
            includeFamily = false,
            familyId = null,
            status = ['active']
        } = options;

        const goalQuery = {
            userId,
            status: { $in: status }
        };

        if (includeFamily && familyId) {
            goalQuery.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete goalQuery.userId;
        }

        const goals = await Goal.find(goalQuery);

        return goals.map(goal => {
            const percentage = goal.targetAmount > 0 
                ? (goal.currentProgress / goal.targetAmount) * 100 
                : 0;

            const daysRemaining = Math.ceil((goal.deadline - new Date()) / (1000 * 60 * 60 * 24));

            return {
                goalId: goal._id,
                name: goal.name,
                targetAmount: goal.targetAmount,
                currentProgress: goal.currentProgress,
                remaining: goal.targetAmount - goal.currentProgress,
                percentage: percentage.toFixed(2),
                deadline: goal.deadline,
                daysRemaining: daysRemaining > 0 ? daysRemaining : 0,
                status: goal.status,
                isOnTrack: percentage >= ((Date.now() - goal.createdAt) / (goal.deadline - goal.createdAt)) * 100
            };
        });
    }

    /**
     * Phân tích ví
     */
    async getWalletAnalytics(userId, options = {}) {
        const {
            includeFamily = false,
            familyId = null
        } = options;

        const walletQuery = { userId, isActive: true };

        if (includeFamily && familyId) {
            walletQuery.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete walletQuery.userId;
        }

        const wallets = await Wallet.find(walletQuery);

        const walletAnalytics = await Promise.all(
            wallets.map(async (wallet) => {
                // Đếm số giao dịch
                const transactionCount = await Transaction.countDocuments({
                    walletId: wallet._id
                });

                // Giao dịch gần nhất
                const lastTransaction = await Transaction.findOne({
                    walletId: wallet._id
                }).sort({ date: -1 });

                return {
                    walletId: wallet._id,
                    name: wallet.name,
                    type: wallet.type,
                    scope: wallet.scope,
                    balance: wallet.balance,
                    transactionCount,
                    lastTransactionDate: lastTransaction?.date,
                    isShared: wallet.isShared,
                    isSystemWallet: wallet.isSystemWallet
                };
            })
        );

        const totalBalance = walletAnalytics.reduce((sum, w) => sum + w.balance, 0);

        return {
            wallets: walletAnalytics,
            summary: {
                totalBalance,
                walletCount: walletAnalytics.length,
                personalWallets: walletAnalytics.filter(w => !w.isShared).length,
                familyWallets: walletAnalytics.filter(w => w.isShared).length,
                systemWallets: walletAnalytics.filter(w => w.isSystemWallet).length
            }
        };
    }

    /**
     * Top giao dịch (lớn nhất, nhỏ nhất, thường xuyên)
     */
    async getTopTransactions(userId, options = {}) {
        const {
            startDate = new Date(new Date().getFullYear(), new Date().getMonth(), 1),
            endDate = new Date(),
            includeFamily = false,
            familyId = null,
            type = 'expense',
            limit = 5
        } = options;

        const query = {
            userId,
            type,
            date: { $gte: startDate, $lte: endDate }
        };

        if (includeFamily && familyId) {
            query.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete query.userId;
        }

        // Top giao dịch lớn nhất
        const topExpensive = await Transaction.find(query)
            .sort({ amount: -1 })
            .limit(limit)
            .populate('categoryId walletId');

        // Danh mục thường xuyên
        const frequentCategories = await Transaction.aggregate([
            { $match: query },
            {
                $group: {
                    _id: '$categoryId',
                    count: { $sum: 1 },
                    totalAmount: { $sum: '$amount' }
                }
            },
            { $sort: { count: -1 } },
            { $limit: limit },
            {
                $lookup: {
                    from: 'categories',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'category'
                }
            },
            { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } }
        ]);

        return {
            topExpensive: topExpensive.map(t => ({
                id: t._id,
                amount: t.amount,
                description: t.description,
                category: t.categoryId?.name,
                wallet: t.walletId?.name,
                date: t.date
            })),
            frequentCategories: frequentCategories.map(c => ({
                categoryName: c.category?.name || 'Không phân loại',
                count: c.count,
                totalAmount: c.totalAmount
            }))
        };
    }

    /**
     * Báo cáo tổng hợp đầy đủ
     */
    async getFullReport(userId, options = {}) {
        const {
            startDate = new Date(new Date().getFullYear(), new Date().getMonth(), 1),
            endDate = new Date(),
            includeFamily = false,
            familyId = null
        } = options;

        const reportOptions = { startDate, endDate, includeFamily, familyId };

        const [
            overview,
            expenseByCategory,
            incomeByCategory,
            budgetStatus,
            goalsProgress,
            walletAnalytics,
            topTransactions,
            comparison
        ] = await Promise.all([
            this.getFinancialOverview(userId, reportOptions),
            this.getExpenseByCategory(userId, reportOptions),
            this.getIncomeByCategory(userId, reportOptions),
            this.getBudgetStatus(userId, reportOptions),
            this.getGoalsProgress(userId, { includeFamily, familyId }),
            this.getWalletAnalytics(userId, { includeFamily, familyId }),
            this.getTopTransactions(userId, reportOptions),
            this.getComparisonWithPreviousPeriod(userId, {
                currentStart: startDate,
                currentEnd: endDate,
                includeFamily,
                familyId
            })
        ]);

        return {
            reportDate: new Date(),
            period: { startDate, endDate },
            overview,
            expenseByCategory,
            incomeByCategory,
            budgetStatus,
            goalsProgress,
            walletAnalytics,
            topTransactions,
            comparison
        };
    }

    /**
     * Phân tích chi tiêu theo quý
     */
    async getQuarterlyAnalysis(userId, options = {}) {
        const {
            year = new Date().getFullYear(),
            includeFamily = false,
            familyId = null
        } = options;

        const quarters = [
            { name: 'Q1', start: new Date(year, 0, 1), end: new Date(year, 2, 31, 23, 59, 59) },
            { name: 'Q2', start: new Date(year, 3, 1), end: new Date(year, 5, 30, 23, 59, 59) },
            { name: 'Q3', start: new Date(year, 6, 1), end: new Date(year, 8, 30, 23, 59, 59) },
            { name: 'Q4', start: new Date(year, 9, 1), end: new Date(year, 11, 31, 23, 59, 59) }
        ];

        const quarterlyData = await Promise.all(
            quarters.map(async (quarter) => {
                const query = {
                    userId,
                    date: { $gte: quarter.start, $lte: quarter.end }
                };

                if (includeFamily && familyId) {
                    query.$or = [
                        { userId, isShared: false },
                        { familyId, isShared: true }
                    ];
                    delete query.userId;
                }

                const [income, expense] = await Promise.all([
                    Transaction.aggregate([
                        { $match: { ...query, type: 'income' } },
                        { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
                    ]),
                    Transaction.aggregate([
                        { $match: { ...query, type: 'expense' } },
                        { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
                    ])
                ]);

                const incomeTotal = income[0]?.total || 0;
                const expenseTotal = expense[0]?.total || 0;
                const incomeCount = income[0]?.count || 0;
                const expenseCount = expense[0]?.count || 0;

                return {
                    quarter: quarter.name,
                    period: {
                        start: quarter.start,
                        end: quarter.end
                    },
                    income: incomeTotal,
                    expense: expenseTotal,
                    balance: incomeTotal - expenseTotal,
                    transactionCount: {
                        income: incomeCount,
                        expense: expenseCount,
                        total: incomeCount + expenseCount
                    },
                    avgDailyExpense: Math.round(expenseTotal / 90), // Ước tính 90 ngày/quý
                    savingsRate: incomeTotal > 0 ? (((incomeTotal - expenseTotal) / incomeTotal) * 100).toFixed(2) : 0
                };
            })
        );

        // Tính tổng năm
        const yearTotal = {
            income: quarterlyData.reduce((sum, q) => sum + q.income, 0),
            expense: quarterlyData.reduce((sum, q) => sum + q.expense, 0),
            balance: quarterlyData.reduce((sum, q) => sum + q.balance, 0),
            transactionCount: quarterlyData.reduce((sum, q) => sum + q.transactionCount.total, 0)
        };

        // Tìm quý chi tiêu cao nhất và thấp nhất
        const sortedByExpense = [...quarterlyData].sort((a, b) => b.expense - a.expense);

        return {
            year,
            quarters: quarterlyData,
            summary: {
                ...yearTotal,
                avgQuarterlyExpense: Math.round(yearTotal.expense / 4),
                avgQuarterlyIncome: Math.round(yearTotal.income / 4),
                highestExpenseQuarter: sortedByExpense[0]?.quarter,
                lowestExpenseQuarter: sortedByExpense[sortedByExpense.length - 1]?.quarter
            }
        };
    }

    /**
     * Phân tích chi tiêu theo năm (nhiều năm)
     */
    async getYearlyAnalysis(userId, options = {}) {
        const {
            startYear = new Date().getFullYear() - 2,
            endYear = new Date().getFullYear(),
            includeFamily = false,
            familyId = null
        } = options;

        const years = [];
        for (let year = startYear; year <= endYear; year++) {
            years.push(year);
        }

        const yearlyData = await Promise.all(
            years.map(async (year) => {
                const yearStart = new Date(year, 0, 1);
                const yearEnd = new Date(year, 11, 31, 23, 59, 59);

                const query = {
                    userId,
                    date: { $gte: yearStart, $lte: yearEnd }
                };

                if (includeFamily && familyId) {
                    query.$or = [
                        { userId, isShared: false },
                        { familyId, isShared: true }
                    ];
                    delete query.userId;
                }

                const [income, expense] = await Promise.all([
                    Transaction.aggregate([
                        { $match: { ...query, type: 'income' } },
                        { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
                    ]),
                    Transaction.aggregate([
                        { $match: { ...query, type: 'expense' } },
                        { 
                            $group: { 
                                _id: null, 
                                total: { $sum: '$amount' }, 
                                count: { $sum: 1 },
                                avg: { $avg: '$amount' }
                            } 
                        }
                    ])
                ]);

                const incomeTotal = income[0]?.total || 0;
                const expenseTotal = expense[0]?.total || 0;
                const expenseCount = expense[0]?.count || 0;

                return {
                    year,
                    income: incomeTotal,
                    expense: expenseTotal,
                    balance: incomeTotal - expenseTotal,
                    transactionCount: (income[0]?.count || 0) + expenseCount,
                    avgMonthlyExpense: Math.round(expenseTotal / 12),
                    avgDailyExpense: Math.round(expenseTotal / 365),
                    avgTransactionAmount: expenseCount > 0 ? Math.round(expenseTotal / expenseCount) : 0,
                    savingsRate: incomeTotal > 0 ? (((incomeTotal - expenseTotal) / incomeTotal) * 100).toFixed(2) : 0
                };
            })
        );

        // Tính growth rate giữa các năm
        const withGrowth = yearlyData.map((data, index) => {
            if (index === 0) return { ...data, growth: null };

            const previous = yearlyData[index - 1];
            return {
                ...data,
                growth: {
                    income: this._calculatePercentageChange(previous.income, data.income),
                    expense: this._calculatePercentageChange(previous.expense, data.expense),
                    balance: this._calculatePercentageChange(previous.balance, data.balance)
                }
            };
        });

        // Summary
        const totalIncome = yearlyData.reduce((sum, y) => sum + y.income, 0);
        const totalExpense = yearlyData.reduce((sum, y) => sum + y.expense, 0);

        return {
            years: withGrowth,
            summary: {
                totalIncome,
                totalExpense,
                totalBalance: totalIncome - totalExpense,
                avgYearlyIncome: Math.round(totalIncome / years.length),
                avgYearlyExpense: Math.round(totalExpense / years.length),
                highestExpenseYear: yearlyData.reduce((max, y) => y.expense > max.expense ? y : max, yearlyData[0])?.year,
                lowestExpenseYear: yearlyData.reduce((min, y) => y.expense < min.expense ? y : min, yearlyData[0])?.year
            }
        };
    }

    /**
     * Phân tích chi tiêu trung bình
     */
    async getAverageSpendingAnalysis(userId, options = {}) {
        const {
            startDate = new Date(new Date().getFullYear(), 0, 1),
            endDate = new Date(),
            includeFamily = false,
            familyId = null,
            groupBy = 'category' // 'category', 'day', 'month', 'paymentMethod'
        } = options;

        const query = {
            userId,
            type: 'expense',
            date: { $gte: startDate, $lte: endDate }
        };

        if (includeFamily && familyId) {
            query.$or = [
                { userId, isShared: false },
                { familyId, isShared: true }
            ];
            delete query.userId;
        }

        // Tổng chi tiêu và số ngày
        const totalDays = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24)) || 1;
        const totalMonths = Math.ceil(totalDays / 30) || 1;

        const [totalStats, categoryAvg, dayOfWeekAvg, monthlyPattern] = await Promise.all([
            // Tổng thống kê
            Transaction.aggregate([
                { $match: query },
                {
                    $group: {
                        _id: null,
                        total: { $sum: '$amount' },
                        count: { $sum: 1 },
                        avg: { $avg: '$amount' },
                        min: { $min: '$amount' },
                        max: { $max: '$amount' }
                    }
                }
            ]),

            // Chi tiêu trung bình theo danh mục
            Transaction.aggregate([
                { $match: query },
                {
                    $group: {
                        _id: '$categoryId',
                        avgAmount: { $avg: '$amount' },
                        totalAmount: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                },
                { $sort: { totalAmount: -1 } },
                { $limit: 10 },
                {
                    $lookup: {
                        from: 'categories',
                        localField: '_id',
                        foreignField: '_id',
                        as: 'category'
                    }
                },
                { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } }
            ]),

            // Chi tiêu trung bình theo ngày trong tuần
            Transaction.aggregate([
                { $match: query },
                {
                    $group: {
                        _id: { $dayOfWeek: '$date' },
                        avgAmount: { $avg: '$amount' },
                        totalAmount: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                },
                { $sort: { _id: 1 } }
            ]),

            // Mẫu hình chi tiêu theo tháng
            Transaction.aggregate([
                { $match: query },
                {
                    $group: {
                        _id: { 
                            year: { $year: '$date' },
                            month: { $month: '$date' }
                        },
                        avgAmount: { $avg: '$amount' },
                        totalAmount: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                },
                { $sort: { '_id.year': 1, '_id.month': 1 } }
            ])
        ]);

        const stats = totalStats[0] || { total: 0, count: 0, avg: 0, min: 0, max: 0 };

        const dayNames = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];

        return {
            period: { startDate, endDate, totalDays, totalMonths },
            overall: {
                totalExpense: stats.total,
                totalTransactions: stats.count,
                avgPerTransaction: Math.round(stats.avg),
                avgPerDay: Math.round(stats.total / totalDays),
                avgPerWeek: Math.round(stats.total / (totalDays / 7)),
                avgPerMonth: Math.round(stats.total / totalMonths),
                minTransaction: stats.min,
                maxTransaction: stats.max
            },
            byCategory: categoryAvg.map(item => ({
                categoryId: item._id,
                categoryName: item.category?.name || 'Không phân loại',
                avgAmount: Math.round(item.avgAmount),
                totalAmount: item.totalAmount,
                transactionCount: item.count,
                avgFrequency: (item.count / totalDays).toFixed(2) // số lần/ngày
            })),
            byDayOfWeek: dayOfWeekAvg.map(item => ({
                day: dayNames[item._id - 1],
                dayNumber: item._id,
                avgAmount: Math.round(item.avgAmount),
                totalAmount: item.totalAmount,
                transactionCount: item.count
            })),
            monthlyPattern: monthlyPattern.map(item => ({
                year: item._id.year,
                month: item._id.month,
                avgAmount: Math.round(item.avgAmount),
                totalAmount: item.totalAmount,
                transactionCount: item.count
            })),
            insights: {
                mostExpensiveDay: dayOfWeekAvg.length > 0 
                    ? dayNames[dayOfWeekAvg.reduce((max, day) => day.totalAmount > max.totalAmount ? day : max, dayOfWeekAvg[0])._id - 1]
                    : null,
                mostFrequentCategory: categoryAvg.length > 0 ? categoryAvg[0].category?.name : null,
                spendingConsistency: stats.count > 0 
                    ? (stats.avg / stats.max * 100).toFixed(2) // % độ đồng đều
                    : 0
            }
        };
    }

    /**
     * So sánh chi tiêu trung bình giữa các khoảng thời gian
     */
    async compareAverageSpending(userId, options = {}) {
        const {
            periods = [], // [{ name: 'Q1 2024', start: ..., end: ... }]
            includeFamily = false,
            familyId = null
        } = options;

        if (periods.length === 0) {
            // Mặc định: 3 tháng gần nhất
            const now = new Date();
            for (let i = 2; i >= 0; i--) {
                const start = new Date(now.getFullYear(), now.getMonth() - i, 1);
                const end = new Date(now.getFullYear(), now.getMonth() - i + 1, 0, 23, 59, 59);
                periods.push({
                    name: `Tháng ${start.getMonth() + 1}/${start.getFullYear()}`,
                    start,
                    end
                });
            }
        }

        const comparisons = await Promise.all(
            periods.map(async (period) => {
                const avgAnalysis = await this.getAverageSpendingAnalysis(userId, {
                    startDate: period.start,
                    endDate: period.end,
                    includeFamily,
                    familyId
                });

                return {
                    period: period.name,
                    dateRange: { start: period.start, end: period.end },
                    avgPerDay: avgAnalysis.overall.avgPerDay,
                    avgPerTransaction: avgAnalysis.overall.avgPerTransaction,
                    totalExpense: avgAnalysis.overall.totalExpense,
                    transactionCount: avgAnalysis.overall.totalTransactions
                };
            })
        );

        // Tính xu hướng
        const trend = comparisons.map((comp, index) => {
            if (index === 0) return { ...comp, change: null };

            const previous = comparisons[index - 1];
            return {
                ...comp,
                change: {
                    avgPerDay: this._calculatePercentageChange(previous.avgPerDay, comp.avgPerDay),
                    avgPerTransaction: this._calculatePercentageChange(previous.avgPerTransaction, comp.avgPerTransaction),
                    totalExpense: this._calculatePercentageChange(previous.totalExpense, comp.totalExpense)
                }
            };
        });

        return {
            periods: trend,
            summary: {
                avgAcrossAllPeriods: {
                    perDay: Math.round(comparisons.reduce((sum, p) => sum + p.avgPerDay, 0) / comparisons.length),
                    perTransaction: Math.round(comparisons.reduce((sum, p) => sum + p.avgPerTransaction, 0) / comparisons.length)
                },
                highestPeriod: comparisons.reduce((max, p) => p.totalExpense > max.totalExpense ? p : max, comparisons[0])?.period,
                lowestPeriod: comparisons.reduce((min, p) => p.totalExpense < min.totalExpense ? p : min, comparisons[0])?.period
            }
        };
    }

    /**
     * Helper: Tính phần trăm thay đổi
     */
    _calculatePercentageChange(oldValue, newValue) {
        if (oldValue === 0) {
            return newValue > 0 ? 100 : 0;
        }
        return (((newValue - oldValue) / Math.abs(oldValue)) * 100).toFixed(2);
    }
}

export default new AnalyticsService();