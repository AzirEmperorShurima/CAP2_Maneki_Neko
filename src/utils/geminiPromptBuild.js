import dayjs from 'dayjs';

/**
 * Tạo prompt để phân tích bill (chỉ ảnh, không có voice)
 * @param {Array} categories - Danh sách categories [{id, name, type}]
 * @returns {string} Prompt đầy đủ
 */
export function buildBillAnalysisPrompt(categories = []) {
   const categoryList = categories
      .map(c => `${c.name} (${c.type === 'income' ? 'thu nhập' : 'chi tiêu'})`)
      .join(', ');

   return `
Bạn là trợ lý tài chính Maneki Neko. Phân tích ảnh hóa đơn/bill để trích xuất JSON.

Các từ lóng về mệnh giá tiền trong tiếng Việt:
- 1k = 1000 đồng
- 1 lít, 1 xị = 100 nghìn đồng
- 1 củ, 1 chai = 1.000.000 đồng (1 triệu đồng)

Trả về JSON với các trường:
- amount: số nguyên VND (bỏ dấu/đơn vị, hỗ trợ "k", "tr/triệu", "củ")
- type: "expense" nếu chi tiêu/thanh toán; "income" nếu nhận tiền
- category_name: chọn chính xác từ danh sách: ${categoryList || 'Ăn uống, Di chuyển, Mua sắm, Lương'}
- merchant: tên người/nơi giao dịch hoặc null
- date: "YYYY-MM-DD" (mặc định ${dayjs().format('YYYY-MM-DD')})
- description: mô tả ngắn gọn, rõ ràng về giao dịch
- items: mảng chi tiết [{name, quantity, price}] cho hóa đơn có nhiều món; chuyển khoản thì []
- confidence: 0..1 (độ chắc chắn)

Quy tắc:
- Trả về JSON thuần, không kèm giải thích hay markdown
- amount phải là số nguyên, bỏ dấu chấm/phẩy
- Chuyển khoản: nếu màn hình hiện "gửi tiền" → expense; "nhận tiền" → income
- Hóa đơn mua sắm: luôn là expense
- Nếu không chắc chắn, giảm confidence xuống
- items chỉ dùng cho hóa đơn có nhiều món hàng rõ ràng
`.trim();
}

/**
 * Tạo prompt để phân tích voice (chỉ audio, không có ảnh)
 * @param {Array} categories - Danh sách categories [{id, name, type}]
 * @returns {string} Prompt đầy đủ
 */
export function buildVoiceAnalysisPrompt(categories = []) {
   const categoryList = categories
      .map(c => `${c.name} (${c.type === 'income' ? 'thu nhập' : 'chi tiêu'})`)
      .join(', ');

   return `
Bạn là trợ lý tài chính Maneki Neko. Phân tích nội dung voice/audio để trích xuất thông tin giao dịch tài chính.

Các từ lóng về mệnh giá tiền trong tiếng Việt:
- 1k = 1000 đồng
- 1 lít, 1 xị = 100 nghìn đồng
- 1 củ, 1 chai = 1.000.000 đồng (1 triệu đồng)

Trả về JSON với các trường:
- amount: số nguyên VND (chuyển đổi từ lóng nếu có)
- type: "expense" nếu chi tiêu/mua/trả/thanh toán; "income" nếu nhận/thu
- category_name: chọn chính xác từ danh sách: ${categoryList || 'Ăn uống, Di chuyển, Mua sắm, Lương'}
- merchant: tên người/nơi giao dịch được nhắc đến, hoặc null
- date: "YYYY-MM-DD" (mặc định ${dayjs().format('YYYY-MM-DD')} nếu không nói rõ)
- description: mô tả ngắn gọn về giao dịch dựa trên voice
- confidence: 0..1 (độ chắc chắn, giảm nếu voice không rõ hoặc nhiễu)
- voiceTranscript: phiên âm đầy đủ nội dung người dùng nói

Quy tắc:
- Trả về JSON thuần, không kèm giải thích
- amount phải là số nguyên
- Nếu người dùng nói "chi 50k ăn sáng" → expense, amount: 50000, category: Ăn uống
- Nếu "nhận lương 20 triệu" → income, amount: 20000000, category: Lương
- Nếu không nghe rõ hoặc không liên quan tài chính, giảm confidence xuống < 0.4
- voiceTranscript phải ghi lại chính xác những gì người dùng nói
`.trim();
}