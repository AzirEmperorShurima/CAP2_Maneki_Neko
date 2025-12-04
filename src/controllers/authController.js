import jwt from "jsonwebtoken";
import crypto from "crypto";
import User from "../models/user.js";
import { OAuth2Client } from "google-auth-library";
import { googleAppClientId } from "../config/googleAuth.js";
import { validateRegister, validateLogin, validateVerifyGoogle } from "../validations/auth.js";
import { registerFCMToken } from "../utils/fcm.js";
import { renewRefreshToken } from "../utils/auth.js";
import RefreshToken from "../models/refreshToken.js";

// ===== ĐĂNG KÝ =====
export const register = async (req, res) => {
    try {
        const { error, value } = validateRegister(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({
                    field: d.path.join('.'),
                    message: d.message
                }))
            });
        }

        const { email, password, username } = value;

        // Kiểm tra email đã tồn tại
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({
                error: 'Email này đã được sử dụng'
            });
        }

        // Tạo user mới
        const newUser = await User.create({
            email,
            password,
            username: username || email.split('@')[0],
            authProvider: 'local'
        });
        const accessToken = jwt.sign(
            { id: newUser._id },
            process.env.JWT_SECRET,
            { expiresIn: "7d" }
        );

        res.status(201).json({
            message: 'Đăng ký thành công',
            data: {
                userId: newUser._id,
                accessToken,
                expiresAt: 7 * 24 * 60 * 60
            }

        });
    } catch (err) {
        console.error('Register error:', err);

        if (err.code === 11000) {
            if (err.keyPattern?.email) {
                return res.status(400).json({ error: 'Email này đã được sử dụng' });
            }
        }

        res.status(500).json({ error: "Lỗi server" });
    }
};

// ===== ĐĂNG NHẬP =====
export const login = async (req, res) => {
    try {
        const { error, value } = validateLogin(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({
                    field: d.path.join('.'),
                    message: d.message
                }))
            });
        }

        const { email, password, deviceId, fcmToken, platform } = value;

        // Tìm user theo email
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({
                error: 'Email hoặc mật khẩu không đúng'
            });
        }

        // Kiểm tra user có mật khẩu không
        if (!user.hasPassword()) {
            return res.status(400).json({
                error: 'Tài khoản này chỉ có thể đăng nhập bằng Google',
                suggestion: 'Vui lòng sử dụng nút "Đăng nhập với Google"'
            });
        }

        // Kiểm tra mật khẩu
        const isPasswordValid = await user.comparePassword(password);
        if (!isPasswordValid) {
            return res.status(401).json({
                error: 'Email hoặc mật khẩu không đúng'
            });
        }

        // Tạo tokens
        const accessToken = jwt.sign(
            { id: user._id },
            process.env.JWT_SECRET,
            { expiresIn: "7d" }
        );

        // Optional: Refresh token logic
        // let refreshTokenValue;
        // if (deviceId) {
        //     refreshTokenValue = await renewRefreshToken(user._id, deviceId);
        // }

        // Response
        res.json({
            message: 'Đăng nhập thành công',
            data: {
                userId: user._id,
                accessToken,
                expiresAt: 7 * 24 * 60 * 60
            }
        });

        // Register FCM token (async)
        // if (fcmToken && deviceId && platform) {
        //     setImmediate(async () => {
        //         await registerFCMToken(user, { fcmToken, deviceId, platform });
        //     });
        // }

    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: "Lỗi server" });
    }
};

// ===== ĐĂNG NHẬP/ĐĂNG KÝ VỚI GOOGLE =====
export const verifyGoogleId = async (req, res) => {
    try {
        const { error, value } = validateVerifyGoogle(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({
                    field: d.path.join('.'),
                    message: d.message
                }))
            });
        }

        const { idToken, deviceId, fcmToken, platform } = value;

        // Verify Google token
        const client = new OAuth2Client(googleAppClientId);
        const ticket = await client.verifyIdToken({
            idToken,
            audience: googleAppClientId,
        });

        const payload = ticket.getPayload();
        const { sub: googleId, email, name, picture: avatar } = payload;

        if (!email) {
            return res.status(400).json({
                error: 'Không thể lấy email từ tài khoản Google'
            });
        }

        // TÌM USER THEO EMAIL HOẶC GOOGLE ID
        let user = await User.findOne({
            $or: [
                { email: email },
                { googleId: googleId }
            ]
        });

        if (user) {
            // USER ĐÃ TỒN TẠI

            // Case 1: User có email match nhưng chưa link Google
            if (!user.googleId) {
                user.googleId = googleId;
                user.authProvider = user.hasPassword() ? 'both' : 'google';
                user.avatar = user.avatar || avatar; // Update avatar nếu chưa có
                await user.save();

                console.log(`✅ Linked Google account to existing email: ${email}`);
            }

            // Case 2: User đã có Google ID rồi
            // → Đăng nhập bình thường

        } else {
            // USER CHƯA TỒN TẠI → TẠO MỚI
            user = await User.create({
                googleId,
                email,
                username: name || email.split('@')[0],
                avatar,
                password: '', // Không có password
                authProvider: 'google'
            });

            console.log(`✅ Created new user via Google: ${email}`);
        }

        // Tạo tokens
        const accessToken = jwt.sign(
            { id: user._id },
            process.env.JWT_SECRET,
            { expiresIn: "7d" }
        );

        // Optional: Refresh token
        // let refreshTokenValue;
        // if (deviceId) {
        //     refreshTokenValue = await renewRefreshToken(user._id, deviceId);
        // }

        res.json({
            message: 'Đăng nhập thành công',
            user: {
                id: user._id,
                username: user.username,
                email: user.email,
                avatar: user.avatar || null,
                authProvider: user.authProvider
            },
            accessToken,
            // refreshToken: refreshTokenValue,
            expiresAt: 7 * 24 * 60 * 60
        });

        // Register FCM token (async)
        // if (fcmToken && deviceId && platform) {
        //     setImmediate(async () => {
        //         await registerFCMToken(user, { fcmToken, deviceId, platform });
        //     });
        // }

    } catch (err) {
        console.error('Google auth error:', err);
        res.status(401).json({ error: "Token Google không hợp lệ" });
    }
};

// ===== ĐĂNG XUẤT =====
export const logout = async (req, res) => {
    try {
        const { deviceId } = req.body;

        if (!deviceId) {
            return res.status(400).json({
                error: 'deviceId là bắt buộc để đăng xuất thiết bị'
            });
        }

        const result = await RefreshToken.updateMany(
            {
                userId: req.userId,
                deviceId: deviceId,
                isValid: true
            },
            { isValid: false }
        );

        const message = result.modifiedCount === 0
            ? 'Không tìm thấy phiên đăng nhập của thiết bị này'
            : 'Đã đăng xuất thiết bị thành công';

        res.json({
            success: true,
            message: message
        });

    } catch (error) {
        console.error('Lỗi khi đăng xuất thiết bị:', error);
        res.status(500).json({ error: 'Lỗi server khi đăng xuất' });
    }
};
export const unlinkGoogleAccount = async (req, res) => {
    try {
        const userId = req.userId;

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ error: 'Không tìm thấy tài khoản' });
        }

        if (!user.googleId) {
            return res.status(400).json({
                error: 'Tài khoản chưa được liên kết với Google'
            });
        }

        // Phải có password mới cho phép unlink
        if (!user.hasPassword()) {
            return res.status(400).json({
                error: 'Không thể hủy liên kết. Vui lòng đặt mật khẩu trước.'
            });
        }

        user.googleId = undefined;
        user.authProvider = 'local';
        await user.save();

        res.json({
            success: true,
            message: 'Đã hủy liên kết tài khoản Google thành công'
        });

    } catch (error) {
        console.error('Lỗi khi hủy liên kết tài khoản Google:', error);
        res.status(500).json({ error: 'Không thể hủy liên kết tài khoản Google' });
    }
};

// ===== XÓA USER =====
export const deleteUser = async (req, res) => {
    try {
        const userId = req.params.userId || req.userId;

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ error: 'Không tìm thấy tài khoản' });
        }

        await user.deleteOne();

        res.json({
            success: true,
            message: 'Đã xóa tài khoản thành công'
        });

    } catch (error) {
        console.error('Lỗi khi xóa tài khoản:', error);
        res.status(500).json({ error: 'Không thể xóa tài khoản' });
    }
};

// ===== LẤY PROFILE =====
export const getUserProfile = async (req, res) => {
    try {
        const user = await User.findById(req.userId)
            .select('-password -googleId -__v')
            .populate({
                path: 'familyId',
                select: 'name adminId members',
                populate: {
                    path: 'members',
                    select: 'username avatar email',
                }
            });

        if (!user) {
            return res.status(404).json({ error: 'Không tìm thấy người dùng' });
        }

        const response = {
            _id: user._id,
            email: user.email,
            username: user.username,
            avatar: user.avatar || null,
            authProvider: user.authProvider,
            hasPassword: user.hasPassword(),
            hasGoogleLinked: user.isGoogleLinked(),
            family: null,
            isFamilyAdmin: user.isFamilyAdmin || false,
        };

        if (user.familyId) {
            const family = user.familyId;
            response.family = {
                _id: family._id,
                name: family.name,
                isAdmin: family.adminId.toString() === req.userId.toString(),
                memberCount: family.members.length,
                members: family.members.map(member => ({
                    _id: member._id,
                    username: member.username,
                    email: member.email,
                    avatar: member.avatar || null,
                    isAdmin: member._id.toString() === family.adminId.toString(),
                })),
            };
            response.isFamilyAdmin = response.family.isAdmin;
        }

        res.json({
            success: true,
            user: response
        });

    } catch (error) {
        console.error('Lỗi lấy thông tin user:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};