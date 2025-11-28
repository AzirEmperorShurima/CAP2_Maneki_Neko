import nodemailer from 'nodemailer';
export const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

export async function sendEmail(to, subject, html) {
    const from = process.env.EMAIL_FROM || process.env.EMAIL_USER;
    return transporter.sendMail({ from, to, subject, html });
}
