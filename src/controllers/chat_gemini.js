import Transaction from '../models/transaction.js';
import Category from '../models/category.js';
import Budget from '../models/budget.js';
import Wallet from '../models/wallet.js';
import Goal from '../models/goal.js';
import { geminiChat } from '../utils/gemini.js';
import dayjs from 'dayjs';
import 'dayjs/locale/vi.js';
import { checkBudgetWarning } from '../utils/budget.js';
import { SYSTEM_PROMPT } from '../utils/geminiChatPrompt.js';

dayjs.locale('vi');

/**
 * Cập nhật tiến độ của các goal liên kết với wallet khi có giao dịch mới
 */
const updateGoalProgressFromTransaction = async (transaction, userId) => {
  try {
    // Chỉ xử lý nếu transaction có walletId và là thu nhập (income)
    if (!transaction.walletId || transaction.type !== 'income') return;

    const activeGoals = await Goal.find({
      userId,
      status: 'active',
      associatedWallets: transaction.walletId
    });

    for (const goal of activeGoals) {
      const newProgress = goal.currentProgress + transaction.amount;
      await goal.updateProgress(newProgress);
    }
  } catch (error) {
    console.error('Lỗi cập nhật tiến độ goal từ giao dịch:', error);
  }
};

export const geminiChatController = async (req, res) => {
  try {
    const { message } = req.body;
    if (!message?.trim()) {
      return res.status(400).json({ error: 'Tin nhắn không được để trống' });
    }

    const chatPayload = [
      { role: 'user', parts: [{ text: `${SYSTEM_PROMPT}\n\n${message}` }] }
    ];

    const result = await geminiChat(chatPayload);
    if (!result || !result.response || typeof result.response.text !== 'function') {
      return res.status(500).json({ error: 'Lỗi kết nối với AI' });
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
      console.log('Gemini trả về không phải JSON hợp lệ:', rawText);
      return res.json({
        reply: 'Xin lỗi, mình chưa hiểu rõ. Bạn thử nói lại theo mẫu nhé!',
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
      reply += `Đã ghi **${data.amount.toLocaleString()}đ** ${typeText} vào **${category.name}**.`;

      // Kiểm tra cảnh báo ngân sách
      const warning = checkBudgetWarning?.(req.userId, trans);
      if (warning) reply += `\n${warning}`;

      // Cập nhật tiến độ goal nếu giao dịch là thu nhập và có walletId
      if (trans.type === 'income') {
        await updateGoalProgressFromTransaction(trans, req.userId);
      }
    }

    // ==================================================================
    // 2. Đặt ngân sách
    // ==================================================================
    else if (data.action === 'set_budget') {
      const categoryId = data.category_name
        ? (await Category.findOne({
          name: { $regex: new RegExp(`^${escapeRegExp(data.category_name)}$`, 'i') }
        }))?._id || null
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
    // 3. Tạo hoặc cập nhật mục tiêu tiết kiệm
    // ==================================================================
    else if (data.action === 'set_goal') {
      const existingGoal = await Goal.findOne({
        userId: req.userId,
        name: data.goal_name,
        status: { $in: ['active', 'completed'] }
      });

      let goal;
      if (existingGoal) {
        existingGoal.targetAmount = data.target_amount;
        existingGoal.deadline = dayjs(data.deadline).toDate();
        existingGoal.isActive = true;
        existingGoal.status = 'active';
        existingGoal.currentProgress = 0; // Reset tiến độ khi cập nhật
        goal = await existingGoal.save();
        reply = `Đã cập nhật mục tiêu **${data.goal_name}**`;
      } else {
        goal = await Goal.create({
          userId: req.userId,
          name: data.goal_name,
          description: data.description || '',
          targetAmount: data.target_amount,
          deadline: dayjs(data.deadline).toDate(),
          currentProgress: 0,
          status: 'active',
          isActive: true
        });
        reply = `Đã tạo mục tiêu tiết kiệm **${data.goal_name}**`;
      }

      const deadlineStr = dayjs(goal.deadline).format('DD/MM/YYYY');
      reply += `: **${data.target_amount.toLocaleString()}đ** trước ngày **${deadlineStr}**.`;

      // Kiểm tra ví liên kết
      if (goal.associatedWallets && goal.associatedWallets.length > 0) {
        const wallets = await Wallet.find({ _id: { $in: goal.associatedWallets } }).select('name');
        const walletList = wallets.map(w => w.name).join(', ');
        reply += `\nMục tiêu đang liên kết với ví: **${walletList}**.`;
      } else {
        reply += `\nMục tiêu chưa liên kết với ví nào. Bạn có thể dùng lệnh: "liên kết ví [tên ví] với mục tiêu [tên mục tiêu]" để thêm.`;
      }
    }

    // ==================================================================
    // 4. Liên kết ví với mục tiêu
    // ==================================================================
    else if (data.action === 'link_wallet_to_goal') {
      const goal = await Goal.findOne({
        userId: req.userId,
        name: data.goal_name,
        status: 'active'
      });

      if (!goal) {
        return res.json({
          reply: `Không tìm thấy mục tiêu đang hoạt động có tên "${data.goal_name}".`
        });
      }

      const wallet = await Wallet.findOne({
        userId: req.userId,
        name: { $regex: new RegExp(`^${escapeRegExp(data.wallet_name)}$`, 'i') }
      });

      if (!wallet) {
        return res.json({
          reply: `Không tìm thấy ví có tên "${data.wallet_name}".`
        });
      }

      if (!goal.associatedWallets) goal.associatedWallets = [];
      if (goal.associatedWallets.map(id => id.toString()).includes(wallet._id.toString())) {
        return res.json({
          reply: `Ví **${wallet.name}** đã được liên kết với mục tiêu **${goal.name}** rồi.`
        });
      }

      goal.associatedWallets.push(wallet._id);
      await goal.save();

      reply = `Đã liên kết ví **${wallet.name}** với mục tiêu **${goal.name}**.\nTừ giờ, các khoản thu nhập vào ví này sẽ tự động cộng vào tiến độ mục tiêu.`;
    }

    // ==================================================================
    // 5. Thêm tiền vào mục tiêu (thủ công)
    // ==================================================================
    else if (data.action === 'add_to_goal') {
      const goal = await Goal.findOne({
        userId: req.userId,
        name: data.goal_name,
        status: 'active'
      });

      if (!goal) {
        return res.json({
          reply: `Không tìm thấy mục tiêu đang hoạt động có tên "${data.goal_name}".`
        });
      }

      const newProgress = goal.currentProgress + data.amount;
      const result = await goal.updateProgress(newProgress);

      const progressPercentage = result.progressPercentage.toFixed(1);
      reply = `Đã thêm **${data.amount.toLocaleString()}đ** vào mục tiêu **${goal.name}**.\nTiến độ: **${goal.currentProgress.toLocaleString()}đ / ${goal.targetAmount.toLocaleString()}đ** (${progressPercentage}%)`;

      if (result.isCompleted) {
        reply += '\nChúc mừng! Bạn đã hoàn thành mục tiêu này!';
      }
    }

    // ==================================================================
    // 6. Chat thường / hỏi thống kê
    // ==================================================================
    else if (data.action === 'chat') {
      reply = data.reply;
    }

    // ==================================================================
    // 7. Không hiểu / không hỗ trợ
    // ==================================================================
    else {
      reply = `${data.reply || 'Mình chưa hiểu yêu cầu này.'
        }\n\nBạn có thể thử:\n` +
        '• Ghi giao dịch: "cơm 35k", "lương 25tr"\n' +
        '• Đặt ngân sách: "ngân sách ăn uống 5tr/tháng"\n' +
        '• Tạo mục tiêu: "mục tiêu du lịch 30tr trong 6 tháng"\n' +
        '• Thêm tiền: "thêm 2tr vào mục tiêu du lịch"\n' +
        '• Liên kết ví: "liên kết ví tiết kiệm với mục tiêu du lịch"';
    }

    // Trả về kết quả
    res.json({
      reply: reply.trim(),
      transaction: transaction || null,
    });

  } catch (error) {
    console.error('Lỗi trong geminiChatController:', error);
    res.status(500).json({
      reply: 'Ôi không, mình bị lỗi rồi. Thử lại sau vài giây nhé!'
    });
  }
};

// Hàm hỗ trợ escape regex
function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}