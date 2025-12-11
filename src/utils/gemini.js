import { GoogleGenAI } from '@google/genai';

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

export async function geminiChat(contents) {
  try {
    const result = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents,
    });
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
}