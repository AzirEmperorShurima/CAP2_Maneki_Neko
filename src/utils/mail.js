import nodemailer from 'nodemailer';

export const transporter = nodemailer.createTransport({
    host: "smtp.gmail.com",
    port: 465,
    secure: true,
    auth: {
        user: process.env.EMAIL_ADMIN,
        pass: process.env.ADMIN_EMAIL_APP_PASSWORD,
    },
});

export async function sendEmail(to, subject, html) {
    return transporter.sendMail({
        from: `"My App" <${process.env.EMAIL_ADMIN}>`,
        to,
        subject,
        html,
    });
}
