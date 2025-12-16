import Transaction from '../models/transaction.js';
import Category from '../models/category.js';
import Budget from '../models/budget.js';
import Wallet from '../models/wallet.js';
import Goal from '../models/goal.js';
import { geminiChat } from '../utils/gemini.js';
import { analyzeBillComplete, analyzeVoiceTransaction } from '../utils/geminiVision.js';
import dayjs from 'dayjs';
import 'dayjs/locale/vi.js';
import { checkBudgetWarning, updateBudgetSpentAmounts } from '../utils/budget.js';
import { SYSTEM_PROMPT } from '../utils/geminiChatPrompt.js';
import { chat_joke } from '../utils/joke.js';
import { checkWalletBalance, getOrCreateDefaultExpenseWallet, getOrCreateDefaultWallet } from '../utils/wallet.js';

dayjs.locale('vi');

const pendingMediaByUser = new Map();
const IRRELEVANT_CONFIDENCE = 0.4;
const REQUIRED_CONFIDENCE = 0.6;

function isIrrelevant(analysis) {
  const noAmount = !analysis?.amount || analysis.amount <= 0;
  const noMerchant = !analysis?.merchant;
  const noItems = !Array.isArray(analysis?.items) || analysis.items.length === 0;
  return (parseFloat(analysis?.confidence) < IRRELEVANT_CONFIDENCE) && noAmount && noMerchant && noItems;
}

/**
 * Cập nhật tiến độ của các goal liên kết với wallet khi có giao dịch mới
 */
const updateGoalProgressFromTransaction = async (transaction, userId) => {
  try {
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
    const message = req.body?.message?.trim();
    const uploadedFiles = req.uploadedFiles;
    // ===== MODE 1: UPLOAD BILL WITH IMAGE =====
    if (uploadedFiles?.billImage) {
      return await handleBillUpload(req, res, uploadedFiles);
    }
    // ===== MODE 2: UPLOAD TRANSACTION WITH VOICE =====
    if (uploadedFiles?.voice) {
      return await handleVoiceTransaction(req, res, uploadedFiles.voice);
    }
    // ===== MODE 3: TEXT CHAT =====
    if (message && message.length > 0) {
      return await handleTextChat(req, res, message);
    }
    return res.json({
      message: 'Vui lòng nhập tin nhắn hoặc tải ảnh hóa đơn lên.',
      data: { requireManualInput: true }
    });

  } catch (error) {
    res.status(500).json({
      message: 'Ôi không, mình bị lỗi rồi. Thử lại sau vài giây nhé!',
      data: { error: error.message }
    });
  }
};

// VOICE TRANSACTION
async function handleVoiceTransaction(req, res, voice, userMessage) {
  try {
    console.log('🎤 Voice transaction...');
    const categories = await Category.find({
      $or: [{ scope: 'system', isDefault: true }, { scope: 'personal', userId: req.userId }]
    });
    const categoriesPayload = categories.map(c => ({ id: c._id, name: c.name, type: c.type }));

    let voiceAnalysis;
    try {
      voiceAnalysis = await analyzeVoiceTransaction(voice.url, categoriesPayload);
    } catch (error) {
      return res.json({
        message: 'Hmm, mình không nghe rõ. Bạn nói lại hoặc nhập tay được không?',
        data: { requireManualInput: true, voice: { url: voice.url, publicId: voice.publicId } }
      });
    }

    if (isIrrelevant(voiceAnalysis)) {
      return res.json({
        message: 'Voice này không liên quan đến giao dịch.',
        data: { isIrrelevant: true, voice: { url: voice.url, publicId: voice.publicId, transcript: voiceAnalysis.voiceTranscript } }
      });
    }

    if (parseFloat(voiceAnalysis.confidence) < REQUIRED_CONFIDENCE) {
      return res.json({
        message: `Mình chỉ nghe rõ ${(parseFloat(voiceAnalysis.confidence) * 100).toFixed(0)}%. Kiểm tra lại nhé!`,
        data: {
          requireManualInput: true, suggestion: voiceAnalysis,
          voice: { url: voice.url, publicId: voice.publicId, transcript: voiceAnalysis.voiceTranscript }
        }
      });
    }

    let category = await Category.findOne({
      name: { $regex: new RegExp(`^${escapeRegExp(voiceAnalysis.category_name)}$`, 'i') },
      type: voiceAnalysis.type,
      $or: [{ scope: 'system', isDefault: true }, { scope: 'personal', userId: req.userId }]
    });

    if (!category) {
      category = await Category.create({
        name: voiceAnalysis.category_name, type: voiceAnalysis.type,
        keywords: voiceAnalysis.category_name.toLowerCase().split(/\s+/),
        scope: 'personal', userId: req.userId
      });
    }

    let wallet = null;
    if (voiceAnalysis.type === 'income') {
      wallet = await getOrCreateDefaultWallet(req.userId);
    } else if (voiceAnalysis.type === 'expense') {
      wallet = await getOrCreateDefaultExpenseWallet(req.userId);
    }

    if (!wallet) {
      return res.json({
        message: 'Không thể tạo hoặc tìm ví để ghi nhận giao dịch.',
        data: { requireManualInput: true }
      });
    }
    let lowBalanceWarning = null;
    if (voiceAnalysis.type === 'expense') {
      const hasEnoughBalance = await checkWalletBalance(wallet._id, voiceAnalysis.amount);
      if (!hasEnoughBalance) {
        lowBalanceWarning = {
          code: 'LOW_BALANCE',
          walletId: wallet._id,
          currentBalance: wallet.balance,
          required: voiceAnalysis.amount,
          shortfall: voiceAnalysis.amount - wallet.balance
        };
      }
    }
    const transaction = await Transaction.create({
      userId: req.userId,
      walletId: wallet._id,
      amount: voiceAnalysis.amount,
      categoryId: category._id,
      type: voiceAnalysis.type,
      inputType: 'voice',
      description: voiceAnalysis.description || userMessage || 'Giao dịch từ voice',
      date: voiceAnalysis.date ? dayjs(voiceAnalysis.date).toDate() : new Date(),
      source: 'voice-input',
      billMetadata: {
        voiceUrl: voice.url, voicePublicId: voice.publicId,
        voiceTranscript: voiceAnalysis.voiceTranscript, confidence: voiceAnalysis.confidence,
        analyzedAt: new Date()
      },
      rawText: voiceAnalysis.voiceTranscript || userMessage,
      confidence: voiceAnalysis.confidence
    });

    let budgetWarnings = null;

    if (transaction.type === 'expense') {
      wallet.balance -= transaction.amount;
      await wallet.save();

      await updateBudgetSpentAmounts(req.userId, transaction);

      const warnings = await checkBudgetWarning(req.userId, transaction);
      if (warnings && warnings.length > 0) {
        budgetWarnings = {
          count: warnings.length,
          hasError: warnings.some(w => w.level === 'error'),
          hasCritical: warnings.some(w => w.level === 'critical'),
          warnings
        };
      }

    } else if (transaction.type === 'income') {
      wallet.balance += transaction.amount;
      await wallet.save();

      await updateGoalProgressFromTransaction(transaction, req.userId);
    }

    const typeText = voiceAnalysis.type === 'income' ? 'thu nhập' : 'chi tiêu';
    let reply = `✅ Đã ghi **${voiceAnalysis.amount.toLocaleString()}đ** ${typeText} vào **${category.name}**`;
    if (voiceAnalysis.merchant) reply += ` tại **${voiceAnalysis.merchant}**`;
    reply += ` từ ví **${wallet.name}**`;
    reply += `\nSố dư còn lại: **${wallet.balance.toLocaleString()}đ**`;

    if (budgetWarnings && budgetWarnings.warnings.length > 0) {
      reply += '\n\n⚠️ Cảnh báo ngân sách:';
      budgetWarnings.warnings.forEach(w => {
        reply += `\n• ${w.message}`;
      });
    }
    if (lowBalanceWarning) {
      reply += `\n⚠️ Cảnh báo số dư thấp: **${lowBalanceWarning.shortfall.toLocaleString()}đ**`;
    }

    const jokePool = voiceAnalysis.type === 'income' ? chat_joke.income : chat_joke.bigSpending;
    const jokeMessage = jokePool?.[Math.floor(Math.random() * jokePool.length)];

    return res.json({
      message: reply,
      data: {
        transaction: {
          id: transaction._id,
          amount: transaction.amount,
          type: transaction.type,
          category: { id: category._id, name: category.name, type: category.type, image: category.image },
          description: transaction.description,
          date: transaction.date,
          confidence: voiceAnalysis.confidence,
          wallet: {
            id: wallet._id,
            name: wallet.name,
            balance: wallet.balance
          }
        },
        lowBalanceWarning: lowBalanceWarning || null,
        budgetWarnings: budgetWarnings || null,
        voice: { url: voice.url, publicId: voice.publicId, transcript: voiceAnalysis.voiceTranscript },
        jokeMessage
      }
    });
  } catch (error) {
    console.error('Lỗi voice:', error);
    throw error;
  }
}

/**
 * Xử lý upload bill và tự động tạo transaction
 */
async function handleBillUpload(req, res, uploadedFiles, userMessage) {
  try {
    const { billImage, voice } = uploadedFiles;
    const manualAmount = req.body?.manualAmount ? Number(req.body.manualAmount) : undefined;
    const manualCategory = req.body?.manualCategory || undefined;

    const categories = await Category.find({
      $or: [{ scope: 'system', isDefault: true }, { scope: 'personal', userId: req.userId }]
    });
    const categoriesPayload = categories.map(c => ({ id: c._id, name: c.name, type: c.type }));

    let billAnalysis;
    try {
      billAnalysis = await analyzeBillComplete(billImage.url, voice?.url || null, categoriesPayload);
    } catch (error) {
      return res.json({
        message: 'Hmm, không đọc được bill. Nhập thủ công nhé!',
        data: {
          requireManualInput: true,
          billImage: { url: billImage.url, thumbnail: billImage.thumbnail, publicId: billImage.publicId },
          voice: voice ? { url: voice.url, publicId: voice.publicId } : null
        }
      });
    }

    if (isIrrelevant(billAnalysis)) {
      return res.json({
        message: 'Ảnh này không liên quan đến bill.',
        data: {
          isIrrelevant: true,
          billImage: { url: billImage.url, thumbnail: billImage.thumbnail, publicId: billImage.publicId },
          voice: voice ? { url: voice.url, publicId: voice.publicId, transcript: billAnalysis.voiceTranscript } : null
        }
      });
    }

    if (parseFloat(billAnalysis.confidence) < REQUIRED_CONFIDENCE) {
      return res.json({
        message: `Chỉ đọc được ${(parseFloat(billAnalysis.confidence) * 100).toFixed(0)}%. Kiểm tra lại nhé!`,
        data: {
          requireManualInput: true, suggestion: billAnalysis,
          billImage: { url: billImage.url, thumbnail: billImage.thumbnail, publicId: billImage.publicId },
          voice: voice ? { url: voice.url, publicId: voice.publicId, transcript: billAnalysis.voiceTranscript } : null
        }
      });
    }

    const finalAmount = manualAmount || billAnalysis.amount;
    const finalCategoryName = manualCategory || billAnalysis.category_name;
    const finalType = billAnalysis.type;

    let category = await Category.findOne({
      name: { $regex: new RegExp(`^${escapeRegExp(finalCategoryName)}$`, 'i') }, type: finalType,
      $or: [{ scope: 'system', isDefault: true }, { scope: 'personal', userId: req.userId }]
    });

    if (!category) {
      category = await Category.create({
        name: finalCategoryName, type: finalType,
        keywords: finalCategoryName.toLowerCase().split(/\s+/),
        scope: 'personal', userId: req.userId
      });
    }

    let wallet = null;
    if (finalType === 'income') {
      wallet = await getOrCreateDefaultWallet(req.userId);
    } else if (finalType === 'expense') {
      wallet = await getOrCreateDefaultExpenseWallet(req.userId);
    }

    if (!wallet) {
      return res.json({
        message: 'Không thể tạo hoặc tìm ví để ghi nhận giao dịch.',
        data: { requireManualInput: true }
      });
    }
    let lowBalanceWarning = null;
    if (billAnalysis.type === 'expense') {
      const hasEnoughBalance = await checkWalletBalance(wallet._id, billAnalysis.amount);
      if (!hasEnoughBalance) {
        lowBalanceWarning = {
          code: 'LOW_BALANCE',
          walletId: wallet._id,
          currentBalance: wallet.balance,
          required: billAnalysis.amount,
          shortfall: billAnalysis.amount - wallet.balance
        };
      }
    }
    let description = userMessage || billAnalysis.description || '';
    if (billAnalysis.items?.length > 0) {
      description = billAnalysis.items
        .map(item => `${item.name} (${item.quantity}x${item.price?.toLocaleString()}đ)`)
        .join(', ');
    } else if (billAnalysis.merchant) {
      description = `Thanh toán tại ${billAnalysis.merchant}`;
    }

    const transaction = await Transaction.create({
      userId: req.userId,
      walletId: wallet._id,
      amount: finalAmount,
      categoryId: category._id,
      type: finalType,
      inputType: 'bill_scan',
      description,
      date: billAnalysis.date ? dayjs(billAnalysis.date).toDate() : new Date(),
      source: 'bill-upload',
      billMetadata: {
        imageUrl: billImage.url, thumbnail: billImage.thumbnail, publicId: billImage.publicId,
        merchant: billAnalysis.merchant, items: billAnalysis.items || [], confidence: billAnalysis.confidence,
        voiceUrl: voice?.url, voicePublicId: voice?.publicId,
        voiceTranscript: billAnalysis.voiceTranscript, analyzedAt: new Date()
      },
      rawText: billAnalysis.voiceTranscript || userMessage || billAnalysis.description,
      confidence: billAnalysis.confidence
    });

    let budgetWarnings = null;

    if (transaction.type === 'expense') {
      wallet.balance -= transaction.amount;
      await wallet.save();
      await updateBudgetSpentAmounts(req.userId, transaction);

      const warnings = await checkBudgetWarning(req.userId, transaction);
      if (warnings && warnings.length > 0) {
        budgetWarnings = {
          count: warnings.length,
          hasError: warnings.some(w => w.level === 'error'),
          hasCritical: warnings.some(w => w.level === 'critical'),
          warnings
        };
      }

    } else if (transaction.type === 'income') {
      wallet.balance += transaction.amount;
      await wallet.save();

      // Cập nhật goal progress
      await updateGoalProgressFromTransaction(transaction, req.userId);
    }

    const typeText = finalType === 'income' ? 'thu nhập' : 'chi tiêu';
    let reply = `✅ Đã ghi **${finalAmount.toLocaleString()}đ** ${typeText} vào **${category.name}**`;
    if (billAnalysis.merchant) reply += ` tại **${billAnalysis.merchant}**`;
    reply += ` từ ví **${wallet.name}**`;
    reply += `\nSố dư còn lại: **${wallet.balance.toLocaleString()}đ**`;
    
    if (budgetWarnings && budgetWarnings.warnings.length > 0) {
      reply += '\n\n⚠️ Cảnh báo ngân sách:';
      budgetWarnings.warnings.forEach(w => {
        reply += `\n• ${w.message}`;
      });
    }
    if (lowBalanceWarning) {
      reply += `\n⚠️ Cảnh báo số dư thấp: **${lowBalanceWarning.shortfall.toLocaleString()}đ**`;
    }

    const jokePool = finalType === 'income' ? chat_joke.income : chat_joke.bigSpending;
    const jokeMessage = jokePool?.[Math.floor(Math.random() * jokePool.length)];

    return res.json({
      message: reply,
      data: {
        transaction: {
          id: transaction._id,
          amount: transaction.amount,
          type: transaction.type,
          category: { id: category._id, name: category.name, type: category.type, image: category.image },
          description: transaction.description,
          merchant: billAnalysis.merchant,
          date: transaction.date,
          confidence: billAnalysis.confidence,
          wallet: {
            id: wallet._id,
            name: wallet.name,
            balance: wallet.balance
          }
        },
        budgetWarnings: budgetWarnings || null,
        lowBalanceWarning: lowBalanceWarning || null,
        billImage: { url: billImage.url, thumbnail: billImage.thumbnail, publicId: billImage.publicId },
        voice: voice ? { url: voice.url, publicId: voice.publicId, transcript: billAnalysis.voiceTranscript } : null,
        items: billAnalysis.items,
        jokeMessage
      }
    });
  } catch (error) {
    console.error('Lỗi bill:', error);
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

    const categories = await Category.find({
      $or: [
        { scope: 'system', isDefault: true },
        { scope: 'personal', userId: req.userId }
      ]
    });
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
      let category = null;

      if (data.category_id) {
        category = await Category.findOne({
          _id: data.category_id,
          $or: [
            { scope: 'system', isDefault: true },
            { scope: 'personal', userId: req.userId }
          ]
        });
      }

      if (!category) {
        category = await Category.findOne({
          name: { $regex: new RegExp(`^${escapeRegExp(data.category_name)}$`, 'i') },
          type: data.type,
          $or: [
            { scope: 'system', isDefault: true },
            { scope: 'personal', userId: req.userId }
          ]
        });
      }

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

      // Xử lý wallet
      let wallet = null;
      let walletId = data.walletId || null;

      if (walletId) {
        wallet = await Wallet.findOne({
          _id: walletId,
          userId: req.userId,
          isActive: true
        });
      }

      if (!wallet) {
        if (data.type === 'income') {
          wallet = await getOrCreateDefaultWallet(req.userId);
        } else if (data.type === 'expense') {
          wallet = await getOrCreateDefaultExpenseWallet(req.userId);
        }
      }

      if (!wallet) {
        return res.json({
          reply: 'Không thể tạo hoặc tìm ví để ghi nhận giao dịch. Vui lòng thử lại.'
        });
      }
      let lowBalanceWarning = null;
      if (data.type === 'expense') {
        const hasEnoughBalance = await checkWalletBalance(wallet._id, data.amount);
        if (!hasEnoughBalance) {
          lowBalanceWarning = {
            code: 'LOW_BALANCE',
            walletId: wallet._id,
            currentBalance: wallet.balance,
            required: data.amount,
            shortfall: data.amount - wallet.balance
          };
        }
      }
      const trans = await Transaction.create({
        userId: req.userId,
        walletId: wallet._id,
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

      let budgetWarnings = null;

      if (data.type === 'expense') {
        wallet.balance -= data.amount;
        await wallet.save();

        await updateBudgetSpentAmounts(req.userId, trans);

        const warnings = await checkBudgetWarning(req.userId, trans);
        if (warnings && warnings.length > 0) {
          budgetWarnings = {
            count: warnings.length,
            hasError: warnings.some(w => w.level === 'error'),
            hasCritical: warnings.some(w => w.level === 'critical'),
            warnings
          };
        }

      } else if (data.type === 'income') {
        wallet.balance += data.amount;
        await wallet.save();

        await updateGoalProgressFromTransaction(trans, req.userId);
      }

      transaction = {
        id: trans._id,
        amount: trans.amount,
        category: {
          id: category._id,
          name: category.name,
          type: category.type,
          image: category.image || ''
        },
        type: trans.type,
        date: trans.date,
        description: trans.description,
        confidence: 1.0,
        wallet: {
          id: wallet._id,
          name: wallet.name,
          balance: wallet.balance
        } || null,
        budgetWarnings,
        lowBalanceWarning,
      };

      const typeText = data.type === 'income' ? 'thu nhập' : 'chi tiêu';
      reply += `Đã ghi **${data.amount.toLocaleString()}đ** ${typeText} vào **${category.name}**`;
      reply += ` từ ví **${wallet.name}**`;
      reply += `\nSố dư còn lại: **${wallet.balance.toLocaleString()}đ**`;

      const jokePool = data.type === 'income' ? chat_joke.income : chat_joke.bigSpending;
      if (Array.isArray(jokePool) && jokePool.length) {
        jokeMessage = jokePool[Math.floor(Math.random() * jokePool.length)];
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
        jokeMessage,
        message: reply.trim(),
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
