import Transaction from '../../../models/transaction.js';
import Category from '../../../models/category.js';
import User from '../../../models/user.js';
import dayjs from 'dayjs';

export const getTransactionChartData = async (userId, month = dayjs().format('YYYY-MM'), type = 'all') => {
    try {
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ error: 'User không tồn tại' });

        const startDate = dayjs(`${month}-01`).startOf('day').toDate();
        const endDate = dayjs(`${month}-01`).endOf('month').endOf('day').toDate();

        // Match: cá nhân + shared trong gia đình
        const match = {
            date: { $gte: startDate, $lte: endDate },
            $or: [
                { userId: user._id },
                { familyId: user.familyId, isShared: true }
            ]
        };
        if (type !== 'all') match.type = type;

        // Lấy danh sách category để map tên + icon + color
        const categories = await Category.find({
            $or: [
                { scope: 'system', isDefault: true },
                { scope: 'personal', userId: user._id },
                { scope: 'family', familyId: user.familyId }
            ]
        }).select('_id name icon color type');

        const catMap = {};
        categories.forEach(c => {
            catMap[c._id.toString()] = {
                name: c.name,
            };
        });

        // Aggregation theo ngày và category
        const dailyData = await Transaction.aggregate([
            { $match: match },
            {
                $group: {
                    _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
                    total: { $sum: '$amount' }
                }
            },
            { $sort: { _id: 1 } }
        ]);

        const categoryData = await Transaction.aggregate([
            { $match: match },
            {
                $group: {
                    _id: '$categoryId',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            },
            { $sort: { total: -1 } }
        ]);

        // Format daily trend (đủ 30/31 ngày)
        const daysInMonth = dayjs(endDate).date();
        const dailyMap = dailyData.reduce((acc, d) => {
            acc[d._id] = d.total;
            return acc;
        }, {});

        const dailyTrend = [];
        for (let i = 1; i <= daysInMonth; i++) {
            const dateStr = dayjs(startDate).set('date', i).format('YYYY-MM-DD');
            dailyTrend.push({
                date: dateStr,
                day: i,
                total: dailyMap[dateStr] || 0
            });
        }

        // Format category data
        const byCategory = categoryData.map(item => {
            const cat = catMap[item._id?.toString()] || {
                name: 'Khác',
            };
            return {
                categoryId: item._id,
                name: cat.name,
                icon: cat.icon,
                color: cat.color,
                total: item.total,
                count: item.count
            };
        });

        const totalAmount = dailyTrend.reduce((sum, d) => sum + d.total, 0);

        return {
            success: true,
            period: month,
            type,
            totalAmount,
            transactionCount: dailyTrend.reduce((s, d) => s + (d.total > 0 ? 1 : 0), 0),
            chart: {
                dailyTrend,
                byCategory
            }
        };

    } catch (error) {
        console.error('Lỗi chart data:', error);
        return { error: 'Lỗi server' }; 
    }
};