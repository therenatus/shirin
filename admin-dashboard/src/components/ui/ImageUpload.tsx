import React, { useRef, useState } from 'react';
import { ImagePlus, X } from 'lucide-react';
import api from '../../services/api';
import { apiErrorMessage } from '../../utils/errors';

interface ImageUploadProps {
  value: string | null;
  onChange: (url: string | null) => void;
  /** Storage folder: products, categories, promotions, stores. */
  folder: 'products' | 'categories' | 'promotions' | 'stores';
  label?: string;
  /** Tailwind aspect class for the preview, e.g. aspect-square, aspect-[2/1]. */
  aspect?: string;
}

const MAX_BYTES = 5 * 1024 * 1024;

/** Picks an image, uploads it to the storage and returns its public URL. */
const ImageUpload: React.FC<ImageUploadProps> = ({
  value,
  onChange,
  folder,
  label = 'Фото',
  aspect = 'aspect-square',
}) => {
  const input = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const upload = async (file: File) => {
    setError('');
    if (!/^image\/(jpeg|png|webp)$/.test(file.type)) {
      setError('Только JPEG, PNG или WebP');
      return;
    }
    if (file.size > MAX_BYTES) {
      setError('Файл больше 5 МБ');
      return;
    }
    setBusy(true);
    try {
      const form = new FormData();
      form.append('file', file);
      const { data } = await api.post<{ url: string }>('/storage/upload', form, {
        params: { folder },
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      onChange(data.url);
    } catch (err: any) {
      setError(apiErrorMessage(err, 'Не удалось загрузить фото'));
    } finally {
      setBusy(false);
      if (input.current) input.current.value = '';
    }
  };

  return (
    <div>
      <span className="block text-sm font-medium text-gray-700 mb-1">{label}</span>
      <div className={`relative w-48 ${aspect} rounded-lg border-2 border-dashed border-gray-200 overflow-hidden bg-gray-50`}>
        {value ? (
          <>
            <img src={value} alt="" className="w-full h-full object-cover" />
            <button
              type="button"
              onClick={() => onChange(null)}
              className="absolute top-1 right-1 p-1 bg-white/90 rounded-full text-gray-600 hover:text-red-600"
              aria-label="Убрать фото"
            >
              <X size={16} />
            </button>
          </>
        ) : (
          <button
            type="button"
            onClick={() => input.current?.click()}
            disabled={busy}
            className="w-full h-full flex flex-col items-center justify-center gap-1 text-gray-400 hover:text-primary"
          >
            {busy ? (
              <div className="animate-spin w-6 h-6 border-2 border-primary border-t-transparent rounded-full" />
            ) : (
              <>
                <ImagePlus size={28} />
                <span className="text-xs">Загрузить</span>
              </>
            )}
          </button>
        )}
      </div>
      {value && (
        <button type="button" onClick={() => input.current?.click()} className="mt-2 text-xs text-primary">
          Заменить
        </button>
      )}
      <input
        ref={input}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={(e) => e.target.files?.[0] && upload(e.target.files[0])}
      />
      {error && <p className="text-xs text-red-600 mt-1">{error}</p>}
    </div>
  );
};

export default ImageUpload;
