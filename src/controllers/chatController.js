import chatMessage from '../models/chatMessage.js';
import transactions from '../models/transaction.js';
import Category from '../models/category.js';
import Budget from '../models/budget.js';
import { parseTransactionText } from '../utils/parser.js';
import { geminiClassify } from '../utils/gemini.js';
import { checkBudgetWarning } from '../utils/budget.js';
import dayjs from 'dayjs';

export const chat = async (req, res) => {
    const { message } = req.body;
    if (!message) return res.status(400).json({ error: 'Message required' });

    // const userMsg = new chatMessage({ userId: req.userId, role: 'user', content: message });
    // await userMsg.save();

    let reply = '';
    let transaction = null;
    let category = null;

    // === 1. Rule-based: thử parse trước ===
    const rule = parseTransactionText(message.toLowerCase());
    console.log('Parsed rule:', rule);


    if (rule.valid) {
        // Tìm category theo keyword trong DB
        category = await findCategoryByKeywords(rule.keywords, rule.type);
        console.log('Found category:', category);
    }

    // === 2. Nếu Rule không hiểu → gọi Gemini ===
    if (!category && rule.valid) {
        const gemini = await geminiClassify(message);
        if (gemini && gemini.confidence > 0.8) {
            // Cập nhật amount/description nếu Gemini tốt hơn
            rule.amount = gemini.amount || rule.amount;
            rule.description = gemini.description || rule.description;
            rule.keywords = [...new Set([...rule.keywords, ...(gemini.keywords || [])])];

            // Tìm hoặc tạo category
            category = await Category.findOne({ name: gemini.category, type: gemini.type });
            if (!category) {
                category = await new Category({
                    name: gemini.category,
                    type: gemini.type,
                    keywords: gemini.keywords || []
                }).save();
            } else {
                // SELF-LEARNING: Cập nhật keywords từ Gemini
                const newKeywords = gemini.keywords.filter(kw => !category.keywords.includes(kw));
                if (newKeywords.length > 0) {
                    category.keywords.push(...newKeywords);
                    await category.save();
                }
            }
        }
        else if (gemini) {
            // Nếu confidence thấp, fallback về category 'Khác' và gợi ý user chỉnh sửa
            category = await Category.findOne({ name: 'Khác', type: rule.type });
            reply += '\nConfidence thấp, tôi tạm phân loại vào "Khác". Bạn có thể chỉnh sửa sau.';
        }
    }

    // === 3. Tạo giao dịch nếu có category ===
    if (category) {
        transaction = new transactions({
            userId: req.userId,
            amount: rule.amount,
            categoryId: category._id,
            date: rule.date,
            description: rule.description,
            type: rule.type,
            source: 'chat',
            rawText: message,
            confidence: category ? 1.0 : 0.7
        });
        // await transaction.save();

        const warning = await checkBudgetWarning(req.userId, transaction);
        reply = `Đã ghi **${rule.amount.toLocaleString()}đ** vào **${category.name}**.\n${warning}`;
    }

    // === 4. Xử lý lệnh set ngân sách ===
    else if (message.match(/set|ngân sách|tiêu tối đa|goal|tiết kiệm/i)) {
        // Budget tổng hoặc per category: e.g., "budget ăn uống 2tr/tháng" or "set 100k/ngày"
        const budgetMatch = message.match(/(budget|ngân sách)?\s*(\w+)?\s*(\d+(?:\.\d+)?)\s*(k|tr|nghìn|triệu)?\s*(ngày|tuần|tháng)/i);
        const goalMatch = message.match(/(goal|tiết kiệm)\s*(\w+)\s*(\d+(?:\.\d+)?)\s*(k|tr|nghìn|triệu)?\s*(trong\s*(\d+)\s*(tháng|ngày|tuần)?)/i);

        if (budgetMatch) {
            const categoryName = budgetMatch[2];
            let amount = parseFloat(budgetMatch[3]);
            const unit = budgetMatch[4]?.toLowerCase();
            const period = budgetMatch[5].toLowerCase();

            if (unit === 'k' || unit === 'nghìn') amount *= 1000;
            else if (unit === 'tr' || unit === 'triệu') amount *= 1000000;

            const typeMap = { 'ngày': 'daily', 'tuần': 'weekly', 'tháng': 'monthly' };
            const type = typeMap[period];

            if (!type) {
                reply = 'Khoảng thời gian không hợp lệ. Hãy dùng: ngày, tuần, tháng.';
            } else {
                let categoryId = null;
                if (categoryName) {
                    const category = await Category.findOne({ name: { $regex: new RegExp(categoryName, 'i') }, type: 'expense' });
                    if (!category) {
                        reply = `Không tìm thấy danh mục "${categoryName}".`;
                        // Có thể tạo mới nếu muốn
                    } else {
                        categoryId = category._id;
                    }
                }

                if (categoryId || !categoryName) {
                    // await Budget.findOneAndUpdate(
                    //     { userId: req.userId, type, categoryId },
                    //     { amount },
                    //     { upsert: true, new: true }
                    // );
                    reply = `Đã đặt ngân sách **${amount.toLocaleString()}đ/${period}** ${categoryName ? `cho ${categoryName}` : ''}. Tôi sẽ nhắc bạn!`;
                }
            }
        } else if (goalMatch) {
            const goalName = goalMatch[2];
            let targetAmount = parseFloat(goalMatch[3]);
            const unit = goalMatch[4]?.toLowerCase();
            const duration = parseInt(goalMatch[6]);
            const durationUnit = goalMatch[7]?.toLowerCase();

            if (unit === 'k' || unit === 'nghìn') targetAmount *= 1000;
            else if (unit === 'tr' || unit === 'triệu') targetAmount *= 1000000;

            let deadline = dayjs();
            if (durationUnit.includes('tháng')) deadline = deadline.add(duration, 'month');
            else if (durationUnit.includes('tuần')) deadline = deadline.add(duration, 'week');
            else deadline = deadline.add(duration, 'day');

            // await Budget.findOneAndUpdate(
            //     { userId: req.userId, 'goal.name': goalName },
            //     {
            //         'goal.targetAmount': targetAmount,
            //         'goal.deadline': deadline.toDate(),
            //         'goal.currentProgress': 0
            //     },
            //     { upsert: true, new: true }
            // );

            reply = `Đã đặt goal **${goalName}**: tiết kiệm **${targetAmount.toLocaleString()}đ** trong ${duration} ${durationUnit}.`;
        } else {
            reply = 'Cú pháp: `budget ăn uống 2tr/tháng` hoặc `goal du lịch 10tr trong 6 tháng` hoặc `set 100k/ngày`';
        }
    }

    // === 5. Không hiểu gì cả ===
    else {
        reply = 'Tôi chưa hiểu. Hãy thử:\n• `mua cơm 25k`\n• `mẹ cho 500k`\n• `set 100k/ngày`';
    }

    // Lưu phản hồi AI
    // const aiMsg = new chatMessage({
    //     userId: req.userId,
    //     role: 'assistant',
    //     content: reply,
    //     transactionId: transaction?._id
    // });
    // await aiMsg.save();

    res.json({
        reply,
        transaction: transaction ? {
            amount: transaction.amount,
            category: category.name,
            type: transaction.type,
            confidence: transaction.confidence
        } : null
    });
}

// === Tìm category theo keyword ===
async function findCategoryByKeywords(keywords, type) {
    if (!keywords.length) return null;
    // Tìm category có nhiều keywords match nhất
    const categories = await Category.aggregate([
        { $match: { type } },
        { $addFields: { matchCount: { $size: { $setIntersection: ["$keywords", keywords] } } } },
        { $sort: { matchCount: -1 } },
        { $limit: 1 }
    ]);
    return categories.length > 0 && categories[0].matchCount > 0 ? categories[0] : null;
}
