import { GoogleGenAI } from '@google/genai';

export async function geminiChat(contents) {
    const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

    try {
        const result = await ai.models.generateContent({
            model: "gemini-2.5-flash",
            contents: contents,
        });
        console.log("response: " + result);
        return result.text;
    } catch (err) {
        console.error('Gemini error:', err);
    }
    return null;
}