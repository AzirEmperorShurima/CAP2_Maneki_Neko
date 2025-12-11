import Transaction from '../models/transaction.js';
import Category from '../models/category.js';
import Budget from '../models/budget.js';
import Wallet from '../models/wallet.js';
import Goal from '../models/goal.js';
import { geminiChat } from '../utils/gemini.js';
import { analyzeBillComplete } from '../utils/geminiVision.js';
import dayjs from 'dayjs';
import 'dayjs/locale/vi.js';
import { checkBudgetWarning } from '../utils/budget.js';
import { SYSTEM_PROMPT } from '../utils/geminiChatPrompt.js';
import { chat_joke } from '../utils/joke.js';

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

const calculatePeriodDates = (period, customStart, customEnd) => {
  const now = dayjs();

  let periodStart, periodEnd;

  switch (period) {
    case 'daily':
      periodStart = now.startOf('day').toDate();
      periodEnd = now.endOf('day').toDate();
      break;
    case 'weekly':
      periodStart = now.startOf('week').toDate();
      periodEnd = now.endOf('week').toDate();
      break;
    case 'monthly':
      periodStart = now.startOf('month').toDate();
      periodEnd = now.endOf('month').toDate();
      break;
    default:
      throw new Error('Period không hợp lệ');
  }

  return { periodStart, periodEnd };
};

// Hàm tìm budget cha phù hợp
const findParentBudget = async (userId, childPeriod, periodStart, periodEnd) => {
  const parentPeriodMap = {
    'daily': 'weekly',
    'weekly': 'monthly'
  };

  const possibleParentPeriod = parentPeriodMap[childPeriod];
  if (!possibleParentPeriod) return null;

  const parentBudget = await Budget.findOne({
    userId,
    type: possibleParentPeriod,
    isActive: true,
    periodStart: { $lte: periodStart },
    periodEnd: { $gte: periodEnd }
  });

  return parentBudget;
};

/**
 * UNIFIED CONTROLLER - Xử lý cả TEXT CHAT và BILL UPLOAD
 */
export const geminiChatController = async (req, res) => {
  try {
    const message = (req.body && typeof req.body.message === 'string') ? req.body.message : '';
    const uploadedFiles = req.uploadedFiles; // Từ billUploadMiddleware

    // ===== MODE 1: UPLOAD BILL WITH IMAGE =====
    if (uploadedFiles && (uploadedFiles.billImage || uploadedFiles.voice)) {
      return await handleBillUpload(req, res, uploadedFiles, message);
    }

    // ===== MODE 2: TEXT CHAT =====
    return await handleTextChat(req, res, message);

  } catch (error) {
    console.error('❌ Lỗi trong geminiChatController:', error);
    res.status(500).json({
      message: 'Ôi không, mình bị lỗi rồi. Thử lại sau vài giây nhé!',
      data: { error: error.message }
    });
  }
};

/**
 * Xử lý upload bill và tự động tạo transaction
 */
async function handleBillUpload(req, res, uploadedFiles, userMessage) {
  try {
    const { billImage, voice } = uploadedFiles;
    const manualAmount = req.body && req.body.manualAmount ? Number(req.body.manualAmount) : undefined;
    const manualCategory = req.body && typeof req.body.manualCategory === 'string' ? req.body.manualCategory : undefined;

    console.log('📸 Đang phân tích bill...');

    // Lấy categories
    const categories = await Category.find({ userId: req.userId });
    const categoriesPayload = categories.map(c => ({
      id: c._id,
      name: c.name,
      type: c.type,
    }));

    let billAnalysis;
    try {
      const imageUrl = billImage?.url || null;
      billAnalysis = await analyzeBillComplete(
        imageUrl,
        voice?.url || null,
        categoriesPayload
      );
    } catch (error) {
      return res.json({
        message: 'Hmm, mình không đọc được bill này rõ lắm. Bạn có thể nhập thủ công không?',
        data: {
          requireManualInput: true,
          billImage: billImage ? {
            url: billImage.url,
            thumbnail: billImage.thumbnail,
            publicId: billImage.publicId
          } : null,
          voice: voice ? {
            url: voice.url,
            publicId: voice.publicId
          } : null
        }
      });
    }

    // Kiểm tra confidence
    if (billAnalysis.confidence < 0.6) {
      return res.json({
        message: `Mình chỉ đọc được khoảng ${(billAnalysis.confidence * 100).toFixed(0)}% thôi. Bạn kiểm tra lại giúp mình nhé!`,
        data: {
          requireManualInput: true,
          suggestion: billAnalysis,
          billImage: {
            url: billImage.url,
            thumbnail: billImage.thumbnail,
            publicId: billImage.publicId
          },
          voice: voice ? {
            url: voice.url,
            publicId: voice.publicId,
            transcript: billAnalysis.voiceTranscript
          } : null
        }
      });
    }

    const finalAmount = manualAmount || billAnalysis.amount;
    const finalCategoryName = manualCategory || billAnalysis.category_name;
    const finalType = billAnalysis.type;

    let category = await Category.findOne({
      name: { $regex: new RegExp(`^${escapeRegExp(finalCategoryName)}$`, 'i') },
      type: finalType,
      userId: req.userId
    });

    if (!category) {
      category = await Category.create({
        name: finalCategoryName,
        type: finalType,
        keywords: finalCategoryName.toLowerCase().split(/\s+/),
        scope: 'personal',
        userId: req.userId
      });
    }

    // Tạo transaction
    const transaction = await Transaction.create({
      userId: req.userId,
      amount: finalAmount,
      categoryId: category._id,
      type: finalType,
      inputType: 'bill_scan',
      description: userMessage || billAnalysis.description || `${billAnalysis.merchant || 'Thanh toán'}`,
      date: billAnalysis.date ? dayjs(billAnalysis.date).toDate() : new Date(),
      source: 'bill-upload',

      // Metadata từ bill
      billMetadata: {
        imageUrl: billImage?.url || null,
        thumbnail: billImage?.thumbnail || null,
        publicId: billImage?.publicId || null,
        merchant: billAnalysis.merchant,
        items: billAnalysis.items || [],
        confidence: billAnalysis.confidence,
        voiceUrl: voice?.url || null,
        voicePublicId: voice?.publicId || null,
        voiceTranscript: billAnalysis.voiceTranscript || null,
        analyzedAt: new Date()
      },

      rawText: billAnalysis.voiceTranscript || userMessage || billAnalysis.description,
      confidence: billAnalysis.confidence,
    });

    // Cập nhật goal nếu là income
    if (transaction.type === 'income' && transaction.walletId) {
      await updateGoalProgressFromTransaction(transaction, req.userId);
    }

    // Check budget warning
    const warning = checkBudgetWarning?.(req.userId, transaction);

    // Tạo reply message
    const typeText = finalType === 'income' ? 'thu nhập' : 'chi tiêu';
    let reply = `✅ Đã ghi **${finalAmount.toLocaleString()}đ** ${typeText} vào **${category.name}**`;

    if (billAnalysis.merchant) {
      reply += ` tại **${billAnalysis.merchant}**`;
    }

    if (warning) {
      reply += `\n\n⚠️ ${warning}`;
    }

    // Thêm joke
    const jokePool = finalType === 'income' ? chat_joke.income : chat_joke.bigSpending;
    const jokeMessage = jokePool?.[Math.floor(Math.random() * jokePool.length)] || null;

    return res.json({
      message: reply,
      data: {
        transaction: {
          id: transaction._id,
          amount: transaction.amount,
          type: transaction.type,
          category: {
            id: category._id,
            name: category.name,
          },
          merchant: billAnalysis.merchant,
          confidence: billAnalysis.confidence
        },
        billImage: billImage ? {
          url: billImage.url,
          thumbnail: billImage.thumbnail,
          publicId: billImage.publicId
        } : null,
        voice: voice ? {
          url: voice.url,
          publicId: voice.publicId,
          transcript: billAnalysis.voiceTranscript
        } : null,
        items: billAnalysis.items,
        jokeMessage
      }
    });

  } catch (error) {
    console.error('Lỗi handleBillUpload:', error);
    throw error;
  }
}

/**
 * Xử lý chat text thông thường
 */
async function handleTextChat(req, res, message) {
  try {
    if (!message?.trim()) {
      return res.status(400).json({ error: 'Tin nhắn không được để trống' });
    }

    const categories = await Category.find({ userId: req.userId });
    const categoriesPayload = categories.map(category => ({
      id: category._id,
      name: category.name,
      type: category.type,
    }));

    const chatPayload = [
      {
        role: 'user',
        parts: [{
          text: `${SYSTEM_PROMPT}\n\n"message": ${message}\n\n"categories for transaction": ${JSON.stringify(categoriesPayload)}`
        }]
      }
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
    let jokeMessage = null;

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
          scope: 'personal',
          userId: req.userId
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
        category: {
          id: category._id,
          name: category.name,
        },
        type: trans.type,
        confidence: 1.0,
      };

      const typeText = data.type === 'income' ? 'thu nhập' : 'chi tiêu';
      reply += `Đã ghi **${data.amount.toLocaleString()}đ** ${typeText} vào **${category.name}**.`;

      const warning = checkBudgetWarning?.(req.userId, trans);
      if (warning) reply += `\n${warning}`;

      const jokePool = data.type === 'income' ? chat_joke.income : chat_joke.bigSpending;
      if (Array.isArray(jokePool) && jokePool.length) {
        jokeMessage = jokePool[Math.floor(Math.random() * jokePool.length)];
      }

      if (trans.type === 'income') {
        await updateGoalProgressFromTransaction(trans, req.userId);
      }
    }

    // ==================================================================
    // 2. Đặt ngân sách
    // ==================================================================
    else if (data.action === 'set_budget') {
      try {
        const categoryId = data.category_name
          ? (await Category.findOne({
            name: { $regex: new RegExp(`^${escapeRegExp(data.category_name)}$`, 'i') }
          }))?._id || null
          : null;

        const { periodStart, periodEnd } = calculatePeriodDates(data.period);

        let parentBudgetId = null;
        const parentBudget = await findParentBudget(req.userId, data.period, periodStart, periodEnd);

        if (parentBudget) {
          parentBudgetId = parentBudget._id;
        }

        const existingBudget = await Budget.findOne({
          userId: req.userId,
          type: data.period,
          categoryId: categoryId || null,
          periodStart,
          periodEnd,
          isActive: true
        });

        let budget;
        if (existingBudget) {
          existingBudget.amount = data.amount;
          budget = await existingBudget.save();
          reply = `Đã cập nhật ngân sách ${data.category_name ? `cho ${data.category_name}` : 'tổng'} cho khoảng thời gian này thành ${data.amount.toLocaleString()}đ.`;
        } else {
          budget = new Budget({
            userId: req.userId,
            type: data.period,
            amount: data.amount,
            categoryId: categoryId || null,
            parentBudgetId: parentBudgetId,
            periodStart,
            periodEnd,
            spentAmount: 0,
            isActive: true
          });

          await budget.save();
          reply = `Đã đặt ngân sách ${data.category_name ? `cho ${data.category_name}` : 'tổng'} ${data.amount.toLocaleString()}đ cho ${data.period}.`;
        }

        if (parentBudgetId) {
          const parentBudget = await Budget.findById(parentBudgetId).populate('categoryId');
          const parentPeriodText = parentBudget.type === 'monthly' ? 'tháng' : parentBudget.type === 'weekly' ? 'tuần' : 'ngày';
          const parentCategoryText = parentBudget.categoryId ? `cho ${parentBudget.categoryId.name}` : 'tổng';
          reply += ` Ngân sách này là một phần của ngân sách cha ${parentCategoryText} ${parentBudget.amount.toLocaleString()}đ/${parentPeriodText}.`;
        }

      } catch (error) {
        console.error('Lỗi khi tạo/cập nhật ngân sách:', error);
        return res.json({
          reply: 'Có lỗi xảy ra khi đặt ngân sách. Vui lòng thử lại.'
        });
      }
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
        existingGoal.currentProgress = 0;
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
    else {
      reply = `${data.reply || 'Mình chưa hiểu yêu cầu này.'}\n\nBạn có thể thử:\n` +
        '• Ghi giao dịch: "cơm 35k", "lương 25tr"\n' +
        '• Đặt ngân sách: "ngân sách ăn uống 5tr/tháng"\n' +
        '• Tạo mục tiêu: "mục tiêu du lịch 30tr trong 6 tháng"\n' +
        '• Thêm tiền: "thêm 2tr vào mục tiêu du lịch"\n' +
        '• Liên kết ví: "liên kết ví tiết kiệm với mục tiêu du lịch"\n' +
        '• Hoặc **chụp ảnh bill** để mình tự động ghi cho bạn!';
    }

    return res.json({
      message: reply.trim(),
      data: {
        transaction: transaction || null,
        jokeMessage
      }
    });

  } catch (error) {
    console.error('Lỗi handleTextChat:', error);
    throw error;
  }
}

// Hàm hỗ trợ escape regex
function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
