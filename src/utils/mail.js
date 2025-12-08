import nodemailer from 'nodemailer';
export const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_ADMIN,
        pass: process.env.ADMIN_EMAIL_APP_PASSWORD,
    },
});

export async function sendEmail(to, subject, html) {
    const from = to || process.env.EMAIL_ADMIN;
    return transporter.sendMail({ from, to, subject, html });
}
