import { GoogleGenAI } from '@google/genai';

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

export async function geminiChat(contents) {
  try {
    const result = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents,
    });
    console.log('Gemini raw result:', result);
    const text = result?.text ? result.text : (typeof result?.text === 'string' ? result.text : '');
    return {
      response: {
        text: () => (typeof text === 'string' ? text : ''),
      },
      raw: result,
    };
  } catch (err) {
    console.error('Gemini error:', err);
    return null;
  }
}

export async function geminiClassify(text) {
  const prompt = `Phân tích câu sau và trả về JSON đúng định dạng.
  Câu: "${text}"
  Danh mục có sẵn: Ăn uống,Đi chợ, Di chuyển, Mua sắm, Giải trí, Lương, Thưởng, Khác
  Nếu xác định danh mục nhưng không có trong danh mục có sẵn thêm vào json 1 trường "category_likely" : "danh mục đó"
  Loại: income hoặc expense

  Trích xuất:
  - Từ khóa đặc trưng (2-3 từ quan trọng để xác định danh mục, viết thường, không dấu)
  - Số tiền chính xác (nếu có)
  - Mô tả ngắn gọn
 ví dụ "Hôm nay đi nhậu hết 2 củ"
  Trả về đúng JSON:
  {
    "type": "expense",
    "category": "Ăn Uống",
    "amount": 200000,
    "amount_in_text": "2 triệu",
    "currency": "VND",
    "description": "đi nhậu",
    "keywords": ["đi nhậu"],
    "confidence": 0.95
  }
    ví dụ "Hôm nay đi mua rau hết 200k"
  Trả về đúng JSON:
  {
    "type": "expense",
    "category": "Đi chợ",
    "amount": 200000,
    "amount_in_text": "2 200k ",
    "currency": "VND", 
    "description": đi mua rau",
    "keywords": ["đi mua rau"],
    "confidence": 0.95
  }
  `;

  try {
    const contents = [{ role: 'user', parts: [{ text: prompt }] }];
    const result = await geminiChat(contents);
    if (!result || !result.response || typeof result.response.text !== 'function') return null;
    const raw = result.response.text().trim();
    const jsonStr = raw
      .replace(/^```json\s */i, '')
      .replace(/^```\s*/i, '')
      .replace(/\s*```$/g, '')
      .trim();
    return JSON.parse(jsonStr);
  } catch (err) {
    console.error('Gemini classify error:', err);
    return null;
  }
}
