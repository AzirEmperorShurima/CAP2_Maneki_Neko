import Joi from "joi";

export const createCategorySchema = Joi.object({
  name: Joi.string().min(1).max(50).required(),
  type: Joi.string().valid('income', 'expense').required(),
  scope: Joi.string().valid('system', 'personal', 'family').optional().default('personal'),
  image: Joi.string().uri().optional().allow('')
});

export const updateCategorySchema = Joi.object({
  name: Joi.string().min(1).max(50).optional(),
  type: Joi.string().valid('income', 'expense').optional(),
  image: Joi.string().uri().optional().allow('')
});

export const getCategoriesQuerySchema = Joi.object({
  type: Joi.string().valid('income', 'expense').optional(),
});

export function validateCreateCategory(payload) {
  return createCategorySchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export function validateUpdateCategory(payload) {
  return updateCategorySchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export function validateGetCategoriesQuery(query) {
  return getCategoriesQuerySchema.validate(query, { abortEarly: false, stripUnknown: true });
}
