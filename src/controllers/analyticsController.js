import mongoose from "mongoose";
import Transaction from "../models/transaction.js";
import Wallet from "../models/wallet.js";
import Category from "../models/category.js";

class AnalyticsController {
    constructor() {
        this.getPersonalOverview = this.getPersonalOverview.bind(this);
        this.getPersonalSpendingTrend = this.getPersonalSpendingTrend.bind(this);
        this.getAnalyticsByWallet = this.getAnalyticsByWallet.bind(this);
        this.getWalletDetailedAnalytics = this.getWalletDetailedAnalytics.bind(this);
        this.getAnalyticsByCategory = this.getAnalyticsByCategory.bind(this);
        this.getTopTransactions = this.getTopTransactions.bind(this);
        this.getPeriodComparison = this.getPeriodComparison.bind(this);
        this.getAnalyticsByPaymentMethod = this.getAnalyticsByPaymentMethod.bind(this);
    }

    /**
     * Helper: Convert userId to ObjectId
     */
    _toObjectId(id) {
        return mongoose.Types.ObjectId.isValid(id)
            ? new mongoose.Types.ObjectId(String(id))
            : id;
    }

    /**
     * Helper: Build base filter for personal transactions
     */
    _buildPersonalFilter(userId, options = {}) {
        const { startDate, endDate, walletId, type } = options;

        const filter = {
            userId: this._toObjectId(userId),
            $or: [
                { isShared: false },
                { isShared: { $exists: false } }
            ]
        };

        if (startDate || endDate) {
            filter.date = {};
            if (startDate) filter.date.$gte = new Date(startDate);
            if (endDate) filter.date.$lte = new Date(endDate);
        }

        if (walletId) {
            filter.walletId = this._toObjectId(walletId);
        }

        if (type) {
            filter.type = type;
        }

        return filter;
    }

    /**
     * GET /api/analytics/personal/overview
     * Tổng quan tài chính CÁ NHÂN
     */
    async getPersonalOverview(req, res) {
        try {
            const userId = req.userId;
            const {
                startDate,
                endDate,
                walletId,
                includePeriodBreakdown = 'false',
                breakdownType = 'month'
            } = req.query;

            const dateFilter = this._buildPersonalFilter(userId, { startDate, endDate, walletId });

            console.log('📊 getPersonalOverview - filter:', JSON.stringify(dateFilter));

            // ===== 1. TỔNG QUAN TOÀN BỘ DATA =====
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
                userId: this._toObjectId(userId),
                isActive: true,
                isShared: false
            });

            const totalBalance = wallets.reduce((sum, w) => sum + (w.balance || 0), 0);

            const overallSummary = {
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
            };

            // ===== 2. BREAKDOWN THEO THÁNG/NĂM =====
            let periodBreakdown = null;

            if (includePeriodBreakdown === 'true') {
                const breakdownFilter = this._buildPersonalFilter(userId, { startDate, endDate, walletId });

                let groupByFormat;
                let sortField;

                if (breakdownType === 'year') {
                    groupByFormat = { $year: '$date' };
                    sortField = '_id';
                } else {
                    groupByFormat = {
                        year: { $year: '$date' },
                        month: { $month: '$date' }
                    };
                    sortField = '_id.year';
                }

                const breakdown = await Transaction.aggregate([
                    { $match: breakdownFilter },
                    {
                        $group: {
                            _id: {
                                period: groupByFormat,
                                type: '$type'
                            },
                            total: { $sum: '$amount' },
                            count: { $sum: 1 }
                        }
                    },
                    { $sort: { [sortField]: -1, '_id.period': -1 } }
                ]);

                const formattedBreakdown = {};
                breakdown.forEach(item => {
                    let periodKey;
                    let periodLabel;

                    if (breakdownType === 'year') {
                        periodKey = item._id.period;
                        periodLabel = `Năm ${item._id.period}`;
                    } else {
                        // month
                        const year = item._id.period.year;
                        const month = item._id.period.month;
                        periodKey = `${year}-${String(month).padStart(2, '0')}`;
                        periodLabel = `Tháng ${month}/${year}`;
                    }

                    if (!formattedBreakdown[periodKey]) {
                        formattedBreakdown[periodKey] = {
                            period: periodLabel,
                            periodKey,
                            income: 0,
                            expense: 0,
                            incomeCount: 0,
                            expenseCount: 0
                        };
                    }

                    if (item._id.type === 'income') {
                        formattedBreakdown[periodKey].income = item.total;
                        formattedBreakdown[periodKey].incomeCount = item.count;
                    } else {
                        formattedBreakdown[periodKey].expense = item.total;
                        formattedBreakdown[periodKey].expenseCount = item.count;
                    }
                });

                // Add net balance and sort
                periodBreakdown = Object.values(formattedBreakdown)
                    .map(item => ({
                        ...item,
                        net: item.income - item.expense,
                        totalTransactions: item.incomeCount + item.expenseCount
                    }))
                    .sort((a, b) => b.periodKey.localeCompare(a.periodKey)); // Sort descending
            }

            // ===== 3. RESPONSE =====
            const response = {
                message: 'Lấy tổng quan tài chính cá nhân thành công',
                data: {
                    overall: overallSummary
                }
            };

            if (periodBreakdown) {
                response.data.breakdown = {
                    type: breakdownType,
                    periods: periodBreakdown
                };
            }

            return res.status(200).json(response);

        } catch (error) {
            console.error('❌ Error in getPersonalOverview:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy tổng quan tài chính cá nhân',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/personal/spending-trend
     * Xu hướng chi tiêu cá nhân theo thời gian
     */
    async getPersonalSpendingTrend(req, res) {
        try {
            const userId = req.userId;
            const { startDate, endDate, groupBy = 'day', walletId } = req.query;

            const matchFilter = this._buildPersonalFilter(userId, { startDate, endDate, walletId });

            // Xác định format groupBy
            let dateFormat;
            switch (groupBy) {
                case 'week':
                    dateFormat = {
                        year: { $year: '$date' },
                        week: { $isoWeek: '$date' }
                    };
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
                const period = typeof item._id.period === 'object'
                    ? `${item._id.period.year}-W${item._id.period.week}`
                    : item._id.period;

                if (!formattedData[period]) {
                    formattedData[period] = {
                        period,
                        income: 0,
                        expense: 0,
                        incomeCount: 0,
                        expenseCount: 0
                    };
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
            console.error('❌ Error in getPersonalSpendingTrend:', error);
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

            const dateFilter = this._buildPersonalFilter(userId, { startDate, endDate });

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
                userId: this._toObjectId(userId),
                isShared: false
            }).lean();

            // Map data
            const walletMap = {};
            wallets.forEach(w => {
                walletMap[w._id.toString()] = {
                    walletId: w._id,
                    walletName: w.name,
                    walletType: w.type,
                    walletIcon: w.icon || '',
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
            console.error('❌ Error in getAnalyticsByWallet:', error);
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

            const wallet = await Wallet.findOne({
                _id: this._toObjectId(walletId),
                userId: this._toObjectId(userId),
                isShared: false
            }).lean();

            if (!wallet) {
                return res.status(404).json({
                    error: 'Không tìm thấy ví hoặc không có quyền truy cập'
                });
            }

            const dateFilter = this._buildPersonalFilter(userId, {
                startDate,
                endDate,
                walletId
            });

            const [analyticsResult, dailyTrendResult] = await Promise.all([
                Transaction.aggregate([
                    { $match: dateFilter },
                    {
                        $facet: {
                            summary: [
                                {
                                    $group: {
                                        _id: '$type',
                                        total: { $sum: '$amount' },
                                        count: { $sum: 1 }
                                    }
                                }
                            ],
                            categoryBreakdown: [
                                {
                                    $group: {
                                        _id: {
                                            type: '$type',
                                            categoryId: '$categoryId'
                                        },
                                        total: { $sum: '$amount' },
                                        count: { $sum: 1 }
                                    }
                                },
                                { $sort: { total: -1 } },
                                {
                                    $lookup: {
                                        from: 'categories',
                                        localField: '_id.categoryId',
                                        foreignField: '_id',
                                        as: 'categoryInfo'
                                    }
                                },
                                {
                                    $unwind: {
                                        path: '$categoryInfo',
                                        preserveNullAndEmptyArrays: true
                                    }
                                },
                                {
                                    $project: {
                                        type: '$_id.type',
                                        categoryId: '$_id.categoryId',
                                        categoryName: {
                                            $ifNull: ['$categoryInfo.name', 'Không phân loại']
                                        },
                                        image: {
                                            $ifNull: ['$categoryInfo.image', '']
                                        },
                                        total: 1,
                                        count: 1
                                    }
                                }
                            ]
                        }
                    }
                ]),
                Transaction.aggregate([
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
                    { $limit: 28 }
                ])
            ]);

            // Xử lý dữ liệu analytics
            const facetResult = analyticsResult[0] || { summary: [], categoryBreakdown: [] };

            // Tính tổng income và expense từ summary
            let totalIncome = 0;
            let incomeCount = 0;
            let totalExpense = 0;
            let expenseCount = 0;

            facetResult.summary.forEach(item => {
                if (item._id === 'income') {
                    totalIncome = item.total || 0;
                    incomeCount = item.count || 0;
                } else if (item._id === 'expense') {
                    totalExpense = item.total || 0;
                    expenseCount = item.count || 0;
                }
            });

            const net = totalIncome - totalExpense;

            // Xử lý expenseByCategory
            const expenseByCategory = facetResult.categoryBreakdown
                .filter(c => c.type === 'expense')
                .map(c => ({
                    categoryId: c.categoryId,
                    categoryName: c.categoryName,
                    image: c.image || '',
                    total: c.total,
                    count: c.count,
                    percentage: totalExpense > 0
                        ? ((c.total / totalExpense) * 100).toFixed(2)
                        : '0.00'
                }));

            // Xử lý incomeByCategory
            const incomeByCategory = facetResult.categoryBreakdown
                .filter(c => c.type === 'income')
                .map(c => ({
                    categoryId: c.categoryId,
                    categoryName: c.categoryName,
                    image: c.image || '',
                    total: c.total,
                    count: c.count,
                    percentage: totalIncome > 0
                        ? ((c.total / totalIncome) * 100).toFixed(2)
                        : '0.00'
                }));

            // Xử lý dailyTrend
            const dailyMap = {};
            dailyTrendResult.forEach(d => {
                if (!dailyMap[d._id.date]) {
                    dailyMap[d._id.date] = { date: d._id.date, income: 0, expense: 0 };
                }
                dailyMap[d._id.date][d._id.type] = d.total;
            });

            const dailyTrend = Object.values(dailyMap)
                .sort((a, b) => b.date.localeCompare(a.date));

            return res.status(200).json({
                message: 'Lấy phân tích chi tiết ví thành công',
                data: {
                    wallet: {
                        id: wallet._id,
                        name: wallet.name,
                        type: wallet.type,
                        icon: wallet.icon || '',
                        currentBalance: wallet.balance
                    },
                    summary: {
                        totalIncome,
                        totalExpense,
                        incomeCount,
                        expenseCount,
                        net
                    },
                    expenseByCategory,
                    incomeByCategory,
                    dailyTrend
                }
            });

        } catch (error) {
            console.error('❌ Error in getWalletDetailedAnalytics:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy phân tích chi tiết ví',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/personal/by-category
     * Phân tích chi tiêu theo danh mục
     */
    async getAnalyticsByCategory(req, res) {
        try {
            const userId = req.userId;
            const { startDate, endDate, type = 'expense', limit = '10' } = req.query;

            const matchFilter = this._buildPersonalFilter(userId, {
                startDate,
                endDate,
                type
            });

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

            // Get total for percentage
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
                categoryName: stat._id
                    ? categoryMap[stat._id.toString()]?.name || 'Không xác định'
                    : 'Không phân loại',
                image: categoryMap[stat._id.toString()]?.image || '',
                total: stat.total,
                count: stat.count,
                avgAmount: Math.round(stat.avgAmount),
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
            console.error('❌ Error in getAnalyticsByCategory:', error);
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

            const matchFilter = this._buildPersonalFilter(userId, {
                startDate,
                endDate,
                walletId,
                type
            });

            const topTransactions = await Transaction.find(matchFilter)
                .sort({ amount: -1 })
                .limit(parseInt(limit))
                .populate('categoryId', 'name')
                .populate('walletId', 'name icon')
                .lean();
            const normalized = topTransactions.map(t => ({
                id: t._id,
                amount: t.amount,
                type: t.type,
                date: t.date,
                description: t.description || '',
                category: t.categoryId ? {
                    id: t.categoryId._id,
                    name: t.categoryId.name || ''
                } : {
                    id: '',
                    name: ''
                },
                wallet: t.walletId ? {
                    id: t.walletId._id,
                    name: t.walletId.name || '',
                    icon: t.walletId.icon || ''
                } : {
                    id: '',
                    name: '',
                    icon: ''
                }
            }));

            return res.status(200).json({
                message: 'Lấy top giao dịch thành công',
                data: normalized
            });
        } catch (error) {
            console.error('❌ Error in getTopTransactions:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy top giao dịch',
                details: error.message
            });
        }
    }

    /**
     * Helper: Get period dates based on type
     */
    _getPeriodDates(periodType, year, period) {
        const now = new Date();
        let startDate, endDate;

        switch (periodType) {
            case 'week':
                // period: week number (1-53)
                const weekNum = period || this._getCurrentWeek(now);
                const yearNum = year || now.getFullYear();
                startDate = this._getDateOfISOWeek(weekNum, yearNum);
                endDate = new Date(startDate);
                endDate.setDate(endDate.getDate() + 6);
                break;

            case 'month':
                // period: month number (1-12)
                const monthNum = period || (now.getMonth() + 1);
                const monthYear = year || now.getFullYear();
                startDate = new Date(monthYear, monthNum - 1, 1);
                endDate = new Date(monthYear, monthNum, 0); // Last day of month
                break;

            case 'quarter':
                // period: quarter number (1-4)
                const quarterNum = period || Math.ceil((now.getMonth() + 1) / 3);
                const quarterYear = year || now.getFullYear();
                const quarterStartMonth = (quarterNum - 1) * 3;
                startDate = new Date(quarterYear, quarterStartMonth, 1);
                endDate = new Date(quarterYear, quarterStartMonth + 3, 0);
                break;

            case 'year':
                // period: ignored, use year param
                const yearValue = year || now.getFullYear();
                startDate = new Date(yearValue, 0, 1);
                endDate = new Date(yearValue, 11, 31);
                break;

            default:
                throw new Error('Invalid period type. Use: week, month, quarter, year');
        }

        return { startDate, endDate };
    }

    /**
     * Helper: Get current ISO week number
     */
    _getCurrentWeek(date) {
        const d = new Date(date);
        d.setHours(0, 0, 0, 0);
        d.setDate(d.getDate() + 4 - (d.getDay() || 7));
        const yearStart = new Date(d.getFullYear(), 0, 1);
        return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
    }

    /**
     * Helper: Get date of ISO week
     */
    _getDateOfISOWeek(week, year) {
        const simple = new Date(year, 0, 1 + (week - 1) * 7);
        const dow = simple.getDay();
        const ISOweekStart = simple;
        if (dow <= 4) {
            ISOweekStart.setDate(simple.getDate() - simple.getDay() + 1);
        } else {
            ISOweekStart.setDate(simple.getDate() + 8 - simple.getDay());
        }
        return ISOweekStart;
    }

    /**
     * Helper: Get period data from transactions
     */
    async _getPeriodData(userId, startDate, endDate) {
        const baseFilter = this._buildPersonalFilter(userId, {});

        const [incomeResult, expenseResult] = await Promise.all([
            Transaction.aggregate([
                {
                    $match: {
                        ...baseFilter,
                        type: 'income',
                        date: { $gte: startDate, $lte: endDate }
                    }
                },
                { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
            ]),
            Transaction.aggregate([
                {
                    $match: {
                        ...baseFilter,
                        type: 'expense',
                        date: { $gte: startDate, $lte: endDate }
                    }
                },
                { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
            ])
        ]);

        const income = incomeResult[0]?.total || 0;
        const expense = expenseResult[0]?.total || 0;
        const incomeCount = incomeResult[0]?.count || 0;
        const expenseCount = expenseResult[0]?.count || 0;

        return {
            startDate,
            endDate,
            income,
            expense,
            incomeCount,
            expenseCount,
            net: income - expense
        };
    }

    /**
     * GET /api/analytics/personal/comparison
     * So sánh nhiều kỳ cùng loại (tuần/tháng/quý/năm)
     * 
     * Query params:
     * - periodType: 'week' | 'month' | 'quarter' | 'year' (default: 'month')
     * - periods: array of period configs, e.g. 
     *   - For month: [{"year": 2024, "period": 12}, {"year": 2024, "period": 11}]
     *   - For week: [{"year": 2024, "period": 50}, {"year": 2024, "period": 49}]
     * 
     * If no periods specified, compares current period with previous period
     */
    async getPeriodComparison(req, res) {
        try {
            const userId = req.userId;
            const { periodType = 'month', periods } = req.query;

            // Validate periodType
            const validTypes = ['week', 'month', 'quarter', 'year'];
            if (!validTypes.includes(periodType)) {
                return res.status(400).json({
                    error: `periodType phải là một trong: ${validTypes.join(', ')}`
                });
            }

            let periodsToCompare = [];

            // Parse periods from query
            if (periods) {
                try {
                    periodsToCompare = JSON.parse(periods);
                    if (!Array.isArray(periodsToCompare)) {
                        return res.status(400).json({
                            error: 'periods phải là array'
                        });
                    }
                } catch (error) {
                    return res.status(400).json({
                        error: 'periods format không hợp lệ. Ví dụ: [{"year":2024,"period":12},{"year":2024,"period":11}]'
                    });
                }
            } else {
                // Default: So sánh kỳ hiện tại với kỳ trước
                const now = new Date();
                const currentYear = now.getFullYear();

                switch (periodType) {
                    case 'week':
                        const currentWeek = this._getCurrentWeek(now);
                        periodsToCompare = [
                            { year: currentYear, period: currentWeek, label: 'Tuần này' },
                            { year: currentYear, period: currentWeek - 1, label: 'Tuần trước' }
                        ];
                        break;

                    case 'month':
                        const currentMonth = now.getMonth() + 1;
                        const prevMonth = currentMonth === 1 ? 12 : currentMonth - 1;
                        const prevMonthYear = currentMonth === 1 ? currentYear - 1 : currentYear;
                        periodsToCompare = [
                            { year: currentYear, period: currentMonth, label: 'Tháng này' },
                            { year: prevMonthYear, period: prevMonth, label: 'Tháng trước' }
                        ];
                        break;

                    case 'quarter':
                        const currentQuarter = Math.ceil((now.getMonth() + 1) / 3);
                        const prevQuarter = currentQuarter === 1 ? 4 : currentQuarter - 1;
                        const prevQuarterYear = currentQuarter === 1 ? currentYear - 1 : currentYear;
                        periodsToCompare = [
                            { year: currentYear, period: currentQuarter, label: 'Quý này' },
                            { year: prevQuarterYear, period: prevQuarter, label: 'Quý trước' }
                        ];
                        break;

                    case 'year':
                        periodsToCompare = [
                            { year: currentYear, label: 'Năm nay' },
                            { year: currentYear - 1, label: 'Năm trước' }
                        ];
                        break;
                }
            }

            // Get data for each period
            const results = await Promise.all(
                periodsToCompare.map(async (config) => {
                    const { startDate, endDate } = this._getPeriodDates(
                        periodType,
                        config.year,
                        config.period
                    );

                    const data = await this._getPeriodData(userId, startDate, endDate);

                    return {
                        label: config.label || this._getPeriodLabel(periodType, config.year, config.period),
                        periodType,
                        year: config.year,
                        period: config.period,
                        ...data
                    };
                })
            );

            // Calculate changes (so với kỳ đầu tiên)
            const baselinePeriod = results[0];
            const comparisons = results.slice(1).map(period => {
                const incomeChange = baselinePeriod.income > 0
                    ? (((period.income - baselinePeriod.income) / baselinePeriod.income) * 100).toFixed(2)
                    : period.income > 0 ? 100 : 0;

                const expenseChange = baselinePeriod.expense > 0
                    ? (((period.expense - baselinePeriod.expense) / baselinePeriod.expense) * 100).toFixed(2)
                    : period.expense > 0 ? 100 : 0;

                return {
                    ...period,
                    changeVsBaseline: {
                        income: {
                            amount: period.income - baselinePeriod.income,
                            percentage: parseFloat(incomeChange)
                        },
                        expense: {
                            amount: period.expense - baselinePeriod.expense,
                            percentage: parseFloat(expenseChange)
                        },
                        net: {
                            amount: period.net - baselinePeriod.net
                        }
                    }
                };
            });

            return res.status(200).json({
                message: 'So sánh kỳ thành công',
                data: {
                    periodType,
                    baseline: baselinePeriod,
                    comparisons
                }
            });
        } catch (error) {
            console.error('❌ Error in getPeriodComparison:', error);
            return res.status(500).json({
                error: 'Lỗi khi so sánh kỳ',
                details: error.message
            });
        }
    }

    /**
     * Helper: Get period label
     */
    _getPeriodLabel(periodType, year, period) {
        switch (periodType) {
            case 'week':
                return `Tuần ${period}/${year}`;
            case 'month':
                return `Tháng ${period}/${year}`;
            case 'quarter':
                return `Quý ${period}/${year}`;
            case 'year':
                return `Năm ${year}`;
            default:
                return 'Unknown';
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

            const matchFilter = this._buildPersonalFilter(userId, {
                startDate,
                endDate,
                type
            });

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
            console.error('❌ Error in getAnalyticsByPaymentMethod:', error);
            return res.status(500).json({
                error: 'Lỗi khi phân tích theo phương thức thanh toán',
                details: error.message
            });
        }
    }
}

export default new AnalyticsController();
