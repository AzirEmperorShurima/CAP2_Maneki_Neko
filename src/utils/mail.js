import nodemailer from 'nodemailer';

const createTransporter = () => {
    const config = {
        host: "smtp.gmail.com",
        port: 10000,
        secure: process.env.NODE_ENV !== 'production',
        auth: {
            user: process.env.EMAIL_ADMIN,
            pass: process.env.ADMIN_EMAIL_APP_PASSWORD,
        },
        connectionTimeout: 10000,
        greetingTimeout: 10000,
        socketTimeout: 10000,
    };

    if (process.env.NODE_ENV === 'production') {
        config.tls = {
            rejectUnauthorized: false
        };
    }

    return nodemailer.createTransport(config);
};

export const transporter = createTransporter();

transporter.verify(function (error, success) {
    if (error) {
        console.log('❌ Email config error:', {
            message: error.message,
            code: error.code,
            command: error.command
        });
    } else {
        console.log('✅ Email server ready');
    }
});

export async function sendEmail(to, subject, html) {
    // Validate inputs
    if (!to || !subject || !html) {
        throw new Error('Missing required email parameters');
    }

    if (!process.env.EMAIL_ADMIN || !process.env.ADMIN_EMAIL_APP_PASSWORD) {
        throw new Error('Email credentials not configured');
    }

    try {
        console.log(`📧 Sending email to ${to}...`);

        const info = await transporter.sendMail({
            from: `"Maneki Neko" <${process.env.EMAIL_ADMIN}>`,
            to,
            subject,
            html,
        });

        console.log('✅ Email sent:', info.messageId);
        return info;

    } catch (error) {
        console.log('❌ Send email failed:', {
            error: error.message,
            code: error.code,
            command: error.command,
            to
        });
    }
}