import { Router } from 'express';
import { createCategory, updateCategory, getCategories, getCategoryImages } from '../controllers/categoryController.js';

const categoryRouter = Router();

categoryRouter.get('/images', getCategoryImages);
categoryRouter.post('/', createCategory);
categoryRouter.get('/', getCategories);
categoryRouter.put('/:id', updateCategory);


export default categoryRouter;
