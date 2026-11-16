import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import Header from '../../components/layout/Header';
import { Category } from '../../types';
import api from '../../services/api';
import ImageUpload from '../../components/ui/ImageUpload';
import { apiErrorMessage } from '../../utils/errors';

const productSchema = z.object({
  nameRu: z.string().min(1, 'Обязательное поле'),
  nameKy: z.string().optional(),
  descriptionRu: z.string().optional(),
  descriptionKy: z.string().optional(),
  price: z.number({ error: 'Введите число' }).min(1, 'Минимум 1 сом'),
  categoryId: z.string().min(1, 'Выберите категорию'),
  isAvailable: z.boolean(),
  isPreorder: z.boolean(),
  leadTimeHours: z
    .number({ error: 'Введите число' })
    .int('Целое число')
    .min(0, 'Не меньше 0')
    .max(720, 'Не больше 720 часов'),
  prepaymentPercent: z
    .number({ error: 'Введите число' })
    .int('Целое число')
    .min(0, 'Не меньше 0')
    .max(100, 'Не больше 100'),
  allowInscription: z.boolean(),
  allowReferencePhoto: z.boolean(),
});

type ProductFormData = z.infer<typeof productSchema>;

const ProductForm: React.FC = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const isEdit = !!id && id !== 'new';
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(false);

  const { register, handleSubmit, reset, watch, formState: { errors } } = useForm<ProductFormData>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      nameRu: '',
      nameKy: '',
      descriptionRu: '',
      descriptionKy: '',
      price: 0,
      categoryId: '',
      isAvailable: true,
      isPreorder: false,
      leadTimeHours: 0,
      prepaymentPercent: 0,
      allowInscription: false,
      allowReferencePhoto: false,
    },
  });
  const isPreorder = watch('isPreorder');
  // Photos live outside the form schema: first one is the main photo
  const [images, setImages] = useState<string[]>([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [catRes, prodRes] = await Promise.all([
          api.get<Category[]>('/products/categories'),
          isEdit ? api.get(`/products/${id}`) : Promise.resolve(null),
        ]);
        setCategories(catRes.data);
        const product = prodRes?.data;
        if (product) {
          reset({
            nameRu: product.nameRu || product.name,
            nameKy: product.nameKy || '',
            descriptionRu: product.descriptionRu || '',
            descriptionKy: product.descriptionKy || '',
            price: Number(product.price),
            categoryId: product.categoryId,
            isAvailable: product.isAvailable,
            isPreorder: !!product.isPreorder,
            leadTimeHours: product.leadTimeHours ?? 0,
            prepaymentPercent: product.prepaymentPercent ?? 0,
            allowInscription: !!product.allowInscription,
            allowReferencePhoto: !!product.allowReferencePhoto,
          });
          setImages(Array.isArray(product.images) ? product.images : []);
        }
      } catch {
        alert('Не удалось загрузить данные товара');
      }
    };
    fetchData();
  }, [id, isEdit, reset]);

  const onSubmit = async (data: ProductFormData) => {
    setLoading(true);
    try {
      // Backend requires the base `name`; Russian is the primary language
      const payload = {
        ...data,
        name: data.nameRu,
        images,
        // Made-to-order settings only apply when the product is made to order
        ...(data.isPreorder
          ? {}
          : { leadTimeHours: 0, prepaymentPercent: 0, allowInscription: false, allowReferencePhoto: false }),
      };
      if (isEdit) {
        await api.patch(`/products/${id}`, payload);
      } else {
        await api.post('/products', payload);
      }
      navigate('/products');
    } catch (err: any) {
      alert(apiErrorMessage(err, 'Ошибка при сохранении'));
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

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <ImageUpload
              value={images[0] ?? null}
              onChange={(url) => setImages((prev) => (url ? [url, ...prev.slice(1)] : prev.slice(1)))}
              folder="products"
              label="Главное фото"
            />
            {images.length > 1 && (
              <p className="text-xs text-gray-500 mt-2">Ещё фото у товара: {images.length - 1}</p>
            )}
          </div>

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 space-y-4">
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="isPreorder"
                {...register('isPreorder')}
                className="w-4 h-4 text-primary border-gray-300 rounded focus:ring-primary"
              />
              <label htmlFor="isPreorder" className="text-sm font-medium text-gray-700">
                Только под заказ (торт на заказ)
              </label>
            </div>

            {isPreorder && (
              <>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Срок изготовления, часов
                    </label>
                    <input
                      type="number"
                      {...register('leadTimeHours', { valueAsNumber: true })}
                      className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    />
                    <p className="text-xs text-gray-500 mt-1">Клиент не сможет выбрать время раньше</p>
                    {errors.leadTimeHours && <p className="text-red-500 text-xs mt-1">{errors.leadTimeHours.message}</p>}
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Предоплата, %
                    </label>
                    <input
                      type="number"
                      {...register('prepaymentPercent', { valueAsNumber: true })}
                      className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    />
                    <p className="text-xs text-gray-500 mt-1">0 — без предоплаты</p>
                    {errors.prepaymentPercent && <p className="text-red-500 text-xs mt-1">{errors.prepaymentPercent.message}</p>}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="allowInscription"
                    {...register('allowInscription')}
                    className="w-4 h-4 text-primary border-gray-300 rounded focus:ring-primary"
                  />
                  <label htmlFor="allowInscription" className="text-sm text-gray-700">
                    Можно заказать надпись
                  </label>
                </div>
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="allowReferencePhoto"
                    {...register('allowReferencePhoto')}
                    className="w-4 h-4 text-primary border-gray-300 rounded focus:ring-primary"
                  />
                  <label htmlFor="allowReferencePhoto" className="text-sm text-gray-700">
                    Можно приложить фото-образец
                  </label>
                </div>
              </>
            )}
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
