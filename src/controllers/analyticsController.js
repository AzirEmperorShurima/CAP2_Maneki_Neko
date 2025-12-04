import analyticsService from "../services/analyticsService.js";
import { models_list } from "../models/models_list.js";

const { Family } = models_list;

class AnalyticsController {
    /**
     * GET /api/analytics/overview
     * Lấy tổng quan tài chính
     */
    async getOverview(req, res) {
        try {
            const userId = req.user.id;
            const {
                startDate,
                endDate,
                includeFamily = 'false',
                familyId
            } = req.query;

            const options = {
                startDate: startDate ? new Date(startDate) : undefined,
                endDate: endDate ? new Date(endDate) : undefined,
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId
            };

            // Kiểm tra quyền truy cập family nếu includeFamily = true
            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const overview = await analyticsService.getFinancialOverview(userId, options);

            return res.status(200).json({
                message: 'Lấy tổng quan tài chính thành công',
                data: overview
            });
        } catch (error) {
            console.error('Error in getOverview:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy tổng quan tài chính',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/expense-by-category
     * Phân tích chi tiêu theo danh mục
     */
    async getExpenseByCategory(req, res) {
        try {
            const userId = req.user.id;
            const {
                startDate,
                endDate,
                includeFamily = 'false',
                familyId,
                limit = '10'
            } = req.query;

            const options = {
                startDate: startDate ? new Date(startDate) : undefined,
                endDate: endDate ? new Date(endDate) : undefined,
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId,
                limit: parseInt(limit)
            };

            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const data = await analyticsService.getExpenseByCategory(userId, options);

            return res.status(200).json({
                message: 'Phân tích chi tiêu theo danh mục thành công',
                data
            });
        } catch (error) {
            console.error('Error in getExpenseByCategory:', error);
            return res.status(500).json({
                error: 'Lỗi khi phân tích chi tiêu theo danh mục',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/income-by-category
     * Phân tích thu nhập theo danh mục
     */
    async getIncomeByCategory(req, res) {
        try {
            const userId = req.user.id;
            const {
                startDate,
                endDate,
                includeFamily = 'false',
                familyId
            } = req.query;

            const options = {
                startDate: startDate ? new Date(startDate) : undefined,
                endDate: endDate ? new Date(endDate) : undefined,
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId
            };

            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const data = await analyticsService.getIncomeByCategory(userId, options);

            return res.status(200).json({
                message: 'Phân tích thu nhập theo danh mục thành công',
                data
            });
        } catch (error) {
            console.error('Error in getIncomeByCategory:', error);
            return res.status(500).json({
                error: 'Lỗi khi phân tích thu nhập theo danh mục',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/spending-trend
     * Xu hướng chi tiêu theo thời gian
     */
    async getSpendingTrend(req, res) {
        try {
            const userId = req.user.id;
            const {
                startDate,
                endDate,
                groupBy = 'day',
                includeFamily = 'false',
                familyId
            } = req.query;

            const options = {
                startDate: startDate ? new Date(startDate) : undefined,
                endDate: endDate ? new Date(endDate) : undefined,
                groupBy,
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId
            };

            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const data = await analyticsService.getSpendingTrend(userId, options);

            return res.status(200).json({
                message: 'Lấy xu hướng chi tiêu thành công',
                data
            });
        } catch (error) {
            console.error('Error in getSpendingTrend:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy xu hướng chi tiêu',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/comparison
     * So sánh với kỳ trước
     */
    async getComparison(req, res) {
        try {
            const userId = req.user.id;
            const {
                currentStart,
                currentEnd,
                includeFamily = 'false',
                familyId
            } = req.query;

            const options = {
                currentStart: currentStart ? new Date(currentStart) : undefined,
                currentEnd: currentEnd ? new Date(currentEnd) : undefined,
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId
            };

            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const data = await analyticsService.getComparisonWithPreviousPeriod(userId, options);

            return res.status(200).json({
                message: 'So sánh với kỳ trước thành công',
                data
            });
        } catch (error) {
            console.error('Error in getComparison:', error);
            return res.status(500).json({
                error: 'Lỗi khi so sánh với kỳ trước',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/budget-status
     * Trạng thái ngân sách
     */
    async getBudgetStatus(req, res) {
        try {
            const userId = req.user.id;
            const {
                startDate,
                endDate,
                includeFamily = 'false',
                familyId
            } = req.query;

            const options = {
                startDate: startDate ? new Date(startDate) : undefined,
                endDate: endDate ? new Date(endDate) : undefined,
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId
            };

            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const data = await analyticsService.getBudgetStatus(userId, options);

            return res.status(200).json({
                message: 'Lấy trạng thái ngân sách thành công',
                data
            });
        } catch (error) {
            console.error('Error in getBudgetStatus:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy trạng thái ngân sách',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/goals-progress
     * Tiến độ mục tiêu
     */
    async getGoalsProgress(req, res) {
        try {
            const userId = req.user.id;
            const {
                includeFamily = 'false',
                familyId,
                status = 'active'
            } = req.query;

            const options = {
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId,
                status: status.split(',')
            };

            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const data = await analyticsService.getGoalsProgress(userId, options);

            return res.status(200).json({
                message: 'Lấy tiến độ mục tiêu thành công',
                data
            });
        } catch (error) {
            console.error('Error in getGoalsProgress:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy tiến độ mục tiêu',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/wallet-analytics
     * Phân tích ví
     */
    async getWalletAnalytics(req, res) {
        try {
            const userId = req.user.id;
            const {
                includeFamily = 'false',
                familyId
            } = req.query;

            const options = {
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId
            };

            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const data = await analyticsService.getWalletAnalytics(userId, options);

            return res.status(200).json({
                message: 'Lấy phân tích ví thành công',
                data
            });
        } catch (error) {
            console.error('Error in getWalletAnalytics:', error);
            return res.status(500).json({
                error: 'Lỗi khi phân tích ví',
                details: error.message
            });
        }
    }

    /**
     * GET /api/analytics/top-transactions
     * Top giao dịch
     */
    async getTopTransactions(req, res) {
        try {
            const userId = req.user.id;
            const {
                startDate,
                endDate,
                includeFamily = 'false',
                familyId,
                type = 'expense',
                limit = '5'
            } = req.query;

            const options = {
                startDate: startDate ? new Date(startDate) : undefined,
                endDate: endDate ? new Date(endDate) : undefined,
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId,
                type,
                limit: parseInt(limit)
            };

            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const data = await analyticsService.getTopTransactions(userId, options);

            return res.status(200).json({
                message: 'Lấy top giao dịch thành công',
                data
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
     * GET /api/analytics/full-report
     * Báo cáo tổng hợp đầy đủ
     */
    async getFullReport(req, res) {
        try {
            const userId = req.user.id;
            const {
                startDate,
                endDate,
                includeFamily = 'false',
                familyId
            } = req.query;

            const options = {
                startDate: startDate ? new Date(startDate) : undefined,
                endDate: endDate ? new Date(endDate) : undefined,
                includeFamily: includeFamily === 'true',
                familyId: familyId || req.user.familyId
            };

            if (options.includeFamily && options.familyId) {
                const family = await Family.findById(options.familyId);
                if (!family || !family.isMember(userId)) {
                    return res.status(403).json({
                        error: 'Bạn không có quyền truy cập dữ liệu gia đình này'
                    });
                }
            }

            const data = await analyticsService.getFullReport(userId, options);

            return res.status(200).json({
                message: 'Lấy báo cáo tổng hợp thành công',
                data
            });
        } catch (error) {
            console.error('Error in getFullReport:', error);
            return res.status(500).json({
                error: 'Lỗi khi lấy báo cáo tổng hợp',
                details: error.message
            });
        }
    }
}

export default new AnalyticsController();
