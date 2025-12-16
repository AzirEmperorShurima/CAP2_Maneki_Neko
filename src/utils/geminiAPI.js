import { GoogleGenAI } from '@google/genai';
import axios from 'axios';
import fs from 'fs';
import path from 'path';
import os from 'os';

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

/**
 * Text chat với Gemini (không có file)
 */
export async function geminiChat(contents) {
  try {
    const result = await ai.models.generateContent({
      model: 'gemini-2.0-flash',
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

/**
 * Download file từ URL về temp folder
 */
async function downloadFileToTemp(url, filename) {
  try {
    const response = await axios.get(url, { responseType: 'arraybuffer' });
    const tempDir = os.tmpdir();
    const tempPath = path.join(tempDir, filename);
    await fs.promises.writeFile(tempPath, response.data);
    return tempPath;
  } catch (error) {
    console.error('Error downloading file:', error);
    throw new Error(`Không thể tải file từ URL: ${url}`);
  }
}

/**
 * Get mime type từ URL
 */
function getMimeTypeFromUrl(url) {
  const ext = path.extname(url).toLowerCase();
  const mimeTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.mp3': 'audio/mpeg',
    '.wav': 'audio/wav',
    '.m4a': 'audio/mp4',
    '.mp4': 'audio/mp4',
  };
  return mimeTypes[ext] || 'application/octet-stream';
}

async function downloadFileAsBase64(url) {
  const response = await axios.get(url, { responseType: 'arraybuffer' });
  const buffer = Buffer.from(response.data);
  return {
    base64: buffer.toString('base64'),
    contentType: response.headers['content-type'] || 'application/octet-stream',
    size: buffer.length
  };
}

function getMimeType(url, headerContentType) {
  const byExt = getMimeTypeFromUrl(url);
  if (byExt && byExt !== 'application/octet-stream') return byExt;
  if (headerContentType) return headerContentType;
  return 'application/octet-stream';
}

/**
 * Phân tích multimodal với inlineData (FASTER VERSION)
 * Hỗ trợ: chỉ ảnh, chỉ voice, hoặc cả hai
 * 
 * @param {string|null} imageUrl - URL ảnh từ Cloudinary (optional)
 * @param {string|null} voiceUrl - URL audio từ Cloudinary (optional)
 * @param {string} prompt - Text prompt
 * @returns {Object} Response từ Gemini
 */
export async function geminiAnalyzeMultimodal_new(imageUrl = null, voiceUrl = null, prompt) {
  try {
    if (!prompt || prompt.trim().length === 0) {
      throw new Error('prompt is required');
    }

    const contents = [];

    // Thêm ảnh nếu có
    if (imageUrl) {
      console.log('📷 Processing image:', imageUrl);
      const imageData = await downloadFileAsBase64(imageUrl);
      const imageMimeType = getMimeType(imageUrl, imageData.contentType);
      contents.push({
        inlineData: {
          mimeType: imageMimeType,
          data: imageData.base64,
        }
      });
    }

    // Thêm voice nếu có
    if (voiceUrl) {
      console.log('🎤 Processing voice:', voiceUrl);
      const audioData = await downloadFileAsBase64(voiceUrl);
      const audioMimeType = getMimeType(voiceUrl, audioData.contentType);
      contents.push({
        inlineData: {
          mimeType: audioMimeType,
          data: audioData.base64,
        }
      });
    }

    // Phải có ít nhất 1 media
    if (contents.length === 0) {
      throw new Error('Phải có ít nhất ảnh hoặc voice');
    }

    // Thêm text prompt
    contents.push({ text: prompt });

    // Gọi Gemini API
    async function callModel(model) {
      return await ai.models.generateContent({
        model,
        contents: contents,
      });
    }

    let result = "";
    try {
      result = await callModel('gemini-2.5-flash');
      console.log('✅ Response from gemini-2.5-flash');
    } catch (e1) {
      console.log('⚠️ Error calling gemini-2.5-flash:', e1.message);
      console.log('🔄 Trying gemini-2.0-flash...');
      try {
        result = await callModel('gemini-2.5-flash-lite');
        console.log('✅ Response from gemini-2.0-flash');
      } catch (e2) {
        console.log('❌ Error calling gemini-2.0-flash:', e2.message);
        throw new Error('Không thể kết nối với Gemini API');
      }
    }

    const text = typeof result?.response?.text === 'function'
      ? (result.response.text() || '').trim()
      : (typeof result?.text === 'string' ? result.text.trim() : '');

    if (!text) {
      throw new Error('Gemini returned empty response');
    }

    return {
      response: {
        text: () => text,
      },
      raw: result,
    };

  } catch (err) {
    console.error('❌ Gemini multimodal error:', err);
    throw err;
  }
}

/**
 * Phân tích multimodal (File API version - LEGACY)
 * Giữ lại để tương thích, nhưng nên dùng geminiAnalyzeMultimodal_new
 */
export async function geminiAnalyzeMultimodal(imageUrl, voiceUrl = null, prompt) {
  try {
    console.log('📤 Uploading files to Gemini...');

    const uploadedFiles = [];
    const contentParts = [];

    if (imageUrl) {
      const imagePath = await downloadFileToTemp(imageUrl, `bill_${Date.now()}.jpg`);
      const imageMimeType = getMimeTypeFromUrl(imageUrl);

      console.log('⬆️ Uploading image to Gemini...');
      const imageFile = await ai.files.upload({
        file: imagePath,
        config: { mimeType: imageMimeType },
      });

      console.log('✅ Image uploaded:', imageFile.uri);
      uploadedFiles.push({ path: imagePath, file: imageFile });
      contentParts.push({
        fileData: {
          mimeType: imageFile.mimeType,
          fileUri: imageFile.uri,
        }
      });
    }

    if (voiceUrl) {
      console.log('🎤 Downloading audio from:', voiceUrl);
      const audioPath = await downloadFileToTemp(voiceUrl, `voice_${Date.now()}.mp3`);
      const audioMimeType = getMimeTypeFromUrl(voiceUrl);

      console.log('⬆️ Uploading audio to Gemini...');
      const audioFile = await ai.files.upload({
        file: audioPath,
        config: { mimeType: audioMimeType },
      });

      console.log('✅ Audio uploaded:', audioFile.uri);
      uploadedFiles.push({ path: audioPath, file: audioFile });
      contentParts.push({
        fileData: {
          mimeType: audioFile.mimeType,
          fileUri: audioFile.uri,
        }
      });
    }

    contentParts.push({ text: prompt });

    console.log('🤖 Generating content with Gemini...');
    const result = await ai.models.generateContent({
      model: 'gemini-2.0-flash',
      contents: [{ role: 'user', parts: contentParts }],
    });

    // Cleanup temp files
    console.log('🧹 Cleaning up temp files...');
    for (const { path: filePath } of uploadedFiles) {
      try {
        await fs.promises.unlink(filePath);
      } catch (err) {
        console.warn('Failed to delete temp file:', filePath);
      }
    }

    try {
      console.log('🗑️ Deleting files from Gemini API...');
      for (const { file } of uploadedFiles) {
        await ai.files.delete({ name: file.name });
        console.log(`✅ Deleted: ${file.uri}`);
      }
    } catch (err) {
      console.warn('Failed to delete Gemini API file:', err);
    }

    const text = result?.text || '';
    console.log('✅ Analysis complete');

    return {
      response: {
        text: () => (typeof text === 'string' ? text : ''),
      },
      raw: result,
    };

  } catch (err) {
    console.error('❌ Gemini multimodal error:', err);
    throw err;
  }
}