import { geminiAnalyzeMultimodal, geminiAnalyzeMultimodal_new } from './geminiAPI.js';
import { buildBillAnalysisPrompt } from './geminiPromptBuild.js';
import dayjs from 'dayjs';

/**
 * Phân tích bill hoàn chỉnh với ảnh và voice
 * @param {string} imageUrl - URL ảnh bill từ Cloudinary
 * @param {string|null} voiceUrl - URL audio từ Cloudinary (optional)
 * @param {Array} categories - Danh sách categories của user
 * @returns {Object} Thông tin giao dịch được trích xuất
 */
export async function analyzeBillComplete(imageUrl, voiceUrl = null, categories = []) {
    try {
        const prompt = buildBillAnalysisPrompt(categories, !!voiceUrl);

        const result = await geminiAnalyzeMultimodal_new(imageUrl, voiceUrl, prompt);

        if (!result || !result.response || typeof result.response.text !== 'function') {
            throw new Error('Không nhận được phản hồi từ Gemini');
        }

        const rawText = result.response.text().trim();
        const billData = parseGeminiResponse(rawText);
        const normalizedData = normalizeBillData(billData);

        console.log('✅ Phân tích thành công:', {
            amount: normalizedData.amount,
            confidence: normalizedData.confidence,
            merchant: normalizedData.merchant,
            hasVoiceTranscript: !!normalizedData.voiceTranscript
        });

        return normalizedData;

    } catch (error) {
        console.error('❌ Lỗi phân tích bill:', error);
        throw new Error('Không thể phân tích bill: ' + error.message);
    }
}

/**
 * Parse JSON từ response của Gemini
 * Xử lý các trường hợp Gemini trả về markdown code block
 */
function parseGeminiResponse(rawText) {
    try {
        // Remove markdown code blocks
        const jsonStr = rawText
            .replace(/^```json\s*/i, '')
            .replace(/^```\s*/i, '')
            .replace(/\s*```$/g, '')
            .trim();

        const parsed = JSON.parse(jsonStr);
        return parsed;

    } catch (error) {
        console.error('Lỗi parse JSON từ Gemini:', error);
        console.error('Raw text:', rawText);
        throw new Error('Gemini trả về không phải JSON hợp lệ');
    }
}

/**
 * Validate và normalize dữ liệu bill
 * Đảm bảo tất cả fields đều có giá trị hợp lệ
 */
function normalizeBillData(billData) {
    // Validate amount
    const amount = parseInt(billData.amount);
    if (isNaN(amount) || amount <= 0) {
        console.warn('⚠️ Amount không hợp lệ:', billData.amount);
    }

    // Validate type
    const type = ['income', 'expense'].includes(billData.type)
        ? billData.type
        : 'expense';

    // Validate confidence
    let confidence = parseFloat(billData.confidence);
    if (isNaN(confidence) || confidence < 0 || confidence > 1) {
        confidence = 0.5;
    }

    // Validate date
    let date = billData.date;
    if (!date || !dayjs(date).isValid()) {
        date = dayjs().format('YYYY-MM-DD');
    }

    // Normalize items
    const items = Array.isArray(billData.items)
        ? billData.items.map(item => ({
            name: item.name || '',
            quantity: item.quantity || 1,
            price: parseInt(item.price) || 0
        }))
        : [];

    return {
        amount: amount || 0,
        type: type,
        category_name: billData.category_name || 'Khác',
        merchant: billData.merchant || null,
        date: date,
        description: billData.description || `Thanh toán${billData.merchant ? ` tại ${billData.merchant}` : ''}`,
        items: items,
        confidence: confidence,
        voiceTranscript: billData.voiceTranscript || null,
    };
}
