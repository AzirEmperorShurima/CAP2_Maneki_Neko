import multer from 'multer';
import cloudinary from '../config/cloudinary.js';
import streamifier from 'streamifier';
import sharp from 'sharp';

const maxImageSize = 10 * 1024 * 1024;
const maxAudioSize = 10 * 1024 * 1024;

// File filter cho cả ảnh và audio
const fileFilter = (req, file, cb) => {
    const allowedImageTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];
    const allowedAudioTypes = ['audio/mpeg', 'audio/wav', 'audio/mp3', 'audio/m4a', 'audio/mp4'];

    if (file.fieldname === 'billImage') {
        if (allowedImageTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Ảnh chỉ chấp nhận định dạng: JPEG, PNG, WebP'));
        }
    } else if (file.fieldname === 'voice') {
        if (allowedAudioTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Audio chỉ chấp nhận định dạng: MP3, WAV, M4A'));
        }
    } else {
        cb(new Error('Field không hợp lệ'));
    }
};

// Multer config
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: maxImageSize,
        files: 2,
    },
    fileFilter,
}).fields([
    { name: 'billImage', maxCount: 1 },
    { name: 'voice', maxCount: 1 }
]);

const uploadImageToCloudinary = (buffer, folder = 'bills') => {
    return new Promise(async (resolve, reject) => {
        try {
            const optimizedBuffer = await sharp(buffer)
                .resize(1920, 1920, {
                    fit: 'inside',
                    withoutEnlargement: true
                })
                .jpeg({ quality: 85, progressive: true })
                .toBuffer();

            const stream = cloudinary.uploader.upload_stream(
                {
                    folder: folder,
                    resource_type: 'image',
                    transformation: [
                        { quality: 'auto:good' },
                        { fetch_format: 'auto' }
                    ],
                },
                (error, result) => {
                    if (error) {
                        reject(error);
                    } else {
                        resolve({
                            url: result.secure_url,
                            publicId: result.public_id,
                            width: result.width,
                            height: result.height,
                            format: result.format,
                            bytes: result.bytes
                        });
                    }
                }
            );

            streamifier.createReadStream(optimizedBuffer).pipe(stream);
        } catch (error) {
            reject(error);
        }
    });
};

const uploadAudioToCloudinary = (buffer, folder = 'voices') => {
    return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
            {
                folder: folder,
                resource_type: 'video',
                format: 'mp3'
            },
            (error, result) => {
                if (error) {
                    reject(error);
                } else {
                    resolve({
                        url: result.secure_url,
                        publicId: result.public_id,
                        format: result.format,
                        bytes: result.bytes,
                        duration: result.duration
                    });
                }
            }
        );

        streamifier.createReadStream(buffer).pipe(stream);
    });
};

const generateThumbnailUrl = (publicId) => {
    return cloudinary.url(publicId, {
        transformation: [
            { width: 300, height: 300, crop: 'fill' },
            { quality: 'auto:low' },
            { fetch_format: 'auto' }
        ]
    });
};

export const billUploadMiddleware = (req, res, next) => {
    upload(req, res, async (err) => {
        if (err instanceof multer.MulterError) {
            if (err.code === 'LIMIT_FILE_SIZE') {
                return res.status(400).json({
                    success: false,
                    message: 'File quá lớn. Tối đa 10MB'
                });
            }
            return res.status(400).json({
                success: false,
                message: err.message
            });
        }

        if (err) {
            return res.status(400).json({
                success: false,
                message: err.message
            });
        }

        if (!req.files || (!req.files.billImage && !req.files.voice)) {
            return next();
        }

        try {
            const uploadPromises = [];
            const uploadResults = {};

            if (req.files.billImage && req.files.billImage[0]) {
                const imageBuffer = req.files.billImage[0].buffer;
                uploadPromises.push(
                    uploadImageToCloudinary(imageBuffer, 'bills').then(result => {
                        uploadResults.billImage = result;
                    })
                );
            }

            if (req.files.voice && req.files.voice[0]) {
                const voiceBuffer = req.files.voice[0].buffer;
                uploadPromises.push(
                    uploadAudioToCloudinary(voiceBuffer, 'voices').then(result => {
                        uploadResults.voice = result;
                    })
                );
            }

            await Promise.all(uploadPromises);

            if (uploadResults.billImage) {
                uploadResults.billImage.thumbnail = generateThumbnailUrl(uploadResults.billImage.publicId);
            }

            req.uploadedFiles = uploadResults;

            next();

        } catch (error) {
            console.error('Lỗi upload:', error);
            return res.status(500).json({
                success: false,
                message: 'Lỗi khi upload file lên Cloudinary',
                error: error.message
            });
        }
    });
};

// Helper function để xóa files từ Cloudinary
export const deleteFromCloudinary = async (publicIds) => {
    try {
        const deletePromises = publicIds.map(({ publicId, resourceType = 'image' }) => {
            return cloudinary.uploader.destroy(publicId, { resource_type: resourceType });
        });
        await Promise.all(deletePromises);
        return true;
    } catch (error) {
        console.error('Lỗi xóa file từ Cloudinary:', error);
        return false;
    }
};