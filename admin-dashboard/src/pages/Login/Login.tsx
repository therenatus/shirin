import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AccessDeniedError, useAuthStore } from '../../store/authStore';

const Login: React.FC = () => {
  const [phone, setPhone] = useState('+996');
  const [code, setCode] = useState('');
  const [step, setStep] = useState<'phone' | 'code'>('phone');
  const [error, setError] = useState('');
  const { login, sendCode, isLoading } = useAuthStore();
  const navigate = useNavigate();

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!/^\+996\d{9}$/.test(phone)) {
      setError('Введите номер в формате +996XXXXXXXXX');
      return;
    }
    try {
      await sendCode(phone);
      setCode('');
      setStep('code');
    } catch (err: any) {
      setError(
        err?.response?.status === 429
          ? 'Код уже отправлен, подождите минуту'
          : 'Не удалось отправить код'
      );
    }
  };

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    try {
      await login(phone, code);
      navigate('/');
    } catch (err: any) {
      if (err instanceof AccessDeniedError) {
        setError(err.message);
      } else if (err?.response?.status === 429) {
        setError('Слишком много попыток, запросите новый код');
        setStep('phone');
      } else {
        setError('Неверный или просроченный код');
      }
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-2xl shadow-lg p-8">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-primary mb-2">Ширин</h1>
            <p className="text-gray-500 text-sm">Панель управления</p>
          </div>

          {step === 'phone' ? (
            <form onSubmit={handleSendCode} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Номер телефона
                </label>
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+996..."
                  className="w-full px-4 py-3 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                />
              </div>
              {error && <p className="text-red-500 text-sm">{error}</p>}
              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-3 bg-primary text-white rounded-lg font-medium hover:bg-primary-dark disabled:opacity-50 transition-colors"
              >
                {isLoading ? 'Отправка...' : 'Получить код'}
              </button>
            </form>
          ) : (
            <form onSubmit={handleVerifyCode} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Код подтверждения
                </label>
                <input
                  type="text"
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  placeholder="Введите код"
                  maxLength={4}
                  className="w-full px-4 py-3 border border-gray-200 rounded-lg text-sm text-center tracking-widest focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                />
              </div>
              {error && <p className="text-red-500 text-sm">{error}</p>}
              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-3 bg-primary text-white rounded-lg font-medium hover:bg-primary-dark disabled:opacity-50 transition-colors"
              >
                {isLoading ? 'Проверка...' : 'Войти'}
              </button>
              <button
                type="button"
                onClick={() => setStep('phone')}
                className="w-full py-2 text-gray-500 text-sm hover:text-gray-700"
              >
                Изменить номер
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};

export default Login;
