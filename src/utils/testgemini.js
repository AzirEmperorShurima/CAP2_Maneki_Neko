import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const base64ImageFile = fs.readFileSync("./1.jpg", {
    encoding: "base64",
});

const contents = [
    {
        inlineData: {
            mimeType: "image/jpeg",
            data: base64ImageFile,
        },
    },
    { text: "Caption this image." },
];

const response = await ai.models.generateContent({
    model: "gemini-2.5-flash",
    contents: contents,
});
console.log(response.text);