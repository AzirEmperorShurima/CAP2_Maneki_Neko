import Joi from "joi";

const passwordComplexity = Joi.string()
  .min(8)
  .pattern(new RegExp("^(?=.*[A-Z])(?=.*\\d)(?=.*[\\W_]).{8,}$"))
  .messages({
    "string.min": "Mật khẩu phải dài ít nhất 8 ký tự",
    "string.pattern.base": "Mật khẩu phải có chữ hoa, số và ký tự đặc biệt",
  });

export const registerSchema = Joi.object({
  email: Joi.string()
    .email({ tlds: { allow: false } })
    .required()
    .messages({
      "string.email": "Email không hợp lệ",
      "any.required": "Email là bắt buộc"
    }),
  password: passwordComplexity.required(),
  username: Joi.string()
    .min(2)
    .max(50)
    .optional()
    .messages({
      "string.min": "Tên hiển thị phải có ít nhất 2 ký tự",
      "string.max": "Tên hiển thị không được vượt quá 50 ký tự"
    }),
});

export const loginSchema = Joi.object({
  email: Joi.string()
    .email({ tlds: { allow: false } })
    .required()
    .messages({
      "string.email": "Email không hợp lệ",
      "any.required": "Email là bắt buộc"
    }),
  password: Joi.string()
    .required()
    .messages({
      "any.required": "Mật khẩu là bắt buộc"
    }),
  deviceId: Joi.string().optional(),
  fcmToken: Joi.string().optional(),
  platform: Joi.string().valid('android', 'ios').optional(),
});

export const verifyGoogleSchema = Joi.object({
  idToken: Joi.string().required().messages({
    "any.required": "idToken là bắt buộc"
  }),
  deviceId: Joi.string().optional(),
  fcmToken: Joi.string().optional(),
  platform: Joi.string().valid('android', 'ios').optional(),
});

export function validateRegister(payload) {
  return registerSchema.validate(payload, {
    abortEarly: false,
    stripUnknown: true
  });
}

export function validateLogin(payload) {
  return loginSchema.validate(payload, {
    abortEarly: false,
    stripUnknown: true
  });
}

export function validateVerifyGoogle(payload) {
  return verifyGoogleSchema.validate(payload, {
    abortEarly: false,
    stripUnknown: true
  });
}