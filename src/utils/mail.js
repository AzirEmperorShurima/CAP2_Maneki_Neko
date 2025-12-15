import nodemailer from 'nodemailer';
import { Resend } from 'resend';

const isProduction = process.env.NODE_ENV === 'production';

// ============= NODEMAILER (Local) =============
let transporter = null;

const createNodemailerTransporter = () => {
    const config = {
        host: "smtp.gmail.com",
        port: 465,
        secure: true,
        auth: {
            user: process.env.EMAIL_ADMIN,
            pass: process.env.ADMIN_EMAIL_APP_PASSWORD,
        },
        connectionTimeout: 10000,
        greetingTimeout: 10000,
        socketTimeout: 10000,
    };

    const transport = nodemailer.createTransport(config);

    // Verify connection cho local
    transport.verify(function (error, success) {
        if (error) {
            console.error('❌ Nodemailer config error:', {
                message: error.message,
                code: error.code,
                command: error.command
            });
        } else {
            console.log('✅ Nodemailer ready (Local)');
        }
    });

    return transport;
};

// ============= RESEND (Production) =============
let resendClient = null;

const createResendClient = () => {
    if (!process.env.RESEND_API_KEY) {
        console.error('❌ RESEND_API_KEY not configured');
        return null;
    }

    console.log('✅ Resend client ready (Production)');
    return new Resend(process.env.RESEND_API_KEY);
};

// ============= INITIALIZE =============
if (isProduction) {
    resendClient = createResendClient();
} else {
    transporter = createNodemailerTransporter();
}

// ============= SEND EMAIL FUNCTION =============
export async function sendEmail(to, subject, html) {
    // Validate inputs
    if (!to || !subject || !html) {
        throw new Error('Missing required email parameters: to, subject, html');
    }

    if (!process.env.EMAIL_ADMIN) {
        throw new Error('EMAIL_ADMIN not configured');
    }

    try {
        console.log(`📧 Sending email via ${isProduction ? 'Resend' : 'Nodemailer'} to ${to}...`);

        let result;

        if (isProduction) {
            // ========== PRODUCTION: Dùng Resend ==========
            if (!resendClient) {
                throw new Error('Resend client not initialized');
            }
            const fromEmail = process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';
            result = await resendClient.emails.send({
                from: `Maneki Neko <${fromEmail}>`,
                to: [to],
                subject,
                html,
            });

            console.log('✅ Email sent via Resend:', result);

        } else {
            // ========== LOCAL: Dùng Nodemailer ==========
            if (!transporter) {
                throw new Error('Nodemailer transporter not initialized');
            }

            if (!process.env.ADMIN_EMAIL_APP_PASSWORD) {
                throw new Error('ADMIN_EMAIL_APP_PASSWORD not configured');
            }

            result = await transporter.sendMail({
                from: `"Maneki Neko" <${process.env.EMAIL_ADMIN}>`,
                to,
                subject,
                html,
            });

            console.log('✅ Email sent via Nodemailer:', result);
        }

        return result;

    } catch (error) {
        console.error('❌ Send email failed:', {
            service: isProduction ? 'Resend' : 'Nodemailer',
            error: error.message,
            code: error.code,
            to,
            subject
        });
    }
}

// ============= BULK EMAIL (Optional) =============
export async function sendBulkEmail(recipients, subject, html) {
    if (!Array.isArray(recipients) || recipients.length === 0) {
        throw new Error('Recipients must be a non-empty array');
    }

    try {
        console.log(`📧 Sending bulk email to ${recipients.length} recipients...`);

        if (isProduction) {
            // Resend hỗ trợ multiple recipients
            if (!resendClient) {
                throw new Error('Resend client not initialized');
            }

            const result = await resendClient.emails.send({
                from: `Maneki Neko <${process.env.EMAIL_ADMIN}>`,
                to: recipients,
                subject,
                html,
            });

            console.log('✅ Bulk email sent via Resend');
            return result;

        } else {
            // Nodemailer: gửi từng email một
            const promises = recipients.map(recipient =>
                sendEmail(recipient, subject, html)
            );

            const results = await Promise.allSettled(promises);
            const successful = results.filter(r => r.status === 'fulfilled').length;
            const failed = results.filter(r => r.status === 'rejected').length;

            console.log(`✅ Bulk email completed: ${successful} sent, ${failed} failed`);
            return { successful, failed, results };
        }

    } catch (error) {
        console.error('❌ Bulk email failed:', error);
        throw error;
    }
}