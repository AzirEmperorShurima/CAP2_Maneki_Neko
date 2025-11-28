import { sendEmail } from '../../utils/mail.js';

function buildFamilyInviteHtml({ adminName, familyName, webJoinLink, deepLink, userExists }) {
    return `
    <div style="background: linear-gradient(135deg, #7c3aed, #ec4899); padding: 24px; font-family: Arial, sans-serif;">
      <div style="max-width: 640px; margin: 0 auto;">
        <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 24px rgba(124, 58, 237, 0.25);">
          <tr>
            <td style="padding: 0;">
              <div style="background: linear-gradient(135deg, #8b5cf6, #f472b6); color: #ffffff; text-align: center; padding: 28px 16px;">
                <div style="font-size: 14px; letter-spacing: 1px; opacity: 0.9;">MANEKI NEKO</div>
                <h2 style="margin: 8px 0 0; font-size: 24px; line-height: 1.4;">Lời mời tham gia gia đình</h2>
              </div>
            </td>
          </tr>
          <tr>
            <td style="padding: 24px 24px 8px; color: #374151; font-size: 15px;">
              <p style="margin: 0 0 10px;">Xin chào,</p>
              <p style="margin: 0 0 12px;">
                <strong>${adminName}</strong> đã mời bạn tham gia gia đình <strong>"${familyName}"</strong> trên ứng dụng <strong>Maneki Neko</strong>.
              </p>
              <p style="margin: 0 0 20px; color: #6b7280;">Kết nối để chia sẻ chi tiêu, thiết lập ngân sách và quản lý tài chính thông minh cùng gia đình.</p>
            </td>
          </tr>
          <tr>
            <td style="padding: 0 24px 24px; text-align: center;">
              <a href="${webJoinLink}"
                 style="display: inline-block; text-decoration: none; background: linear-gradient(135deg, #7c3aed, #ec4899); color: #ffffff; padding: 14px 28px; border-radius: 9999px; font-weight: bold; font-size: 16px; box-shadow: 0 8px 16px rgba(236, 72, 153, 0.35);">
                ${userExists ? 'Tham gia ngay' : 'Đăng nhập & tham gia'}
              </a>
              <div style="margin-top: 12px; font-size: 13px; color: #9ca3af;">Nếu nút không hoạt động, hãy mở liên kết: <br/>
                <a href="${webJoinLink}" style="color: #7c3aed; text-decoration: underline;">${webJoinLink}</a>
              </div>
            </td>
          </tr>
          <tr>
            <td style="padding: 0 24px 24px;">
              <div style="border-top: 1px solid #f1f5f9; padding-top: 16px; text-align: center;">
                <span style="display: inline-block; color: #6b7280; font-size: 12px;">Lời mời hết hạn sau 7 ngày.</span>
              </div>
            </td>
          </tr>
        </table>
      </div>
    </div>
  `;
}

export async function sendFamilyInviteEmail({ to, adminName, familyName, webJoinLink, deepLink, userExists }) {
    const subject = `Mời tham gia gia đình "${familyName}"`;
    const html = buildFamilyInviteHtml({ adminName, familyName, webJoinLink, deepLink, userExists });
    return sendEmail(to, subject, html);
}
