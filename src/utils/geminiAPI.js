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
      model: 'gemini-2.0-flash-exp',
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
 * Phân tích multimodal (ảnh + audio) với Gemini
 * Sử dụng File API để upload file lên Google trước
 */
export async function geminiAnalyzeMultimodal(imageUrl, voiceUrl = null, prompt) {
  try {
    console.log('📤 Uploading files to Gemini...');

    const uploadedFiles = [];
    const contentParts = [];

    // Upload image nếu có
    if (imageUrl) {
      console.log('📸 Downloading image from:', imageUrl);
      const imagePath = await downloadFileToTemp(imageUrl, `bill_${Date.now()}.jpg`);
      const imageMimeType = getMimeTypeFromUrl(imageUrl);

      console.log('⬆️ Uploading image to Gemini...');
      const imageFile = await ai.files.upload({
        file: imagePath,
        config: { mimeType: imageMimeType },
      });

      console.log('✅ Image uploaded:', imageFile.uri);
      uploadedFiles.push({ path: imagePath, file: imageFile });

      // Add to content
      contentParts.push({
        fileData: {
          mimeType: imageFile.mimeType,
          fileUri: imageFile.uri,
        }
      });
    }

    // Upload audio nếu có
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

      // Add to content
      contentParts.push({
        fileData: {
          mimeType: audioFile.mimeType,
          fileUri: audioFile.uri,
        }
      });
    }

    // Add text prompt
    contentParts.push({ text: prompt });

    // Generate content với files đã upload
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
        console.log(`❌ Deleted: ${file.uri}`);
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
/**
 * Phân tích multimodal với inlineData (FASTER VERSION)
 * Sử dụng base64 encoding trực tiếp, không cần upload file lên Google
 * 
 * @param {string} imageUrl - URL ảnh bill từ Cloudinary
 * @param {string|null} voiceUrl - URL audio từ Cloudinary (optional)
 * @param {string} prompt - Text prompt
 * @returns {Object} Response từ Gemini
 */
export async function geminiAnalyzeMultimodal_new(imageUrl, voiceUrl = null, prompt) {
  try {
    console.log('📤 Starting multimodal analysis (inline data mode)...');
    if (!prompt || prompt.trim().length === 0) {
      throw new Error('prompt is required');
    }

    const contents = [];

    // ============== Process Image ==============
    if (imageUrl) {
      console.log('📸 Processing image...');

      const imageData = await downloadFileAsBase64(imageUrl);
      const imageMimeType = getMimeType(imageUrl, imageData.contentType);
      console.log(`📁 Image URL: ${imageData.base64}`);
      console.log(`✅ Image ready: ${imageMimeType}, ${(imageData.size / 1024).toFixed(2)}KB`);

      contents.push({
        inlineData: {
          mimeType: imageMimeType,
          data: imageData.base64,
        }
      });
    }

    // ============== Process Audio ==============
    if (voiceUrl) {
      console.log('🎤 Processing audio...');

      const audioData = await downloadFileAsBase64(voiceUrl);
      const audioMimeType = getMimeType(voiceUrl, audioData.contentType);
      console.log(`📁 Audio URL: ${audioData.base64}`);
      console.log(`✅ Audio ready: ${audioMimeType}, ${(audioData.size / 1024).toFixed(2)}KB`);

      contents.push({
        inlineData: {
          mimeType: audioMimeType,
          data: audioData.base64,
        }
      });
    }

    if (contents.length === 0) {
      throw new Error('no media provided');
    }

    // ============== Add Text Prompt ==============
    contents.push({ text: prompt });

    console.log(`🤖 Calling Gemini with ${contents.length} content parts...`);

    async function callModel(model) {
      return await ai.models.generateContent({
        model,
        contents: [{ role: 'user', parts: contents }],
        generationConfig: {
          temperature: 0.3,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        }
      });
    }

    let result;
    try {
      result = await callModel('gemini-2.0-flash');
    } catch (e1) {
      const retryDelay = e1?.error?.details?.find?.(d => d['@type']?.includes('RetryInfo'))?.retryDelay || null;
      const isQuota = e1?.error?.status === 'RESOURCE_EXHAUSTED' || /Quota exceeded|rate[- ]?limit/i.test(String(e1?.error?.message || e1?.message || '')) || e1?.error?.code === 429;
      if (!isQuota) throw e1;
      console.warn('⚠️ Quota exhausted for gemini-2.0-flash. Falling back to gemini-1.5-flash.', retryDelay ? `retryAfter=${retryDelay}` : '');
      try {
        result = await callModel('gemini-1.5-flash');
      } catch (e2) {
        const isQuota2 = e2?.error?.status === 'RESOURCE_EXHAUSTED' || e2?.error?.code === 429;
        if (!isQuota2) throw e2;
        console.warn('⚠️ Quota exhausted for gemini-1.5-flash. Falling back to gemini-1.5-flash-8b.');
        result = await callModel('gemini-1.5-flash-8b');
      }
    }

    const text = result?.text || '';

    if (!text) {
      throw new Error('Gemini returned empty response');
    }

    console.log('✅ Analysis complete');

    return {
      response: {
        text: () => (typeof text === 'string' ? text : ''),
      },
      raw: result,
    };

  } catch (err) {
    console.error('❌ Gemini multimodal error:', typeof err === 'object' ? JSON.stringify(err) : String(err));

    // User-friendly error messages
    if (String(err?.error?.status || err?.message || '').includes('RESOURCE_EXHAUSTED') || err?.error?.code === 429) {
      throw new Error('Hết hạn mức sử dụng (quota/rate limit). Vui lòng thử lại sau.');
    }
    if (err.message?.includes('invalid') || err.message?.includes('format')) {
      throw new Error('File không đúng định dạng hoặc bị lỗi');
    }
    if (err.message?.includes('size') || err.message?.includes('large')) {
      throw new Error('File quá lớn, vui lòng chọn file nhỏ hơn');
    }
    if (err.message?.includes('SAFETY')) {
      throw new Error('Nội dung file vi phạm chính sách an toàn');
    }

    throw err;
  }
}
