import Transaction from '../models/transaction.js';
import Category from '../models/category.js';
import Budget from '../models/budget.js';
import { geminiChat } from '../utils/gemini.js';
import dayjs from 'dayjs';
import 'dayjs/locale/vi.js';
import { checkBudgetWarning } from '../utils/budget.js';
import { SYSTEM_PROMPT } from '../utils/geminiChatPrompt.js';
dayjs.locale('vi');

export const geminiChatController = async (req, res) => {
  try {
    const { message } = req.body;
    if (!message?.trim()) {
      return res.status(400).json({ error: 'Message required' });
    }
    if (!req.userId) {
      return res.status(401).json({ error: 'Bạn cần đăng nhập để ghi giao dịch' });
    }
    const chatPayload = [
      { role: 'user', parts: [{ text: `${SYSTEM_PROMPT}\n\n${message}` }] }
    ]

    const result = await geminiChat(chatPayload);
    if (!result || !result.response || typeof result.response.text !== 'function') {
      return res.status(500).json({ error: 'Chat error' });
    }

    const rawText = result.response.text().trim();

    let data;
    try {
      const jsonStr = rawText
        .replace(/^```json\s*/i, '')
        .replace(/^```\s*/i, '')
        .replace(/\s*```$/g, '')
        .trim();

      data = JSON.parse(jsonStr);
    } catch (e) {
      console.log('Gemini trả về không phải JSON sạch:', rawText);
      return res.json({
        reply: 'Xin lỗi, mình hơi bị lỗi khi hiểu tin nhắn này. Bạn thử nói lại nhé!',
      });
    }

    let reply = '';
    let transaction = null;

    // ==================================================================
    // 1. Tạo giao dịch
    // ==================================================================
    if (data.action === 'create_transaction') {
      let category = await Category.findOne({
        name: { $regex: new RegExp(`^${escapeRegExp(data.category_name)}$`, 'i') },
        type: data.type,
      });

      if (!category) {
        category = await Category.create({
          name: data.category_name,
          type: data.type,
          keywords: data.category_name.toLowerCase().split(/\s+/),
        });
        reply += `Đã tạo danh mục mới "${data.category_name}". `;
      }

      const trans = await Transaction.create({
        userId: req.userId,
        amount: data.amount,
        categoryId: category._id,
        type: data.type,
        inputType: 'ai',
        description: data.description?.trim() || message,
        date: data.date ? dayjs(data.date).toDate() : new Date(),
        source: 'chat-gemini',
        rawText: message,
        confidence: 1.0,
      });

      transaction = {
        amount: trans.amount,
        category: category.name,
        type: trans.type,
        confidence: 1.0,
      };

      const typeText = data.type === 'income' ? 'thu nhập' : 'chi tiêu';
      reply += `Đã ghi **${data.amount.toLocaleString()}đ** ${typeText} vào **${category.name}**`;

      // Kiểm tra cảnh báo ngân sách
      const warning = checkBudgetWarning?.(req.userId, trans);
      if (warning) reply += `\n${warning}`;
    }

    // ==================================================================
    // 2. Đặt ngân sách
    // ==================================================================
    else if (data.action === 'set_budget') {
      const categoryId = data.category_name
        ? (await Category.findOne({ name: { $regex: new RegExp(`^${escapeRegExp(data.category_name)}$`, 'i') } }))?._id || null
        : null;

      await Budget.findOneAndUpdate(
        { userId: req.userId, type: data.period, categoryId },
        { amount: data.amount },
        { upsert: true, new: true }
      );

      const periodVi = data.period === 'daily' ? 'ngày' : data.period === 'weekly' ? 'tuần' : 'tháng';
      const catText = data.category_name ? ` cho **${data.category_name}**` : ' tổng';

      reply = `Đã đặt ngân sách **${data.amount.toLocaleString()}đ/${periodVi}${catText}**. Mình sẽ nhắc nếu bạn sắp vượt nhé!`;
    }

    // ==================================================================
    // 3. Đặt mục tiêu tiết kiệm
    // ==================================================================
    else if (data.action === 'set_goal') {
      await Budget.findOneAndUpdate(
        { userId: req.userId },
        {
          $set: {
            'goal.name': data.goal_name || 'Tiết kiệm',
            'goal.targetAmount': data.target_amount,
            'goal.deadline': dayjs(data.deadline).toDate(),
            'goal.currentProgress': 0,
          },
        },
        { upsert: true }
      );

      const deadlineStr = dayjs(data.deadline).format('DD/MM/YYYY');
      reply = `Goal **${data.goal_name || 'Tiết kiệm'}**: **${data.target_amount.toLocaleString()}đ** trước ngày **${deadlineStr}**. Cố lên nào!`;
    }

    // ==================================================================
    // 4. Chat thường / hỏi thống kê → Gemini tự trả lời
    // ==================================================================
    else if (data.action === 'chat') {
      reply = data.reply;
    }

    // ==================================================================
    // 5. Không hiểu gì cả
    // ==================================================================
    else {
      reply = data.reply + '\nBạn thử nói kiểu:\n• cơm 35k\n• lương 20tr\n• ngân sách ăn uống 5tr/tháng\n• goal mua xe 1 tỷ trong 5 năm';
    }

    res.json({
      reply: reply.trim(),
      transaction: transaction || null,
    });

  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({ reply: 'Ôi không, mình bị lỗi rồi. Thử lại sau vài giây nhé!' });
  }
};

function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
