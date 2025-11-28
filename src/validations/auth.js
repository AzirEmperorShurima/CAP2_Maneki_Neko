import Joi from "joi";

const passwordComplexity = Joi.string()
  .min(8)
  .pattern(new RegExp("^(?=.*[A-Z])(?=.*\\d)(?=.*[\\W_]).{8,}$"))
  .messages({
    "string.min": "Mật khẩu phải dài ít nhất 8 ký tự",
    "string.pattern.base": "Mật khẩu phải có chữ hoa, số và ký tự đặc biệt",
  });

export const registerSchema = Joi.object({
  accountName: Joi.string()
    .alphanum()
    .min(3)
    .max(30)
    .required()
    .messages({
      "string.alphanum": "Tên đăng nhập chỉ được chứa chữ và số",
      "string.min": "Tên đăng nhập phải có ít nhất 3 ký tự",
      "string.max": "Tên đăng nhập không được vượt quá 30 ký tự",
      "any.required": "Tên đăng nhập là bắt buộc"
    }),
  password: passwordComplexity.required(),
  email: Joi.string()
    .email({ tlds: { allow: false } })
    .required()
    .messages({
      "string.email": "Email không đúng định dạng",
      "any.required": "Email là bắt buộc"
    })
});

export const loginSchema = Joi.object({
  accountName: Joi.string()
    .alphanum()
    .min(3)
    .max(30)
    .required()
    .messages({
      "string.alphanum": "Tên đăng nhập chỉ được chứa chữ và số",
      "string.min": "Tên đăng nhập phải có ít nhất 3 ký tự",
      "string.max": "Tên đăng nhập không được vượt quá 30 ký tự",
      "any.required": "Tên đăng nhập là bắt buộc"
    }),
  password: Joi.string()
    .required()
    .messages({
      "any.required": "Mật khẩu là bắt buộc"
    })
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