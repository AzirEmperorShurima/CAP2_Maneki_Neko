import dayjs from 'dayjs';

/**
 * Tạo prompt để phân tích bill với ảnh và voice
 * @param {Array} categories - Danh sách categories [{id, name, type}]
 * @param {boolean} hasVoice - Có file voice kèm theo không
 * @returns {string} Prompt đầy đủ để gửi cho Gemini
 */
export function buildBillAnalysisPrompt(categories = [], hasVoice = false) {
    const categoryList = categories
        .map(c => `- ${c.name} (${c.type === 'income' ? 'thu nhập' : 'chi tiêu'})`)
        .join('\n');

    return `
Bạn là Maneki Neko - trợ lý tài chính thông minh của người Việt.
Nhiệm vụ: Phân tích hóa đơn/bill/giao dịch từ ảnh${hasVoice ? ' và ghi âm giọng nói' : ''} để trích xuất thông tin.

${hasVoice ? `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎤 QUAN TRỌNG: Người dùng đã ghi âm giọng nói kèm theo ảnh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Phiên âm đầy đủ nội dung người dùng nói trong trường "voiceTranscript"
- Ưu tiên thông tin từ VOICE nếu có xung đột với ảnh
- Kết hợp cả 2 nguồn (ảnh + voice) để phân tích chính xác nhất
- Voice thường chứa context quan trọng: mục đích chi tiêu, ghi chú, người nhận/gửi
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

` : ''}📋 DANH MỤC CÓ SẴN CỦA NGƯỜI DÙNG:
${categoryList || '- Ăn uống (chi tiêu)\n- Di chuyển (chi tiêu)\n- Mua sắm (chi tiêu)\n- Lương (thu nhập)'}

💰 CÁC TỪ LÓNG VỀ TIỀN TRONG TIẾNG VIỆT:
- "k" sau số = nghìn đồng (ví dụ: 50k = 50.000đ)
- "lít", "xị" = 100 nghìn đồng (ví dụ: 1 lít = 100.000đ)
- "củ", "chai", "cây" = 1 triệu đồng (ví dụ: 2 củ = 2.000.000đ)
- "triệu", "tr" = triệu đồng (ví dụ: 5tr = 5.000.000đ)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 LOẠI GIAO DỊCH CÓ THỂ GẶP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 🏪 HÓA ĐƠN TRUYỀN THỐNG (Nhà hàng, siêu thị, cửa hàng)
   - Có logo/tên cửa hàng ở trên
   - Danh sách items/món ăn
   - Total/Tổng cộng ở cuối
   - → type: "expense"

2. 💸 CHUYỂN KHOẢN NGÂN HÀNG (MoMo, Banking, ZaloPay, VNPay...)
   - Có từ: "Chuyển khoản", "Transfer", "Giao dịch thành công"
   - Hiển thị: Người gửi/nhận, số tiền, nội dung chuyển khoản
   - Có mã giao dịch (Transaction ID)
   
   🔍 QUAN TRỌNG - Xác định thu/chi cho chuyển khoản:
   
   A) Nếu NGƯỜI DÙNG là người GỬI tiền:
      - Từ khóa: "Bạn đã chuyển", "Chuyển tiền đến", "You sent", "Transfer to"
      - Số dư giảm
      - → type: "expense" (chi tiêu)
      - merchant: Tên người nhận hoặc tên app
      - description: "Chuyển khoản cho [tên người nhận] - [nội dung]"
   
   B) Nếu NGƯỜI DÙNG là người NHẬN tiền:
      - Từ khóa: "Bạn đã nhận", "Nhận tiền từ", "You received", "Transfer from"
      - Số dư tăng
      - → type: "income" (thu nhập)
      - merchant: Tên người gửi hoặc tên app
      - description: "Nhận chuyển khoản từ [tên người gửi] - [nội dung]"
   
   ${hasVoice ? `C) Nếu KHÔNG RÕ từ ảnh → Ưu tiên thông tin từ VOICE:
      - Voice nói "chuyển tiền cho", "trả tiền" → expense
      - Voice nói "nhận tiền", "được chuyển" → income` : ''}

3. 🧾 BIÊN LAI THU NHẬP (Lương, hợp đồng, thanh toán dịch vụ)
   - Có từ: "Phiếu thu", "Receipt", "Biên lai", "Payment received"
   - → type: "income"

4. 📄 HÓA ĐƠN DỊCH VỤ (Điện, nước, internet, thuê nhà...)
   - Có từ: "Hóa đơn", "Invoice", "Bill"
   - Thông tin dịch vụ, kỳ thanh toán
   - → type: "expense"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 YÊU CẦU TRÍCH XUẤT THÔNG TIN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ amount (number): Số tiền chính xác
   ✓ Tìm số tiền chính:
     - Hóa đơn: TOTAL, TỔNG CỘNG, THÀNH TIỀN
     - Chuyển khoản: "Số tiền", "Amount", số tiền lớn nhất trên màn hình
   ✓ Chuyển đổi: "2 củ" → 2000000, "50k" → 50000
   ✓ Loại bỏ dấu phẩy, chấm, ký tự đặc biệt
   ✓ Trả về số nguyên thuần túy (ví dụ: 350000)
   ${hasVoice ? '✓ Nếu voice nói số tiền khác ảnh → ưu tiên voice' : ''}

2️⃣ type (string): Loại giao dịch
   ✓ "expense" - Chi tiêu:
     - Hóa đơn mua hàng, dịch vụ
     - Chuyển khoản đi (bạn gửi tiền cho người khác)
     - Thanh toán hóa đơn
   
   ✓ "income" - Thu nhập:
     - Biên lai lương, thưởng
     - Chuyển khoản đến (bạn nhận tiền từ người khác)
     - Thanh toán nhận được
   
   🚨 ĐẶC BIỆT QUAN TRỌNG cho chuyển khoản:
   - Xem kỹ HƯỚNG MŨI TÊN trên giao diện
   - Xem NGƯỜI GỬI và NGƯỜI NHẬN là ai
   - Xem số dư TĂNG hay GIẢM (nếu có)
   ${hasVoice ? '- Nếu không rõ → Nghe voice để xác định' : ''}

3️⃣ category_name (string): Danh mục
   ✓ Chọn từ danh sách có sẵn (khớp chính xác)
   ✓ Gợi ý phân loại:
     - Chuyển khoản cho ăn uống → "Ăn uống"
     - Chuyển khoản Grab → "Di chuyển"
     - Chuyển khoản mua hàng → "Mua sắm"
     - Nhận lương qua banking → "Lương"
     - Chuyển khoản không rõ mục đích → "Khác"
   ${hasVoice ? '✓ Voice có thể nói rõ mục đích → dùng để phân loại' : ''}

4️⃣ merchant (string|null): Người/Nơi giao dịch
   
   📱 Với CHUYỂN KHOẢN:
   ✓ Nếu là CHI TIÊU (gửi đi):
     - merchant = Tên người nhận
     - Ví dụ: "Nguyễn Văn A", "MoMo - Grab", "Shopee"
   
   ✓ Nếu là THU NHẬP (nhận về):
     - merchant = Tên người gửi
     - Ví dụ: "Công ty ABC", "Nguyễn Thị B", "Khách hàng"
   
   🏪 Với HÓA ĐƠN:
   ✓ merchant = Tên cửa hàng/nhà hàng
   ✓ Viết hoa chữ cái đầu: "Nhà Hàng Phở Việt"
   ✓ null nếu không xác định được

5️⃣ date (string): Ngày giao dịch
   ✓ Format: "YYYY-MM-DD" (bắt buộc)
   ✓ Tìm ngày trên bill/giao dịch
   ✓ Mặc định: "${dayjs().format('YYYY-MM-DD')}" nếu không có
   ✓ Ví dụ: "11/12/2024" → "2024-12-11"

6️⃣ description (string): Mô tả giao dịch
   
   📱 Với CHUYỂN KHOẢN:
   ✓ Template CHI TIÊU: "Chuyển khoản cho [tên người nhận] - [nội dung CK]"
   ✓ Template THU NHẬP: "Nhận chuyển khoản từ [tên người gửi] - [nội dung CK]"
   ✓ Lấy nội dung chuyển khoản nếu có (thường có trên bill)
   ${hasVoice ? '✓ Bổ sung context từ voice: mục đích, lý do chuyển' : ''}
   
   🏪 Với HÓA ĐƠN:
   ✓ Template: "[Hoạt động] tại [merchant]"
   ✓ Ví dụ: "Ăn trưa tại Nhà Hàng Phở Việt"
   
   📝 Ví dụ cụ thể:
   - "Chuyển khoản cho Nguyễn Văn A - Tiền ăn trưa"
   - "Nhận chuyển khoản từ công ty - Lương tháng 12"
   - "Thanh toán Grab qua MoMo"
   - "Mua sắm Shopee qua ZaloPay"

7️⃣ items (array): Chi tiết các món/sản phẩm
   ✓ Chỉ áp dụng cho HÓA ĐƠN truyền thống có danh sách items
   ✓ Format: [{"name": "Phở bò", "quantity": 1, "price": 50000}]
   ✓ Với CHUYỂN KHOẢN: để [] (mảng rỗng)
   ✓ Với HÓA ĐƠN không có chi tiết: []

8️⃣ confidence (number): Độ tin cậy
   ✓ 0.9-1.0: Rất rõ ràng (có đầy đủ thông tin, số tiền rõ)
   ✓ 0.7-0.9: Rõ ràng (đọc được hầu hết thông tin)
   ✓ 0.5-0.7: Khá mờ (thiếu một số thông tin)
   ✓ < 0.5: Rất mờ → yêu cầu nhập thủ công
   
   Factors ảnh hưởng confidence:
   - Ảnh rõ nét, số tiền rõ → +0.2
   - Có merchant/người gửi nhận → +0.1
   - Có nội dung chuyển khoản → +0.1
   ${hasVoice ? '- Voice cung cấp thêm context → +0.15' : ''}
   - Không rõ hướng giao dịch → -0.3
   - Ảnh mờ, số tiền khó đọc → -0.4

${hasVoice ? `9️⃣ voiceTranscript (string): Phiên âm giọng nói
   ✓ Viết lại chính xác 100% những gì người dùng nói
   ✓ Giữ nguyên ngữ cảnh, từ lóng, tên người
   ✓ Ví dụ: "Hôm nay chuyển 2 củ cho anh Nam tiền cơm team, nhớ ghi vào ăn uống"
` : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 VÍ DỤ CỤ THỂ
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VÍ DỤ 1: Chuyển khoản MoMo đi (CHI TIÊU)
Ảnh: "Bạn đã chuyển 500,000đ cho Nguyễn Văn A - Nội dung: Tiền ăn"
{
  "amount": 500000,
  "type": "expense",
  "category_name": "Ăn uống",
  "merchant": "Nguyễn Văn A",
  "date": "${dayjs().format('YYYY-MM-DD')}",
  "description": "Chuyển khoản cho Nguyễn Văn A - Tiền ăn",
  "items": [],
  "confidence": 0.92
}

VÍ DỤ 2: Nhận lương qua Banking (THU NHẬP)
Ảnh: "Bạn nhận 15,000,000đ từ CÔNG TY ABC - Lương tháng 12"
{
  "amount": 15000000,
  "type": "income",
  "category_name": "Lương",
  "merchant": "Công Ty ABC",
  "date": "${dayjs().format('YYYY-MM-DD')}",
  "description": "Nhận chuyển khoản từ Công Ty ABC - Lương tháng 12",
  "items": [],
  "confidence": 0.95
}

VÍ DỤ 3: Hóa đơn nhà hàng (CHI TIÊU)
Ảnh: Bill nhà hàng có items, tổng 350k
{
  "amount": 350000,
  "type": "expense",
  "category_name": "Ăn uống",
  "merchant": "Nhà Hàng Phở Việt",
  "date": "${dayjs().format('YYYY-MM-DD')}",
  "description": "Ăn tối tại Nhà Hàng Phở Việt",
  "items": [
    {"name": "Phở bò", "quantity": 2, "price": 120000},
    {"name": "Nước ngọt", "quantity": 3, "price": 45000}
  ],
  "confidence": 0.88
}

VÍ DỤ 4: Thanh toán Grab qua MoMo (CHI TIÊU)
Ảnh: "Thanh toán Grab - 85,000đ"
${hasVoice ? 'Voice: "Tiền Grab về nhà tối qua"' : ''}
{
  "amount": 85000,
  "type": "expense",
  "category_name": "Di chuyển",
  "merchant": "Grab",
  "date": "${dayjs().format('YYYY-MM-DD')}",
  "description": "Thanh toán Grab qua MoMo${hasVoice ? ' - Về nhà tối qua' : ''}",
  "items": [],
  "confidence": 0.90${hasVoice ? ',\n  "voiceTranscript": "Tiền Grab về nhà tối qua"' : ''}
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ QUY TẮC XỬ LÝ (BẮT BUỘC TUÂN THỦ)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Luôn trả về JSON thuần túy, KHÔNG có \`\`\`json, KHÔNG có text giải thích
✓ amount phải là số nguyên, KHÔNG dấu phẩy, KHÔNG đơn vị, KHÔNG chữ
✓ type chỉ có 2 giá trị: "expense" hoặc "income"
✓ Với chuyển khoản: XÁC ĐỊNH ĐÚNG HƯỚNG (gửi đi hay nhận về)
${hasVoice ? '✓ Voice có độ ưu tiên CAO HƠN ảnh khi có xung đột' : ''}
✓ date luôn theo format "YYYY-MM-DD"
✓ merchant: tên người/nơi giao dịch, null nếu không có
✓ description: rõ ràng, có context đầy đủ
✓ items: [] cho chuyển khoản, chỉ fill cho hóa đơn có items
✓ Nếu không chắc chắn → giảm confidence, ĐỪNG bịa dữ liệu

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 NGÀY THAM KHẢO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hôm nay là: ${dayjs().format('dddd, DD/MM/YYYY')}

BẮT ĐẦU PHÂN TÍCH NGAY - CHỈ TRẢ VỀ JSON!
`.trim();
}