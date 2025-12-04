// controllers/budgetController.js
import Budget from '../models/budget.js';
import Family from '../models/family.js';
import dayjs from 'dayjs';
import isBetween from 'dayjs/plugin/isBetween.js';
import timezone from 'dayjs/plugin/timezone.js';
import utc from 'dayjs/plugin/utc.js';
import weekday from 'dayjs/plugin/weekday.js';
import { validateCreateBudget, validateUpdateBudget, validateGetBudgetsQuery } from '../validations/budget.js';

dayjs.extend(isBetween);
dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.extend(weekday);

// Cấu hình tuần bắt đầu từ Thứ Hai
dayjs.Ls.en.weekStart = 1;

const VIETNAM_TZ = 'Asia/Ho_Chi_Minh';

/**
 * Kiểm tra xem có budget trùng khoảng thời gian không
 * Budget trùng khi: có cùng userId, type, categoryId, parentBudgetId và khoảng thời gian giao nhau
 */
const findOverlappingBudget = async (userId, type, periodStart, periodEnd, categoryId, parentBudgetId, excludeBudgetId = null) => {
    const query = {
        userId,
        type,
        isActive: true,
        periodStart: { $lt: periodEnd },
        periodEnd: { $gt: periodStart }
    };

    if (excludeBudgetId) {
        query._id = { $ne: excludeBudgetId };
    }

    if (categoryId !== undefined) {
        query.categoryId = categoryId || null;
    } else {
        query.categoryId = null;
    }

    if (parentBudgetId !== undefined) {
        query.parentBudgetId = parentBudgetId || null;
    } else {
        query.parentBudgetId = null;
    }

    console.log('🔍 Finding overlapping budget with query:', JSON.stringify(query, null, 2));

    return await Budget.findOne(query).populate('categoryId parentBudgetId');
};


/**
 * Tính toán period start và end dựa trên type và input date
 */
const calculatePeriod = (type, inputStart, inputEnd) => {
    const vietnamTz = VIETNAM_TZ;
    let periodStart, periodEnd;

    if (!inputStart || !inputEnd) {
        // Tự động tính toán dựa trên thời điểm hiện tại
        const now = dayjs().tz(vietnamTz);

        switch (type) {
            case 'daily':
                periodStart = now.startOf('day').toDate();
                periodEnd = now.endOf('day').toDate();
                break;
            case 'weekly':
                // Tuần bắt đầu từ Thứ Hai (weekday 1) và kết thúc Chủ Nhật (weekday 0)
                // Nếu hôm nay là Chủ Nhật (day = 0), startOf('week') sẽ là Chủ Nhật tuần trước
                // Nên cần điều chỉnh
                const dayOfWeek = now.day(); // 0 = CN, 1 = T2, ..., 6 = T7

                if (dayOfWeek === 0) {
                    // Nếu là Chủ Nhật, tuần này là từ Thứ Hai tuần trước đến hôm nay
                    periodStart = now.subtract(6, 'day').startOf('day').toDate();
                    periodEnd = now.endOf('day').toDate();
                } else {
                    // Các ngày khác: tính từ Thứ Hai tuần này
                    const daysFromMonday = dayOfWeek - 1; // T2 = 0, T3 = 1, ..., T7 = 5
                    periodStart = now.subtract(daysFromMonday, 'day').startOf('day').toDate();
                    periodEnd = now.add(7 - dayOfWeek, 'day').endOf('day').toDate(); // Đến Chủ Nhật
                }
                break;
            case 'monthly':
                periodStart = now.startOf('month').toDate();
                periodEnd = now.endOf('month').toDate();
                break;
            default:
                throw new Error('Type phải là daily, weekly hoặc monthly');
        }
    } else {
        // Sử dụng input date và chuẩn hóa theo type
        const startDate = dayjs.tz(inputStart, vietnamTz);
        const endDate = dayjs.tz(inputEnd, vietnamTz);

        // Kiểm tra periodStart phải nhỏ hơn periodEnd
        if (startDate.isAfter(endDate)) {
            throw new Error('periodStart phải nhỏ hơn periodEnd');
        }

        // Nếu cùng một ngày hoặc muốn chuẩn hóa theo type
        if (startDate.isSame(endDate, 'day')) {
            switch (type) {
                case 'monthly':
                    periodStart = startDate.startOf('month').toDate();
                    periodEnd = startDate.endOf('month').toDate();
                    break;
                case 'weekly': {
                    const dayOfWeek = startDate.day();
                    if (dayOfWeek === 0) {
                        // Chủ Nhật
                        periodStart = startDate.subtract(6, 'day').startOf('day').toDate();
                        periodEnd = startDate.endOf('day').toDate();
                    } else {
                        // Các ngày khác
                        const daysFromMonday = dayOfWeek - 1;
                        periodStart = startDate.subtract(daysFromMonday, 'day').startOf('day').toDate();
                        periodEnd = startDate.add(7 - dayOfWeek, 'day').endOf('day').toDate();
                    }
                    break;
                }
                case 'daily':
                    periodStart = startDate.startOf('day').toDate();
                    periodEnd = startDate.endOf('day').toDate();
                    break;
                default:
                    periodStart = startDate.startOf('day').toDate();
                    periodEnd = endDate.endOf('day').toDate();
            }
        } else {
            // Khác ngày: lấy startOf day và endOf day
            periodStart = startDate.startOf('day').toDate();
            periodEnd = endDate.endOf('day').toDate();
        }
    }

    return { periodStart, periodEnd };
};

/**
 * Validate thời gian budget dựa trên type
 */
const validateBudgetPeriod = (type, periodEnd) => {
    const now = dayjs().tz(VIETNAM_TZ);
    const endDate = dayjs(periodEnd).tz(VIETNAM_TZ);

    switch (type) {
        case 'daily':
            // Không cho phép tạo cho ngày đã qua hoàn toàn
            if (endDate.isBefore(now.startOf('day'))) {
                throw new Error('Không thể tạo ngân sách hàng ngày cho ngày đã qua hoàn toàn');
            }
            break;
        case 'weekly':
            // Không cho phép tạo cho tuần đã kết thúc hoàn toàn
            if (endDate.isBefore(now.startOf('week'))) {
                throw new Error('Không thể tạo ngân sách hàng tuần cho tuần đã kết thúc hoàn toàn');
            }
            break;
        case 'monthly':
            // Cho phép tạo cho tháng hiện tại và các tháng sau
            // Không giới hạn nếu vẫn trong tháng
            break;
        default:
            throw new Error('Type không hợp lệ');
    }
};

export const createBudget = async (req, res) => {
    try {
        const { error, value } = validateCreateBudget(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }

        const {
            type,
            amount,
            categoryId,
            isShared,
            familyId: bodyFamilyId,
            parentBudgetId,
            periodStart: reqPeriodStart,
            periodEnd: reqPeriodEnd,
            updateIfExists
        } = value;

        // Tính toán period
        let periodStart, periodEnd;
        try {
            const period = calculatePeriod(type, reqPeriodStart, reqPeriodEnd);
            periodStart = period.periodStart;
            periodEnd = period.periodEnd;
        } catch (err) {
            return res.status(400).json({ error: err.message });
        }

        // Validate period
        try {
            validateBudgetPeriod(type, periodEnd);
        } catch (err) {
            return res.status(400).json({ error: err.message });
        }

        // Kiểm tra quyền gia đình
        let familyId = null;
        if (isShared) {
            const familyUser = await Family.findOne({ _id: bodyFamilyId, adminId: req.userId });
            if (!familyUser) {
                return res.status(403).json({ error: 'Chỉ admin của gia đình mới có thể tạo ngân sách chia sẻ' });
            }
            familyId = bodyFamilyId;
        }

        const normalizedCategoryId = categoryId || null;
        const normalizedParentBudgetId = parentBudgetId || null;

        // Kiểm tra budget trùng (với logic đã fix)
        const existingBudget = await findOverlappingBudget(
            req.userId,
            type,
            periodStart,
            periodEnd,
            normalizedCategoryId,
            normalizedParentBudgetId
        );

        if (existingBudget) {
            if (updateIfExists) {
                // Cập nhật budget hiện có
                existingBudget.amount = amount;

                // Kiểm tra ràng buộc parent-child
                const childBudgets = await Budget.find({
                    parentBudgetId: existingBudget._id,
                    userId: req.userId,
                    isActive: true
                });

                if (childBudgets.length > 0) {
                    const totalChildAmount = childBudgets.reduce((sum, b) => sum + b.amount, 0);
                    if (amount < totalChildAmount) {
                        return res.status(400).json({
                            error: 'Số tiền ngân sách mới không được nhỏ hơn tổng ngân sách con',
                            details: { totalChildAmount, requestedAmount: amount }
                        });
                    }
                }

                await existingBudget.save();
                const populatedBudget = await Budget.findById(existingBudget._id)
                    .populate('parentBudgetId categoryId');

                return res.status(200).json({
                    message: 'Đã cập nhật ngân sách có sẵn',
                    budget: populatedBudget,
                    isUpdated: true
                });
            } else {
                return res.status(409).json({
                    error: 'Ngân sách đã tồn tại trong khoảng thời gian này',
                    message: 'Ngân sách đã tồn tại trong khoảng thời gian này',
                    budget: existingBudget,
                    isUpdated: false
                });
            }
        }

        const overlappingBudgets = await Budget.find({
            userId: req.userId,
            type,
            isActive: true,
            categoryId: normalizedCategoryId,
            parentBudgetId: normalizedParentBudgetId,
            $or: [
                {
                    periodStart: { $lte: periodStart },
                    periodEnd: { $gte: periodStart }
                },
                {
                    periodStart: { $lte: periodEnd },
                    periodEnd: { $gte: periodEnd }
                },
                {
                    periodStart: { $gte: periodStart },
                    periodEnd: { $lte: periodEnd }
                }
            ]
        });

        if (overlappingBudgets.length > 0) {
            const deactivatedIds = overlappingBudgets.map(b => b._id);

            await Budget.updateMany(
                { _id: { $in: deactivatedIds } },
                { $set: { isActive: false } }
            );

            console.log(`🔄 Auto-deactivated ${overlappingBudgets.length} overlapping budgets`);
        }

        // Kiểm tra parentBudget
        if (normalizedParentBudgetId) {
            const parentBudget = await Budget.findOne({
                _id: normalizedParentBudgetId,
                userId: req.userId
            });

            if (!parentBudget) {
                return res.status(404).json({ error: 'Không tìm thấy ngân sách cha' });
            }

            // Kiểm tra budget con phải nằm trong khoảng thời gian của budget cha
            const parentStart = dayjs(parentBudget.periodStart);
            const parentEnd = dayjs(parentBudget.periodEnd);
            const childStart = dayjs(periodStart);
            const childEnd = dayjs(periodEnd);

            if (!childStart.isBetween(parentStart, parentEnd, null, '[]') ||
                !childEnd.isBetween(parentStart, parentEnd, null, '[]')) {
                return res.status(400).json({
                    error: 'Khoảng thời gian của budget con phải nằm trong khoảng thời gian của budget cha'
                });
            }

            // Kiểm tra tổng budget con không vượt quá parent
            const existingChildBudgets = await Budget.find({
                parentBudgetId: normalizedParentBudgetId,
                userId: req.userId,
                isActive: true
            });

            const totalChildAmount = existingChildBudgets.reduce((sum, b) => sum + b.amount, 0);

            if (totalChildAmount + amount > parentBudget.amount) {
                return res.status(400).json({
                    error: 'Tổng ngân sách con không được vượt quá ngân sách cha',
                    details: {
                        parentAmount: parentBudget.amount,
                        currentChildTotal: totalChildAmount,
                        requestedAmount: amount,
                        remaining: parentBudget.amount - totalChildAmount
                    }
                });
            }
        }

        // Tạo budget mới
        const budget = new Budget({
            userId: req.userId,
            type,
            amount,
            categoryId: normalizedCategoryId,
            familyId: familyId || null,
            isShared: isShared || false,
            parentBudgetId: normalizedParentBudgetId,
            isDerived: false,
            periodStart,
            periodEnd,
            spentAmount: 0
        });

        await budget.save();

        const populatedBudget = await Budget.findById(budget._id)
            .populate('parentBudgetId categoryId');

        res.status(201).json({
            message: 'Tạo ngân sách thành công',
            budget: populatedBudget,
            isUpdated: false,
            deactivatedCount: overlappingBudgets.length
        });

    } catch (error) {
        console.error('Lỗi tạo ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server', message: error.message });
    }
};

export const getBudgets = async (req, res) => {
    try {
        const { error, value } = validateGetBudgetsQuery(req.query);
        if (error) {
            return res.status(400).json({
                error: 'Invalid query',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }

        const { isActive, isShared, type, page: queryPage, limit: queryLimit } = value;

        // Thiết lập pagination
        const page = Math.max(1, parseInt(queryPage) || 1);
        const limit = Math.min(50, parseInt(queryLimit) || 50);
        const skip = (page - 1) * limit;

        // Base filter chỉ cần userId
        const filter = { userId: req.userId };

        // Áp dụng các bộ lọc khác nếu có
        if (isActive !== undefined) {
            filter.isActive = isActive === 'true';
        }

        if (isShared !== undefined) {
            filter.isShared = isShared === 'true';
        }

        if (type) {
            filter.type = type;
        }

        // Thực hiện query với pagination
        const [budgets, total] = await Promise.all([
            Budget.find(filter)
                .populate('categoryId', 'name')
                .populate('parentBudgetId', 'type amount')
                .sort({ type: 1, periodStart: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),

            Budget.countDocuments(filter)
        ]);

        res.json({
            success: true,
            budgets,
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit),
                hasNext: page < Math.ceil(total / limit)
            }
        });

    } catch (error) {
        console.error('Lỗi lấy danh sách ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getBudgetById = async (req, res) => {
    try {
        const { id } = req.params;
        const budget = await Budget.findOne({ _id: id, userId: req.userId })
            .populate('categoryId parentBudgetId');

        if (!budget) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách' });
        }

        // Lấy thông tin các budget con nếu có
        const childBudgets = await Budget.find({
            parentBudgetId: id,
            userId: req.userId,
            isActive: true
        }).populate('categoryId');

        const totalChildAmount = childBudgets.reduce((sum, b) => sum + b.amount, 0);
        const totalChildSpent = childBudgets.reduce((sum, b) => sum + b.spentAmount, 0);

        res.json({
            budget,
            childBudgets,
            summary: {
                totalChildAmount,
                totalChildSpent,
                remainingForChildren: budget.amount - totalChildAmount
            }
        });
    } catch (error) {
        console.error('Lỗi lấy thông tin ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const updateBudget = async (req, res) => {
    try {
        const { id } = req.params;
        const { error, value } = validateUpdateBudget(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }

        const { amount, categoryId, isActive, isShared, familyId: bodyFamilyId } = value;

        const budget = await Budget.findOne({ _id: id, userId: req.userId });
        if (!budget) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách' });
        }

        // Xử lý thay đổi trạng thái chia sẻ
        if (isShared !== undefined && isShared !== budget.isShared) {
            if (isShared) {
                const family = await Family.findOne({ _id: bodyFamilyId, adminId: req.userId });
                if (!family) {
                    return res.status(403).json({ error: 'Chỉ admin của gia đình mới có thể chia sẻ ngân sách' });
                }
                budget.familyId = bodyFamilyId;
            } else {
                budget.familyId = null;
            }
            budget.isShared = isShared;
        }

        // Kiểm tra nếu thay đổi amount và có budget con
        if (amount !== undefined && amount !== budget.amount) {
            // Nếu là budget cha, kiểm tra tổng budget con
            const childBudgets = await Budget.find({
                parentBudgetId: id,
                userId: req.userId,
                isActive: true
            });

            if (childBudgets.length > 0) {
                const totalChildAmount = childBudgets.reduce((sum, b) => sum + b.amount, 0);
                if (amount < totalChildAmount) {
                    return res.status(400).json({
                        error: 'Số tiền ngân sách mới không được nhỏ hơn tổng ngân sách con',
                        details: {
                            totalChildAmount,
                            requestedAmount: amount
                        }
                    });
                }
            }

            // Nếu là budget con, kiểm tra với budget cha
            if (budget.parentBudgetId) {
                const parentBudget = await Budget.findById(budget.parentBudgetId);
                const siblingBudgets = await Budget.find({
                    parentBudgetId: budget.parentBudgetId,
                    _id: { $ne: id },
                    userId: req.userId,
                    isActive: true
                });

                const totalSiblingAmount = siblingBudgets.reduce((sum, b) => sum + b.amount, 0);

                if (totalSiblingAmount + amount > parentBudget.amount) {
                    return res.status(400).json({
                        error: 'Tổng ngân sách con không được vượt quá ngân sách cha',
                        details: {
                            parentAmount: parentBudget.amount,
                            siblingTotal: totalSiblingAmount,
                            requestedAmount: amount,
                            remaining: parentBudget.amount - totalSiblingAmount
                        }
                    });
                }
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

        const populatedBudget = await Budget.findById(budget._id)
            .populate('categoryId parentBudgetId');

        res.json({
            message: 'Cập nhật ngân sách thành công',
            budget: populatedBudget
        });
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

        // Kiểm tra xem có budget con không
        const childBudgets = await Budget.find({
            parentBudgetId: id,
            userId: req.userId,
            isActive: true
        });

        if (childBudgets.length > 0) {
            return res.status(400).json({
                error: 'Không thể xóa ngân sách vì còn ngân sách con',
                details: {
                    childCount: childBudgets.length
                }
            });
        }

        // Thực hiện xóa budget khỏi database
        const result = await Budget.deleteOne({ _id: id, userId: req.userId });

        if (result.deletedCount === 0) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách hoặc không có quyền xóa' });
        }

        res.json({ message: 'Đã xóa ngân sách thành công' });
    } catch (error) {
        console.error('Lỗi xóa ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getActiveBudgetsForCurrentPeriod = async (req, res) => {
    try {
        const now = dayjs();
        const budgets = await Budget.find({
            userId: req.userId,
            isActive: true,
            periodStart: { $lte: now.toDate() },
            periodEnd: { $gte: now.toDate() }
        })
            .populate('categoryId parentBudgetId')
            .sort({ type: 1 });

        res.json({ budgets });
    } catch (error) {
        console.error('Lỗi lấy danh sách ngân sách hiện tại:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getBudgetSummary = async (req, res) => {
    try {
        const { id } = req.params;
        const budget = await Budget.findOne({ _id: id, userId: req.userId })
            .populate('categoryId parentBudgetId');

        if (!budget) {
            return res.status(404).json({ error: 'Không tìm thấy ngân sách' });
        }

        const childBudgets = await Budget.find({
            parentBudgetId: id,
            userId: req.userId,
            isActive: true
        }).populate('categoryId');

        const totalChildAmount = childBudgets.reduce((sum, b) => sum + b.amount, 0);
        const totalChildSpent = childBudgets.reduce((sum, b) => sum + b.spentAmount, 0);
        const remainingForChildren = budget.amount - totalChildAmount;
        const percentUsed = budget.amount > 0 ? (budget.spentAmount / budget.amount * 100).toFixed(2) : 0;

        res.json({
            budget,
            childBudgets,
            summary: {
                totalChildAmount,
                totalChildSpent,
                remainingForChildren,
                percentUsed: parseFloat(percentUsed),
                isOverBudget: budget.spentAmount > budget.amount
            }
        });
    } catch (error) {
        console.error('Lỗi lấy thông tin tổng quan ngân sách:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};