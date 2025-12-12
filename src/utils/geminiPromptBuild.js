import dayjs from 'dayjs';

/**
 * Tạo prompt để phân tích bill với ảnh và voice
 * @param {Array} categories - Danh sách categories [{id, name, type}]
 * @param {boolean} hasVoice - Có file voice kèm theo không
 * @returns {string} Prompt đầy đủ để gửi cho Gemini
 */
export function buildBillAnalysisPrompt(categories = [], hasVoice = false) {
   const categoryList = categories
      .map(c => `${c.name} (${c.type === 'income' ? 'thu nhập' : 'chi tiêu'})`)
      .join(', ');

   return `
Bạn là trợ lý tài chính Maneki Neko. Phân tích ảnh${hasVoice ? ' và voice' : ''} để trích xuất JSON duy nhất với các trường:
Các từ lóng về mệnh giá tiền trong tiếng Việt:
- 1k = 1000 đồng
- 1 lít , 1 xị = 100 nghìn đồng
- 1củ , 1chai,  = 1.000.000 đồng ( 1 triệu đồng)
Trả về JSON với các trường:
- amount: số nguyên VND (hỗ trợ "k", "tr/triệu", "củ")
- type: "expense" nếu người dùng gửi tiền/chi; "income" nếu nhận tiền/thu
- category_name: chọn chính xác từ danh sách: ${categoryList || 'Ăn uống, Di chuyển, Mua sắm, Lương'}
- merchant: tên người/nơi giao dịch hoặc null
- date: "YYYY-MM-DD" (mặc định ${dayjs().format('YYYY-MM-DD')})
- description: mô tả ngắn gọn, rõ ràng
- items: mảng chi tiết cho hóa đơn; chuyển khoản thì []
- confidence: 0..1
${hasVoice ? '- voiceTranscript: phiên âm đầy đủ nội dung người dùng nói' : ''}

Quy tắc:
- Trả về JSON thuần, không kèm giải thích.
- amount phải là số nguyên, bỏ dấu/đơn vị.
- Chuyển khoản: nếu màn hình/voice cho thấy "gửi" → expense; "nhận" → income
- Nếu không chắc, giảm confidence.
`.trim();
}
