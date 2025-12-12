import category from "../models/category.js";
import user from "../models/user.js";
import { validateCreateCategory, validateUpdateCategory, validateGetCategoriesQuery } from "../validations/category.js";
import cloudinary from '../config/cloudinary.js';

export const createCategory = async (req, res) => {
    const { error, value } = validateCreateCategory(req.body);
    if (error) {
        return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { name, type, scope, image } = value;
    const _user = await user.findById(req.userId).lean();
    if (!_user) return res.status(404).json({ error: 'User not found' });

    const _category = new category({
        name,
        type,
        scope: scope || 'personal',
        userId: _user._id,
        familyId: _user.familyId || null,
        isDefault: scope === 'system',
        image: image?.trim() || "",
    });
    await _category.save();

    res.json({ message: 'Tạo danh mục thành công', data: _category });
};

export const updateCategory = async (req, res) => {
    try {
        const { id } = req.params;
        const { error, value } = validateUpdateCategory(req.body);
        if (error) {
            return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
        }
        const { name, type, image } = value;
        const _user = await user.findById(req.userId).lean();

        const _category = await category.findById(id);
        if (!_category) return res.status(404).json({ error: 'Không tìm thấy category' });

        if (_category.scope === 'system' && _category.isDefault) {
            return res.status(400).json({ error: 'Category mặc định không thể chỉnh sửa' });
        }
        if (_category.scope === 'personal') {
            if (_category.userId?.toString() !== req.userId.toString()) {
                return res.status(403).json({ error: 'Bạn không có quyền sửa danh mục này' });
            }
        } else if (_category.scope === 'family') {
            if (!_user?.familyId || _category.familyId?.toString() !== _user.familyId.toString()) {
                return res.status(403).json({ error: 'Bạn không có quyền sửa danh mục của gia đình này' });
            }
        }

        const update = {};
        if (typeof name === 'string') update.name = name.trim();
        if (type === 'income' || type === 'expense') update.type = type;
        if (typeof image === 'string') update.image = image.trim();

        if (_category.scope === 'personal') update.userId = _category.userId;
        if (_category.scope === 'family') update.familyId = _category.familyId;

        const updated = await category.findByIdAndUpdate(id, update, { new: true });

        return res.json({ message: 'Cập nhật danh mục thành công', data: updated });
    } catch (err) {
        console.error('updateCategory error:', err);
        return res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getCategories = async (req, res) => {
    try {
        const { error, value } = validateGetCategoriesQuery(req.query);
        if (error) {
            return res.status(400).json({
                error: 'Invalid query',
                details: error.details.map(d => ({
                    field: d.path.join('.'),
                    message: d.message
                }))
            });
        }
        const { type } = value;
        const _user = await user.findById(req.userId).lean();

        if (!_user) {
            return res.status(404).json({ error: 'Không tìm thấy người dùng' });
        }

        // Build query conditions
        const orConditions = [
            { scope: 'system', isDefault: true },
            { scope: 'personal', userId: _user._id }
        ];

        if (_user.familyId) {
            orConditions.push({ scope: 'family', familyId: _user.familyId });
        }

        const match = { $or: orConditions };
        if (type) {
            match.type = type;
        }

        const categories = await category.find(match)
            .select('_id name type scope userId familyId isDefault image')
            .sort({ scope: 1, name: 1 })
            .lean();
        const normalizedCategories = categories.map(cat => {
            const { _id, ...rest } = cat;
            return {
                id: _id.toString(),
                ...rest,
                userId: cat.userId?.toString() || "",
                familyId: cat.familyId?.toString() || ""
            };
        });

        res.json({
            message: 'Lấy danh mục thành công',
            data: normalizedCategories
        });
    } catch (err) {
        console.error('getCategories error:', err);
        return res.status(500).json({ error: 'Lỗi server' });
    }
};


export const getCategoryImages = async (req, res) => {
    try {
        // Lấy folder từ query, nếu là 'root' hoặc rỗng thì không dùng prefix
        const folder = req.query.folder && typeof req.query.folder === 'string'
            ? req.query.folder.trim()
            : '';

        const maxResults = req.query.limit && Number(req.query.limit) > 0
            ? Math.min(Number(req.query.limit), 500)
            : 100;

        const nextCursor = req.query.next_cursor;

        // Cấu hình request
        const requestOptions = {
            type: 'upload',
            max_results: maxResults,
            resource_type: 'image',
        };

        // Chỉ thêm prefix nếu folder không rỗng và không phải 'root'
        if (folder && folder !== 'root') {
            requestOptions.prefix = `${folder}/`;
        }

        if (nextCursor) {
            requestOptions.next_cursor = nextCursor;
        }

        console.log('Cloudinary request options:', requestOptions);

        // Gọi Cloudinary API
        const result = await cloudinary.api.resources(requestOptions);

        console.log('Cloudinary found:', result.resources.length, 'images');

        // Xử lý dữ liệu
        const images = (result.resources || []).map(r => ({
            publicId: r.public_id,
            url: r.secure_url || r.url,
            thumbnail: r.secure_url ?
                r.secure_url.replace('/upload/', '/upload/w_300,h_300,c_fill/') :
                null,
            format: r.format,
            bytes: r.bytes,
            width: r.width,
            height: r.height,
            createdAt: r.created_at,
            // Xác định folder từ public_id
            folder: r.public_id.includes('/')
                ? r.public_id.split('/').slice(0, -1).join('/')
                : 'root',
            filename: r.public_id.split('/').pop()
        }));

        res.json({
            success: true,
            message: images.length > 0
                ? `Tìm thấy ${images.length} ảnh`
                : 'Không tìm thấy ảnh',
            data: {
                images,
                total: images.length,
                folder: folder || 'root',
                nextCursor: result.next_cursor || null,
                hasMore: !!result.next_cursor
            }
        });

    } catch (err) {
        console.error('getCategoryImages error:', err);

        if (err.error && err.error.http_code === 404) {
            return res.status(404).json({
                success: false,
                error: `Không tìm thấy folder '${req.query.folder}' trên Cloudinary`
            });
        }

        return res.status(500).json({
            success: false,
            error: 'Lỗi lấy danh sách ảnh từ Cloudinary',
            details: process.env.NODE_ENV === 'development' ? err.message : undefined
        });
    }
};
