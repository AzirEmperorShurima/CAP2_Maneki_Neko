import Transaction from "../models/transaction.js";
import Wallet from "../models/wallet.js";

class AnalyticsController {
    /**
     * GET /api/analytics/personal/overview
     * Tổng quan tài chính CÁ NHÂN (không liên quan family)
     */
    async getPersonalOverview(req, res) {
        try {
            const userId = req.userId;
            const { startDate, endDate, walletId } = req.query;

            const dateFilter = {
                userId,
                isDeleted: { $ne: true }
            };

            if (startDate || endDate) {
                dateFilter.date = {};
                if (startDate) dateFilter.date.$gte = new Date(startDate);
                if (endDate) dateFilter.date.$lte = new Date(endDate);
            } else {
                dateFilter.date = new Date(new Date().setMonth(new Date().getMonth() - 1));
                dateFilter.date = new Date();
            }

            if (walletId) {
                dateFilter.walletId = walletId;
            }

            // Lấy tổng thu nhập và chi tiêu
            const [incomeResult, expenseResult] = await Promise.all([
                Transaction.aggregate([
                    { $match: { ...dateFilter, type: 'income' } },
                    { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
                ]),
                Transaction.aggregate([
                    { $match: { ...dateFilter, type: 'expense' } },
                    { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
                ])
            ]);

            const totalIncome = incomeResult[0]?.total || 0;
            const totalExpense = expenseResult[0]?.total || 0;
            const incomeCount = incomeResult[0]?.count || 0;
            const expenseCount = expenseResult[0]?.count || 0;

            // Lấy tổng số dư ví cá nhân
            const wallets = await Wallet.find({
                userId,
                isActive: true,
                isShared: false // CHỈ VÍ CÁ NHÂN
            });

            const totalBalance = wallets.reduce((sum, w) => sum + w.balance, 0);

            return res.status(200).json({
                message: 'Lấy tổng quan tài chính cá nhân thành công',
                data: {
                    income: {
                        total: totalIncome,
                        count: incomeCount
                    },
                    expense: {
                        total: totalExpense,
                        count: expenseCount
                    },
                    netBalance: totalIncome - totalExpense,
                    totalWalletBalance: totalBalance,
                    walletsCount: wallets.length,
                    period: {
                        startDate: startDate || null,
                        endDate: endDate || null
                    }
                }
            });
        } catch (error) {
            console.error('Error in getPersonalOverview:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy tổng quan tài chính cá nhân',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/personal/spending-trend
     * Xu hướng chi tiêu cá nhân theo thời gian (day/week/month)
     */
    async getPersonalSpendingTrend(req, res) {
        try {
            const userId = req.userId;
            const { startDate, endDate, groupBy = 'day', walletId } = req.query;

            const matchFilter = {
                userId,
                isDeleted: { $ne: true }
            };

            if (startDate || endDate) {
                matchFilter.date = {};
                if (startDate) matchFilter.date.$gte = new Date(startDate);
                if (endDate) matchFilter.date.$lte = new Date(endDate);
            }

            if (walletId) {
                matchFilter.walletId = walletId;
            }

            // Xác định format groupBy
            let dateFormat;
            switch (groupBy) {
                case 'week':
                    dateFormat = { $isoWeek: '$date' };
                    break;
                case 'month':
                    dateFormat = { $dateToString: { format: '%Y-%m', date: '$date' } };
                    break;
                case 'day':
                default:
                    dateFormat = { $dateToString: { format: '%Y-%m-%d', date: '$date' } };
            }

            const trendData = await Transaction.aggregate([
                { $match: matchFilter },
                {
                    $group: {
                        _id: {
                            period: dateFormat,
                            type: '$type'
                        },
                        total: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                },
                { $sort: { '_id.period': 1 } }
            ]);

            // Format data
            const formattedData = {};
            trendData.forEach(item => {
                const period = item._id.period;
                if (!formattedData[period]) {
                    formattedData[period] = { period, income: 0, expense: 0, incomeCount: 0, expenseCount: 0 };
                }
                if (item._id.type === 'income') {
                    formattedData[period].income = item.total;
                    formattedData[period].incomeCount = item.count;
                } else {
                    formattedData[period].expense = item.total;
                    formattedData[period].expenseCount = item.count;
                }
            });

            const result = Object.values(formattedData).map(item => ({
                ...item,
                net: item.income - item.expense
            }));

            return res.status(200).json({
                message: 'Lấy xu hướng chi tiêu cá nhân thành công',
                data: {
                    groupBy,
                    trend: result
                }
            });
        } catch (error) {
            console.error('Error in getPersonalSpendingTrend:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy xu hướng chi tiêu',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/personal/by-wallet
     * Phân tích thu chi theo từng ví cá nhân
     */
    async getAnalyticsByWallet(req, res) {
        try {
            const userId = req.userId;
            const { startDate, endDate } = req.query;

            const dateFilter = { userId, isDeleted: { $ne: true } };
            if (startDate || endDate) {
                dateFilter.date = {};
                if (startDate) dateFilter.date.$gte = new Date(startDate);
                if (endDate) dateFilter.date.$lte = new Date(endDate);
            }

            // Aggregate theo wallet
            const walletStats = await Transaction.aggregate([
                { $match: dateFilter },
                {
                    $group: {
                        _id: {
                            walletId: '$walletId',
                            type: '$type'
                        },
                        total: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                }
            ]);

            // Lấy thông tin wallet
            const walletIds = [...new Set(walletStats.map(s => s._id.walletId).filter(Boolean))];
            const wallets = await Wallet.find({
                _id: { $in: walletIds },
                userId,
                isShared: false // CHỈ VÍ CÁ NHÂN
            }).lean();

            // Map data
            const walletMap = {};
            wallets.forEach(w => {
                walletMap[w._id.toString()] = {
                    walletId: w._id,
                    walletName: w.name,
                    walletType: w.type,
                    walletIcon: w.icon,
                    currentBalance: w.balance,
                    income: 0,
                    expense: 0,
                    incomeCount: 0,
                    expenseCount: 0
                };
            });

            walletStats.forEach(stat => {
                const walletId = stat._id.walletId?.toString();
                if (walletId && walletMap[walletId]) {
                    if (stat._id.type === 'income') {
                        walletMap[walletId].income = stat.total;
                        walletMap[walletId].incomeCount = stat.count;
                    } else {
                        walletMap[walletId].expense = stat.total;
                        walletMap[walletId].expenseCount = stat.count;
                    }
                }
            });

            const result = Object.values(walletMap).map(w => ({
                ...w,
                net: w.income - w.expense,
                totalTransactions: w.incomeCount + w.expenseCount
            })).sort((a, b) => (b.income + b.expense) - (a.income + a.expense));

            return res.status(200).json({
                message: 'Lấy phân tích theo ví thành công',
                data: result
            });
        } catch (error) {
            console.error('Error in getAnalyticsByWallet:', error);
            return res.status(500).json({
                error: 'Lỗi khi phân tích theo ví',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/personal/wallet/:walletId/details
     * Chi tiết phân tích cho 1 ví cụ thể
     */
    async getWalletDetailedAnalytics(req, res) {
        try {
            const userId = req.userId;
            const { walletId } = req.params;
            const { startDate, endDate } = req.query;

            // Kiểm tra wallet có thuộc user không
            const wallet = await Wallet.findOne({
                _id: walletId,
                userId,
                isShared: false
            });

            if (!wallet) {
                return res.status(404).json({ error: 'Không tìm thấy ví hoặc không có quyền truy cập' });
            }

            const dateFilter = {
                userId,
                walletId,
                isDeleted: { $ne: true }
            };

            if (startDate || endDate) {
                dateFilter.date = {};
                if (startDate) dateFilter.date.$gte = new Date(startDate);
                if (endDate) dateFilter.date.$lte = new Date(endDate);
            }

            // 1. Tổng quan
            const [incomeResult, expenseResult] = await Promise.all([
                Transaction.aggregate([
                    { $match: { ...dateFilter, type: 'income' } },
                    { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
                ]),
                Transaction.aggregate([
                    { $match: { ...dateFilter, type: 'expense' } },
                    { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
                ])
            ]);

            // 2. Chi tiêu theo category
            const categoryBreakdown = await Transaction.aggregate([
                { $match: { ...dateFilter, type: 'expense' } },
                {
                    $group: {
                        _id: '$categoryId',
                        total: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                },
                { $sort: { total: -1 } },
                { $limit: 10 }
            ]);

            // Populate categories
            const categoryIds = categoryBreakdown.map(c => c._id).filter(Boolean);
            const categories = await Category.find({ _id: { $in: categoryIds } }).lean();
            const categoryMap = {};
            categories.forEach(c => categoryMap[c._id.toString()] = c.name);

            const formattedCategories = categoryBreakdown.map(c => ({
                categoryId: c._id,
                categoryName: c._id ? categoryMap[c._id.toString()] || 'Không xác định' : 'Không phân loại',
                total: c.total,
                count: c.count,
                percentage: expenseResult[0]?.total ? ((c.total / expenseResult[0].total) * 100).toFixed(2) : 0
            }));

            // 3. Xu hướng theo ngày (7 ngày gần nhất)
            const dailyTrend = await Transaction.aggregate([
                { $match: dateFilter },
                {
                    $group: {
                        _id: {
                            date: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
                            type: '$type'
                        },
                        total: { $sum: '$amount' }
                    }
                },
                { $sort: { '_id.date': -1 } },
                { $limit: 14 }
            ]);

            const dailyMap = {};
            dailyTrend.forEach(d => {
                if (!dailyMap[d._id.date]) {
                    dailyMap[d._id.date] = { date: d._id.date, income: 0, expense: 0 };
                }
                dailyMap[d._id.date][d._id.type] = d.total;
            });

            return res.status(200).json({
                message: 'Lấy phân tích chi tiết ví thành công',
                data: {
                    wallet: {
                        id: wallet._id,
                        name: wallet.name,
                        type: wallet.type,
                        icon: wallet.icon,
                        currentBalance: wallet.balance
                    },
                    summary: {
                        totalIncome: incomeResult[0]?.total || 0,
                        totalExpense: expenseResult[0]?.total || 0,
                        incomeCount: incomeResult[0]?.count || 0,
                        expenseCount: expenseResult[0]?.count || 0,
                        net: (incomeResult[0]?.total || 0) - (expenseResult[0]?.total || 0)
                    },
                    expenseByCategory: formattedCategories,
                    dailyTrend: Object.values(dailyMap).sort((a, b) => b.date.localeCompare(a.date))
                }
            });
        } catch (error) {
            console.error('Error in getWalletDetailedAnalytics:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy phân tích chi tiết ví',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/personal/by-category
     * Phân tích chi tiêu theo danh mục (tất cả ví cá nhân)
     */
    async getAnalyticsByCategory(req, res) {
        try {
            const userId = req.userId;
            const { startDate, endDate, type = 'expense', limit = '10' } = req.query;

            const matchFilter = {
                userId,
                type,
                isDeleted: { $ne: true }
            };

            if (startDate || endDate) {
                matchFilter.date = {};
                if (startDate) matchFilter.date.$gte = new Date(startDate);
                if (endDate) matchFilter.date.$lte = new Date(endDate);
            }

            const categoryStats = await Transaction.aggregate([
                { $match: matchFilter },
                {
                    $group: {
                        _id: '$categoryId',
                        total: { $sum: '$amount' },
                        count: { $sum: 1 },
                        avgAmount: { $avg: '$amount' }
                    }
                },
                { $sort: { total: -1 } },
                { $limit: parseInt(limit) }
            ]);

            // Get total for percentage calculation
            const totalResult = await Transaction.aggregate([
                { $match: matchFilter },
                { $group: { _id: null, grandTotal: { $sum: '$amount' } } }
            ]);
            const grandTotal = totalResult[0]?.grandTotal || 0;

            // Populate categories
            const categoryIds = categoryStats.map(c => c._id).filter(Boolean);
            const categories = await Category.find({ _id: { $in: categoryIds } }).lean();
            const categoryMap = {};
            categories.forEach(c => categoryMap[c._id.toString()] = c);

            const result = categoryStats.map(stat => ({
                categoryId: stat._id,
                categoryName: stat._id ? categoryMap[stat._id.toString()]?.name || 'Không xác định' : 'Không phân loại',
                total: stat.total,
                count: stat.count,
                avgAmount: stat.avgAmount,
                percentage: grandTotal > 0 ? ((stat.total / grandTotal) * 100).toFixed(2) : 0
            }));

            return res.status(200).json({
                message: 'Lấy phân tích theo danh mục thành công',
                data: {
                    type,
                    categories: result,
                    grandTotal
                }
            });
        } catch (error) {
            console.error('Error in getAnalyticsByCategory:', error);
            return res.status(500).json({
                error: 'Lỗi khi phân tích theo danh mục',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/personal/top-transactions
     * Top giao dịch lớn nhất
     */
    async getTopTransactions(req, res) {
        try {
            const userId = req.userId;
            const { startDate, endDate, type = 'expense', limit = '10', walletId } = req.query;

            const matchFilter = {
                userId,
                isDeleted: { $ne: true }
            };

            if (type) matchFilter.type = type;
            if (walletId) matchFilter.walletId = walletId;

            if (startDate || endDate) {
                matchFilter.date = {};
                if (startDate) matchFilter.date.$gte = new Date(startDate);
                if (endDate) matchFilter.date.$lte = new Date(endDate);
            }

            const topTransactions = await Transaction.find(matchFilter)
                .sort({ amount: -1 })
                .limit(parseInt(limit))
                .populate('categoryId', 'name')
                .populate('walletId', 'name icon')
                .lean();

            return res.status(200).json({
                message: 'Lấy top giao dịch thành công',
                data: topTransactions
            });
        } catch (error) {
            console.error('Error in getTopTransactions:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy top giao dịch',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/personal/comparison
     * So sánh kỳ này vs kỳ trước
     */
    async getPeriodComparison(req, res) {
        try {
            const userId = req.userId;
            const { currentStart, currentEnd } = req.query;

            if (!currentStart || !currentEnd) {
                return res.status(400).json({ error: 'currentStart và currentEnd là bắt buộc' });
            }

            const current_start = new Date(currentStart);
            const current_end = new Date(currentEnd);
            const periodLength = current_end - current_start;

            const previous_end = new Date(current_start.getTime() - 1);
            const previous_start = new Date(previous_end.getTime() - periodLength);

            // Current period
            const [currentIncome, currentExpense] = await Promise.all([
                Transaction.aggregate([
                    {
                        $match: {
                            userId,
                            type: 'income',
                            date: { $gte: current_start, $lte: current_end },
                            isDeleted: { $ne: true }
                        }
                    },
                    { $group: { _id: null, total: { $sum: '$amount' } } }
                ]),
                Transaction.aggregate([
                    {
                        $match: {
                            userId,
                            type: 'expense',
                            date: { $gte: current_start, $lte: current_end },
                            isDeleted: { $ne: true }
                        }
                    },
                    { $group: { _id: null, total: { $sum: '$amount' } } }
                ])
            ]);

            // Previous period
            const [previousIncome, previousExpense] = await Promise.all([
                Transaction.aggregate([
                    {
                        $match: {
                            userId,
                            type: 'income',
                            date: { $gte: previous_start, $lte: previous_end },
                            isDeleted: { $ne: true }
                        }
                    },
                    { $group: { _id: null, total: { $sum: '$amount' } } }
                ]),
                Transaction.aggregate([
                    {
                        $match: {
                            userId,
                            type: 'expense',
                            date: { $gte: previous_start, $lte: previous_end },
                            isDeleted: { $ne: true }
                        }
                    },
                    { $group: { _id: null, total: { $sum: '$amount' } } }
                ])
            ]);

            const currentIncomeTotal = currentIncome[0]?.total || 0;
            const currentExpenseTotal = currentExpense[0]?.total || 0;
            const previousIncomeTotal = previousIncome[0]?.total || 0;
            const previousExpenseTotal = previousExpense[0]?.total || 0;

            const incomeChange = previousIncomeTotal > 0
                ? (((currentIncomeTotal - previousIncomeTotal) / previousIncomeTotal) * 100).toFixed(2)
                : 0;
            const expenseChange = previousExpenseTotal > 0
                ? (((currentExpenseTotal - previousExpenseTotal) / previousExpenseTotal) * 100).toFixed(2)
                : 0;

            return res.status(200).json({
                message: 'So sánh kỳ thành công',
                data: {
                    currentPeriod: {
                        startDate: current_start,
                        endDate: current_end,
                        income: currentIncomeTotal,
                        expense: currentExpenseTotal,
                        net: currentIncomeTotal - currentExpenseTotal
                    },
                    previousPeriod: {
                        startDate: previous_start,
                        endDate: previous_end,
                        income: previousIncomeTotal,
                        expense: previousExpenseTotal,
                        net: previousIncomeTotal - previousExpenseTotal
                    },
                    change: {
                        income: {
                            amount: currentIncomeTotal - previousIncomeTotal,
                            percentage: incomeChange
                        },
                        expense: {
                            amount: currentExpenseTotal - previousExpenseTotal,
                            percentage: expenseChange
                        }
                    }
                }
            });
        } catch (error) {
            console.error('Error in getPeriodComparison:', error);
            return res.status(500).json({
                error: 'Lỗi khi so sánh kỳ',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/personal/payment-method
     * Phân tích theo phương thức thanh toán
     */
    async getAnalyticsByPaymentMethod(req, res) {
        try {
            const userId = req.userId;
            const { startDate, endDate, type = 'expense' } = req.query;

            const matchFilter = {
                userId,
                type,
                isDeleted: { $ne: true }
            };

            if (startDate || endDate) {
                matchFilter.date = {};
                if (startDate) matchFilter.date.$gte = new Date(startDate);
                if (endDate) matchFilter.date.$lte = new Date(endDate);
            }

            const paymentStats = await Transaction.aggregate([
                { $match: matchFilter },
                {
                    $group: {
                        _id: '$paymentMethod',
                        total: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                },
                { $sort: { total: -1 } }
            ]);

            const totalResult = await Transaction.aggregate([
                { $match: matchFilter },
                { $group: { _id: null, grandTotal: { $sum: '$amount' } } }
            ]);
            const grandTotal = totalResult[0]?.grandTotal || 0;

            const result = paymentStats.map(stat => ({
                paymentMethod: stat._id || 'cash',
                total: stat.total,
                count: stat.count,
                percentage: grandTotal > 0 ? ((stat.total / grandTotal) * 100).toFixed(2) : 0
            }));

            return res.status(200).json({
                message: 'Lấy phân tích theo phương thức thanh toán thành công',
                data: {
                    type,
                    methods: result,
                    grandTotal
                }
            });
        } catch (error) {
            console.error('Error in getAnalyticsByPaymentMethod:', error);
            return res.status(500).json({
                error: 'Lỗi khi phân tích theo phương thức thanh toán',
                details: error.message
            });
        }
    }
}

export default new AnalyticsController();