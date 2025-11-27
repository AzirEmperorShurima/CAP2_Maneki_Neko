import jwt from "jsonwebtoken";
import user from "../models/user.js";
import { OAuth2Client } from "google-auth-library";
import { googleAppClientId } from "../config/googleAuth.js";

export const loginBase = async (req , res)=>{
    try {
        const { email, password } = req.body;
        const _user = await user.findOne({ email });
        if (!_user) {
            return res.status(404).json({ error: 'Email không tồn tại' });
        }
        const isPasswordValid = await _user.comparePassword(password);
        if (!isPasswordValid) {
            return res.status(401).json({ error: 'Mật khẩu không đúng' });
        }
        const token = jwt.sign(
            { id: _user._id },
            process.env.JWT_SECRET,
            { expiresIn: "7d" }
        );
        res.json({
            user: {
                id: _user._id,
                username: _user.username || null,
                email: _user.email,
                avatar: _user.avatar || null,
            }, token
        });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ message: "Internal server error" });
    }
}
export const verifyGoogleId = async (req, res) => {
    try {
        const { idToken } = req.body;
        const client = new OAuth2Client(googleAppClientId);
        const ticket = await client.verifyIdToken({
            idToken,
            audience: googleAppClientId,
        });

        const payload = ticket.getPayload();
        const { sub: googleId, email, name, picture: avatar } = payload;

        let _user = await user.findOne({ googleId });
        if (!_user) {
            _user = await user.create({ googleId, name, email, avatar });
        }

        const token = jwt.sign(
            { id: _user._id },
            process.env.JWT_SECRET,
            { expiresIn: "7d" }
        );

        res.json({
            user: {
                id: _user._id,
                username: _user.username,
                email: _user.email,
                avatar: _user.avatar,
            }, token
        });
    } catch (err) {
        console.error('Google auth error:', err);
        res.status(401).json({ message: "Invalid Google token" });
    }
}


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