import jwt from "jsonwebtoken";
import crypto from "crypto";
import user from "../models/user.js";
import { OAuth2Client } from "google-auth-library";
import { googleAppClientId } from "../config/googleAuth.js";
import { validateRegister, validateLogin, validateVerifyGoogle } from "../validations/auth.js";
import { registerFCMToken } from "../utils/fcm.js";
import { renewRefreshToken } from "../utils/auth.js";
import RefreshToken from "../models/refreshToken.js";

export const register = async (req, res) => {
    try {
        const { error, value } = validateRegister(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }

        const { accountName, password } = value;
        const _user = await user.create({
            accountName,
            password: password,
        });

        res.status(201).json({
            user: {
                id: _user._id,
                accountName: _user.accountName,
            },
        });
    } catch (err) {
        console.error('Register error:', err);
        if (err.code === 11000) {
            if (err.keyPattern && err.keyPattern.accountName) {
                return res.status(400).json({ error: 'Tên đăng nhập đã tồn tại' });
            }
            if (err.keyPattern && err.keyPattern.email) {
                return res.status(400).json({ error: 'Email này đã được sử dụng' });
            }
        }

        res.status(500).json({ message: "Internal server error" });
    }
};

export const login = async (req, res) => {
    try {
        const { error, value } = validateLogin(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }

        const { accountName, password,
            //  deviceId, fcmToken, platform
             } = value;
        const _user = await user.findOne({ accountName });

        if (!_user) {
            return res.status(404).json({ error: 'Tên đăng nhập không tồn tại' });
        }

        // Kiểm tra xem tài khoản có mật khẩu không
        if (!_user.password || _user.password.length === 0) {
            return res.status(400).json({
                error: 'Tài khoản này chỉ có thể đăng nhập bằng Google'
            });
        }

        const isPasswordValid = await _user.comparePassword(password);
        if (!isPasswordValid) {
            return res.status(401).json({ error: 'Tên đăng nhập hoặc mật khẩu không đúng' });
        }
        // if (!deviceId) {
        //     return res.status(400).json({ error: 'deviceId là bắt buộc để quản lý phiên đăng nhập' });
        // }
        // Xóa các refresh token cũ của user trên deviceId này
        // const refreshTokenValue = await renewRefreshToken(_user._id, deviceId);

        const accessToken = jwt.sign(
            { id: _user._id },
            process.env.JWT_SECRET,
            { expiresIn: "7d" }
        );
        let fcmPayload = {};
        // if (fcmToken && deviceId && platform) {
        //     fcmPayload = {
        //         fcmToken,
        //         deviceId,
        //         platform
        //     }
        // }
        res.json({
            user: {
                id: _user._id,
                username: _user.username || null,
                email: _user.email,
                avatar: _user.avatar || null,
            },
            accessToken,
            // refreshToken: refreshTokenValue,
            expiresAt: 15 * 60
        });
        // setImmediate(async () => {
        //     const fcm = await registerFCMToken(_user, fcmPayload);
        //     if (fcm) {
        //         console.log('FCM token đã được đăng ký thành công');
        //     } else {
        //         console.log('FCM token đã được đăng ký thất bại');
        //     }
        // });

    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ message: "Internal server error" });
    }
};
export const verifyGoogleId = async (req, res) => {
    try {
        const { error, value } = validateVerifyGoogle(req.body);
        if (error) {
            return res.status(400).json({
                error: 'Invalid payload',
                details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
            });
        }
        const { idToken, deviceId, fcmToken, platform } = value;
        const client = new OAuth2Client(googleAppClientId);
        const ticket = await client.verifyIdToken({
            idToken,
            audience: googleAppClientId,
        });

        const payload = ticket.getPayload();
        const { sub: googleId, email, name, picture: avatar } = payload;

        // Tìm user theo googleId
        let userWithGoogleId = await user.findOne({ googleId });

        if (userWithGoogleId) {
            // Nếu googleId đã tồn tại trong hệ thống, đăng nhập với user đó
            const accessToken = jwt.sign(
                { id: userWithGoogleId._id },
                process.env.JWT_SECRET,
                { expiresIn: "7d" }
            );
            const refreshTokenValue = await renewRefreshToken(userWithGoogleId._id, deviceId);
            return res.json({
                user: {
                    id: userWithGoogleId._id,
                    username: userWithGoogleId.username || null,
                    email: userWithGoogleId.email,
                    avatar: userWithGoogleId.avatar || null,
                },
                accessToken,
                refreshToken: refreshTokenValue,
                expiresAt: 15 * 60
            });
        }

        // Nếu googleId chưa tồn tại trong hệ thống, tạo user mới với Google
        const newUser = await user.create({
            googleId,
            email,
            accountName: email.split('@')[0],
            username: name || email.split('@')[0],
            avatar,
            password: '' // Tài khoản chỉ dùng Google
        });
        const refreshTokenValue = crypto.randomBytes(64).toString('hex');

        const refreshToken = new RefreshToken({
            token: refreshTokenValue,
            userId: newUser._id,
            deviceId: deviceId,
            isValid: true,
            expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        });

        await RefreshToken.save();
        const accessToken = jwt.sign(
            { id: newUser._id },
            process.env.JWT_SECRET,
            { expiresIn: "7d" }
        );
        let fcmPayload = {};
        if (fcmToken && deviceId && platform) {
            fcmPayload = {
                fcmToken,
                deviceId,
                platform
            }
        }
        res.json({
            user: {
                id: newUser._id,
                username: newUser.username || null,
                email: newUser.email,
                avatar: newUser.avatar || null,
            },
            accessToken,
            refreshToken: refreshTokenValue,
            expiresAt: 15 * 60
        });
        setImmediate(async () => {
            const fcm = await registerFCMToken(newUser, fcmPayload);
            if (fcm) {
                console.log('FCM token đã được đăng ký thành công');
            } else {
                console.log('FCM token đã được đăng ký thất bại');
            }
        });
    } catch (err) {
        console.error('Google auth error:', err);
        if (err.code === 11000 && err.keyPattern && err.keyPattern.googleId) {
            return res.status(400).json({
                error: 'Tài khoản Google này đã được liên kết với một tài khoản khác trong hệ thống'
            });
        }
        res.status(401).json({ message: "Invalid Google token" });
    }
};


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

        let message = ""
        result.modifiedCount === 0
            ? message = 'Không tìm thấy phiên đăng nhập của thiết bị này hoặc thiết bị đã được đăng xuất trước đó'
            : message = 'Đã đăng xuất thiết bị thành công';

        res.json({
            success: true,
            message: message
        });

    } catch (error) {
        console.error('Lỗi khi đăng xuất thiết bị:', error);
        res.status(500).json({ error: 'Lỗi server khi đăng xuất' });
    }
};

export const linkGoogleAccount = async (req, res) => {
    try {
        const { idToken } = req.body;
        const userId = req.userId;

        if (!idToken) {
            return res.status(400).json({
                error: 'Token Google không được cung cấp'
            });
        }

        const client = new OAuth2Client(googleAppClientId);
        const ticket = await client.verifyIdToken({
            idToken,
            audience: googleAppClientId,
        });

        const payload = ticket.getPayload();
        if (!payload) {
            return res.status(400).json({
                error: 'Token Google không hợp lệ'
            });
        }

        const { sub: googleId } = payload;

        // Kiểm tra xem googleId này đã được liên kết với tài khoản khác chưa
        const existingUserWithGoogleId = await user.findOne({
            googleId,
            _id: { $ne: userId } // Không tính user hiện tại
        });

        if (existingUserWithGoogleId) {
            return res.status(400).json({
                error: 'Tài khoản Google này đã được liên kết với một tài khoản khác trong hệ thống. Vui lòng đăng nhập bằng tài khoản đó để sử dụng tài khoản Google này.'
            });
        }

        // Kiểm tra user hiện tại
        const currentUser = await user.findById(userId);
        if (!currentUser) {
            return res.status(404).json({ error: 'Không tìm thấy tài khoản' });
        }

        // Kiểm tra xem user hiện tại đã liên kết Google chưa
        if (currentUser.googleId) {
            return res.status(400).json({
                error: 'Tài khoản này đã được liên kết với một tài khoản Google. Nếu bạn muốn liên kết với một tài khoản Google khác, vui lòng hủy liên kết tài khoản Google hiện tại trước.'
            });
        }

        // Liên kết googleId với tài khoản hiện tại
        currentUser.googleId = googleId;
        await currentUser.save();

        res.json({
            success: true,
            message: 'Đã liên kết thành công tài khoản Google với tài khoản hiện tại'
        });

    } catch (error) {
        console.error('Lỗi khi liên kết tài khoản Google:', error);

        if (error.code === 11000 && error.keyPattern && error.keyPattern.googleId) {
            return res.status(400).json({
                error: 'Tài khoản Google này đã được liên kết với một tài khoản khác trong hệ thống'
            });
        }

        res.status(400).json({
            error: 'Không thể liên kết tài khoản Google. Vui lòng thử lại.'
        });
    }
};

export const unlinkGoogleAccount = async (req, res) => {
    try {
        const userId = req.userId;

        const userToUpdate = await user.findById(userId);
        if (!userToUpdate) {
            return res.status(404).json({ error: 'Không tìm thấy tài khoản' });
        }

        // Kiểm tra xem tài khoản có liên kết Google không
        if (!userToUpdate.googleId) {
            return res.status(400).json({ error: 'Tài khoản này chưa được liên kết với Google' });
        }

        // Kiểm tra xem tài khoản có mật khẩu hay không
        // Nếu không có mật khẩu (password rỗng hoặc không tồn tại) thì đây là tài khoản chỉ được tạo bằng Google
        const hasPassword = userToUpdate.password && userToUpdate.password.length > 0;

        if (!hasPassword) {
            return res.status(400).json({
                error: 'Không thể hủy liên kết tài khoản Google. Tài khoản này chỉ có thể đăng nhập bằng Google.'
            });
        }

        // Hủy liên kết Google bằng cách xóa googleId
        userToUpdate.googleId = undefined;
        await userToUpdate.save();

        res.json({ message: 'Đã hủy liên kết tài khoản Google thành công' });

    } catch (error) {
        console.error('Lỗi khi hủy liên kết tài khoản Google:', error);
        res.status(500).json({ error: 'Không thể hủy liên kết tài khoản Google' });
    }
};

// Xử lý khi xóa user
export const deleteUser = async (req, res) => {
    try {
        const userId = req.params.userId || req.userId;

        const userToDelete = await user.findById(userId);
        if (!userToDelete) {
            return res.status(404).json({ error: 'Không tìm thấy tài khoản' });
        }

        // Khi xóa user, tự động xóa liên kết Google để googleId có thể được sử dụng lại
        if (userToDelete.googleId) {
            userToDelete.googleId = undefined;
            await userToDelete.save();
        }

        // Sau đó thực hiện xóa user
        await userToDelete.deleteOne();

        res.json({ message: 'Đã xóa tài khoản thành công' });

    } catch (error) {
        console.error('Lỗi khi xóa tài khoản:', error);
        res.status(500).json({ error: 'Không thể xóa tài khoản' });
    }
};


export const getUserProfile = async (req, res) => {
    try {
        const user = await user.findById(req.userId)
            .select('-googleId -__v')
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
            username: user.username || null,
            email: user.email,
            avatar: user.avatar || null,
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
                    username: member.username || 'Người dùng chưa đặt tên',
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
