import Joi from "joi";

const objectId = Joi.string().hex().length(24);

export const getBudgetsQuerySchema = Joi.object({
  isActive: Joi.string().valid('true', 'false').optional(),
  isShared: Joi.string().valid('true', 'false').optional(),
  familyId: objectId.optional(),
});

export const validateCreateBudget = (data) => {
  const schema = Joi.object({
    name: Joi.string().optional().allow(''),
    type: Joi.string().valid('daily', 'weekly', 'monthly').required(),
    amount: Joi.number().min(0).required(),
    categoryId: objectId.optional().allow(null),
    familyId: objectId.optional(),
    isShared: Joi.boolean().optional(),
    parentBudgetId: Joi.string().optional().allow(null),
    periodStart: Joi.date(),
    periodEnd: Joi.date(),
    updateIfExists: Joi.boolean().optional().default(false)
  });

  return schema.validate(data, { abortEarly: false });
};
export const validateUpdateBudget = (data) => {
  const schema = Joi.object({
    amount: Joi.number().min(0).optional(),
    categoryId: Joi.string().optional().allow(null),
    isActive: Joi.boolean().optional(),
    isShared: Joi.boolean().optional(),
    familyId: objectId.optional(),
  });

  return schema.validate(data, { abortEarly: false });
};

export const validateGetBudgetsQuery = (query) => {
  return getBudgetsQuerySchema.validate(query, { abortEarly: false });
};

