import { Router } from 'express';
import { createCategory, updateCategory, getCategories } from '../controllers/categoryController.js';
import { categoryImageUploadMiddleware } from '../middlewares/cloudinary.js';

const categoryRouter = Router();

categoryRouter.post('/', categoryImageUploadMiddleware, createCategory);
categoryRouter.get('/', getCategories);
categoryRouter.put('/:id', categoryImageUploadMiddleware, updateCategory);

export default categoryRouter;
