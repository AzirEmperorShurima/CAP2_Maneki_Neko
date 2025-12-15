import { geminiAnalyzeMultimodal, geminiAnalyzeMultimodal_new } from './geminiAPI.js';
import { buildBillAnalysisPrompt, buildVoiceAnalysisPrompt } from './geminiPromptBuild.js';
import dayjs from 'dayjs';

/**
 * Phân tích bill với ảnh (không có voice)
 * @param {string} imageUrl - URL ảnh bill từ Cloudinary
 * @param {string|null} voiceUrl - URL audio (để tương thích, nhưng không dùng)
 * @param {Array} categories - Danh sách categories
 * @returns {Object} Thông tin giao dịch
 */
export async function analyzeBillComplete(imageUrl, voiceUrl = null, categories = []) {
    try {
        const prompt = buildBillAnalysisPrompt(categories, false); // hasVoice = false

        const result = await geminiAnalyzeMultimodal_new(imageUrl, null, prompt);

        if (!result?.response || typeof result.response.text !== 'function') {
            throw new Error('Không nhận được phản hồi từ Gemini');
        }

        const rawText = result.response.text().trim();
        const billData = parseGeminiResponse(rawText);
        const normalizedData = normalizeBillData(billData);

        console.log('✅ Phân tích bill thành công:', {
            amount: normalizedData.amount,
            confidence: normalizedData.confidence,
            merchant: normalizedData.merchant
        });

        return normalizedData;
    } catch (error) {
        console.error('❌ Lỗi phân tích bill:', error);
        throw new Error('Không thể phân tích bill: ' + error.message);
    }
}

/**
 * Phân tích voice để ghi giao dịch (không có ảnh)
 * @param {string} voiceUrl - URL audio từ Cloudinary
 * @param {Array} categories - Danh sách categories
 * @returns {Object} Thông tin giao dịch từ voice
 */
export async function analyzeVoiceTransaction(voiceUrl, categories = []) {
    try {
        const prompt = buildVoiceAnalysisPrompt(categories);

        const result = await geminiAnalyzeMultimodal_new(null, voiceUrl, prompt);

        if (!result?.response || typeof result.response.text !== 'function') {
            throw new Error('Không nhận được phản hồi từ Gemini');
        }

        const rawText = result.response.text().trim();
        const voiceData = parseGeminiResponse(rawText);
        const normalizedData = normalizeVoiceData(voiceData);

        console.log('✅ Phân tích voice thành công:', {
            amount: normalizedData.amount,
            confidence: normalizedData.confidence,
            transcript: normalizedData.voiceTranscript?.substring(0, 50) + '...'
        });

        return normalizedData;
    } catch (error) {
        console.error('❌ Lỗi phân tích voice:', error);
        throw new Error('Không thể phân tích voice: ' + error.message);
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
 * Normalize dữ liệu bill
 */
function normalizeBillData(billData) {
    const amount = parseInt(billData.amount);
    if (isNaN(amount) || amount <= 0) {
        console.warn('⚠️ Amount không hợp lệ:', billData.amount);
    }

    const type = ['income', 'expense'].includes(billData.type) ? billData.type : 'expense';

    let confidence = parseFloat(billData.confidence);
    if (isNaN(confidence) || confidence < 0 || confidence > 1) {
        confidence = 0.5;
    }

    let date = billData.date;
    if (!date || !dayjs(date).isValid()) {
        date = dayjs().format('YYYY-MM-DD');
    }

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
        voiceTranscript: null // Bill không có voice
    };
}

/**
 * Normalize dữ liệu voice
 */
function normalizeVoiceData(voiceData) {
    const amount = parseInt(voiceData.amount);
    if (isNaN(amount) || amount <= 0) {
        console.warn('⚠️ Amount không hợp lệ:', voiceData.amount);
    }

    const type = ['income', 'expense'].includes(voiceData.type) ? voiceData.type : 'expense';

    let confidence = parseFloat(voiceData.confidence);
    if (isNaN(confidence) || confidence < 0 || confidence > 1) {
        confidence = 0.5;
    }

    let date = voiceData.date;
    if (!date || !dayjs(date).isValid()) {
        date = dayjs().format('YYYY-MM-DD');
    }

    return {
        amount: amount || 0,
        type: type,
        category_name: voiceData.category_name || 'Khác',
        merchant: voiceData.merchant || null,
        date: date,
        description: voiceData.description || 'Giao dịch từ voice',
        confidence: confidence,
        voiceTranscript: voiceData.voiceTranscript || null
    };
}
