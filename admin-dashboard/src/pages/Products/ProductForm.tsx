import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import Header from '../../components/layout/Header';
import { Category } from '../../types';
import { getMockCategories, getMockProducts, isTestMode } from '../../services/mockData';
import api from '../../services/api';

const productSchema = z.object({
  nameRu: z.string().min(1, 'Обязательное поле'),
  nameKy: z.string().optional(),
  descriptionRu: z.string().optional(),
  descriptionKy: z.string().optional(),
  price: z.number({ error: 'Введите число' }).min(1, 'Минимум 1 сом'),
  categoryId: z.string().min(1, 'Выберите категорию'),
  isAvailable: z.boolean(),
});

type ProductFormData = z.infer<typeof productSchema>;

const ProductForm: React.FC = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const isEdit = !!id && id !== 'new';
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(false);

  const { register, handleSubmit, reset, formState: { errors } } = useForm<ProductFormData>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      nameRu: '',
      nameKy: '',
      descriptionRu: '',
      descriptionKy: '',
      price: 0,
      categoryId: '',
      isAvailable: true,
    },
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        if (isTestMode()) {
          setCategories(getMockCategories());
          if (isEdit) {
            const product = getMockProducts().find((p) => p.id === id);
            if (product) {
              reset({
                nameRu: product.nameRu,
                nameKy: product.nameKy || '',
                descriptionRu: product.descriptionRu || '',
                descriptionKy: product.descriptionKy || '',
                price: product.price,
                categoryId: product.categoryId,
                isAvailable: product.isAvailable,
              });
            }
          }
        } else {
          const [catRes, prodRes] = await Promise.all([
            api.get('/products/categories'),
            isEdit ? api.get(`/products/${id}`) : Promise.resolve(null),
          ]);
          setCategories(catRes.data);
          if (prodRes?.data) {
            reset(prodRes.data);
          }
        }
      } catch {
        setCategories(getMockCategories());
      }
    };
    fetchData();
  }, [id, isEdit, reset]);

  const onSubmit = async (data: ProductFormData) => {
    setLoading(true);
    try {
      if (!isTestMode()) {
        if (isEdit) {
          await api.put(`/products/${id}`, data);
        } else {
          await api.post('/products', data);
        }
      }
      navigate('/products');
    } catch {
      alert('Ошибка при сохранении');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <Header title={isEdit ? 'Редактировать товар' : 'Новый товар'} />
      <div className="p-8 max-w-2xl">
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Название (RU) *
              </label>
              <input
                {...register('nameRu')}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                placeholder="Торт Наполеон"
              />
              {errors.nameRu && <p className="text-red-500 text-xs mt-1">{errors.nameRu.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Название (KY)
              </label>
              <input
                {...register('nameKy')}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                placeholder="Наполеон торту"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Описание (RU)
              </label>
              <textarea
                {...register('descriptionRu')}
                rows={3}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary resize-none"
                placeholder="Описание товара..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Описание (KY)
              </label>
              <textarea
                {...register('descriptionKy')}
                rows={3}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary resize-none"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Цена (сом) *
                </label>
                <input
                  type="number"
                  {...register('price', { valueAsNumber: true })}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                />
                {errors.price && <p className="text-red-500 text-xs mt-1">{errors.price.message}</p>}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Категория *
                </label>
                <select
                  {...register('categoryId')}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                >
                  <option value="">Выберите...</option>
                  {categories.map((cat) => (
                    <option key={cat.id} value={cat.id}>{cat.nameRu}</option>
                  ))}
                </select>
                {errors.categoryId && <p className="text-red-500 text-xs mt-1">{errors.categoryId.message}</p>}
              </div>
            </div>

            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="isAvailable"
                {...register('isAvailable')}
                className="w-4 h-4 text-primary border-gray-300 rounded focus:ring-primary"
              />
              <label htmlFor="isAvailable" className="text-sm text-gray-700">
                В наличии
              </label>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              type="submit"
              disabled={loading}
              className="px-6 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-dark disabled:opacity-50 transition-colors"
            >
              {loading ? 'Сохранение...' : isEdit ? 'Сохранить' : 'Создать'}
            </button>
            <button
              type="button"
              onClick={() => navigate('/products')}
              className="px-6 py-2 bg-gray-100 text-gray-700 rounded-lg text-sm font-medium hover:bg-gray-200 transition-colors"
            >
              Отмена
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ProductForm;
