import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create settings
  await prisma.settings.createMany({
    data: [
      {
        key: 'loyalty_cashback_percent',
        value: '5',
        description: 'Loyalty program cashback percentage',
      },
      {
        key: 'loyalty_max_points_use_percent',
        value: '100',
        description: 'Maximum percentage payable with points',
      },
      {
        key: 'delivery_fee',
        value: '100',
        description: 'Delivery fee (som)',
      },
      {
        key: 'free_delivery_min_amount',
        value: '1000',
        description: 'Minimum order amount for free delivery',
      },
      {
        key: 'support_phone',
        value: '+996701039009',
        description: 'Support phone number',
      },
      {
        key: 'support_email',
        value: 'support@shirin.kg',
        description: 'Support email',
      },
    ],
    skipDuplicates: true,
  });

  // Create admin user
  const admin = await prisma.user.upsert({
    where: { phone: '+996700000000' },
    update: {},
    create: {
      phone: '+996700000000',
      firstName: 'Admin',
      lastName: 'User',
      role: 'ADMIN',
      loyaltyPoints: 0,
    },
  });

  console.log('Admin user:', admin.phone);

  // Create categories
  const categories = await Promise.all([
    prisma.category.upsert({
      where: { id: 'cat-cakes' },
      update: {},
      create: {
        id: 'cat-cakes',
        name: 'Торты',
        nameRu: 'Торты',
        nameKy: 'Торттор',
        description: 'Торты на любой праздник',
        icon: 'cake',
        sortOrder: 1,
        isActive: true,
      },
    }),
    prisma.category.upsert({
      where: { id: 'cat-pastries' },
      update: {},
      create: {
        id: 'cat-pastries',
        name: 'Пирожные',
        nameRu: 'Пирожные',
        nameKy: 'Пирожныйлар',
        description: 'Нежные пирожные',
        icon: 'cupcake',
        sortOrder: 2,
        isActive: true,
      },
    }),
    prisma.category.upsert({
      where: { id: 'cat-cookies' },
      update: {},
      create: {
        id: 'cat-cookies',
        name: 'Печенье',
        nameRu: 'Печенье',
        nameKy: 'Печенье',
        description: 'Хрустящее печенье',
        icon: 'cookie',
        sortOrder: 3,
        isActive: true,
      },
    }),
    prisma.category.upsert({
      where: { id: 'cat-eclairs' },
      update: {},
      create: {
        id: 'cat-eclairs',
        name: 'Эклеры',
        nameRu: 'Эклеры',
        nameKy: 'Эклерлер',
        description: 'Французские эклеры',
        icon: 'eclair',
        sortOrder: 4,
        isActive: true,
      },
    }),
  ]);

  console.log('Categories created:', categories.length);

  // Create products
  const products = await Promise.all([
    // Cakes
    prisma.product.upsert({
      where: { id: 'prod-napoleon' },
      update: {},
      create: {
        id: 'prod-napoleon',
        name: 'Наполеон',
        nameRu: 'Наполеон',
        nameKy: 'Наполеон',
        description: 'Классический торт Наполеон с нежным кремом',
        descriptionRu: 'Классический торт Наполеон с нежным кремом',
        descriptionKy: 'Назик крем менен классикалык Наполеон торту',
        price: 1200,
        images: [],
        ingredients: 'Мука, масло, яйца, сливки, сахар',
        weight: 1000,
        calories: 350,
        categoryId: 'cat-cakes',
        isAvailable: true,
        isBestseller: true,
        sortOrder: 1,
      },
    }),
    prisma.product.upsert({
      where: { id: 'prod-medovik' },
      update: {},
      create: {
        id: 'prod-medovik',
        name: 'Медовик',
        nameRu: 'Медовик',
        nameKy: 'Бал торт',
        description: 'Медовый торт со сметанным кремом',
        descriptionRu: 'Медовый торт со сметанным кремом',
        descriptionKy: 'Каймак крем менен бал торту',
        price: 1100,
        images: [],
        ingredients: 'Мед, мука, сметана, масло, сахар',
        weight: 1000,
        calories: 320,
        categoryId: 'cat-cakes',
        isAvailable: true,
        isNew: true,
        sortOrder: 2,
      },
    }),
    prisma.product.upsert({
      where: { id: 'prod-prague' },
      update: {},
      create: {
        id: 'prod-prague',
        name: 'Прага',
        nameRu: 'Прага',
        nameKy: 'Прага',
        description: 'Шоколадный торт Прага',
        descriptionRu: 'Шоколадный торт Прага',
        descriptionKy: 'Прага шоколад торту',
        price: 1300,
        discountPrice: 1100,
        images: [],
        ingredients: 'Шоколад, мука, масло, яйца, сахар',
        weight: 1000,
        calories: 380,
        categoryId: 'cat-cakes',
        isAvailable: true,
        sortOrder: 3,
      },
    }),

    // Pastries
    prisma.product.upsert({
      where: { id: 'prod-tiramisu' },
      update: {},
      create: {
        id: 'prod-tiramisu',
        name: 'Тирамису',
        nameRu: 'Тирамису',
        nameKy: 'Тирамису',
        description: 'Итальянский десерт с маскарпоне и кофе',
        descriptionRu: 'Итальянский десерт с маскарпоне и кофе',
        descriptionKy: 'Маскарпоне жана кофе менен италиялык десерт',
        price: 250,
        images: [],
        ingredients: 'Маскарпоне, кофе, печенье савоярди, какао',
        weight: 150,
        calories: 280,
        categoryId: 'cat-pastries',
        isAvailable: true,
        isBestseller: true,
        sortOrder: 1,
      },
    }),
    prisma.product.upsert({
      where: { id: 'prod-cheesecake' },
      update: {},
      create: {
        id: 'prod-cheesecake',
        name: 'Чизкейк',
        nameRu: 'Чизкейк',
        nameKy: 'Чизкейк',
        description: 'Нью-Йоркский чизкейк',
        descriptionRu: 'Нью-Йоркский чизкейк',
        descriptionKy: 'Нью-Йорк чизкейк',
        price: 280,
        images: [],
        ingredients: 'Сливочный сыр, сахар, яйца, сливки',
        weight: 160,
        calories: 320,
        categoryId: 'cat-pastries',
        isAvailable: true,
        sortOrder: 2,
      },
    }),

    // Cookies
    prisma.product.upsert({
      where: { id: 'prod-macaron' },
      update: {},
      create: {
        id: 'prod-macaron',
        name: 'Макарон (набор 6 шт)',
        nameRu: 'Макарон (набор 6 шт)',
        nameKy: 'Макарон (6 даана)',
        description: 'Французские миндальные печенья с кремом',
        descriptionRu: 'Французские миндальные печенья с кремом',
        descriptionKy: 'Крем менен француз бадам печеньеси',
        price: 450,
        images: [],
        ingredients: 'Миндаль, сахар, яичный белок, крем',
        weight: 120,
        calories: 150,
        categoryId: 'cat-cookies',
        isAvailable: true,
        isNew: true,
        sortOrder: 1,
      },
    }),

    // Eclairs
    prisma.product.upsert({
      where: { id: 'prod-eclair-chocolate' },
      update: {},
      create: {
        id: 'prod-eclair-chocolate',
        name: 'Эклер шоколадный',
        nameRu: 'Эклер шоколадный',
        nameKy: 'Шоколад эклер',
        description: 'Эклер с шоколадным кремом и глазурью',
        descriptionRu: 'Эклер с шоколадным кремом и глазурью',
        descriptionKy: 'Шоколад крем жана глазурь менен эклер',
        price: 150,
        images: [],
        ingredients: 'Мука, масло, яйца, шоколад, сливки',
        weight: 80,
        calories: 220,
        categoryId: 'cat-eclairs',
        isAvailable: true,
        isBestseller: true,
        sortOrder: 1,
      },
    }),
    prisma.product.upsert({
      where: { id: 'prod-eclair-vanilla' },
      update: {},
      create: {
        id: 'prod-eclair-vanilla',
        name: 'Эклер ванильный',
        nameRu: 'Эклер ванильный',
        nameKy: 'Ванилдүү эклер',
        description: 'Эклер с ванильным кремом',
        descriptionRu: 'Эклер с ванильным кремом',
        descriptionKy: 'Ваниль крем менен эклер',
        price: 140,
        images: [],
        ingredients: 'Мука, масло, яйца, ваниль, сливки',
        weight: 80,
        calories: 200,
        categoryId: 'cat-eclairs',
        isAvailable: true,
        sortOrder: 2,
      },
    }),
  ]);

  console.log('Products created:', products.length);

  // Create stores
  const stores = await Promise.all([
    prisma.store.upsert({
      where: { id: 'store-main' },
      update: {},
      create: {
        id: 'store-main',
        name: 'Ширин - Центр',
        nameRu: 'Ширин - Центр',
        nameKy: 'Ширин - Борбор',
        address: 'ул. Киевская, 77',
        addressRu: 'ул. Киевская, 77',
        addressKy: 'Киев көчөсү, 77',
        latitude: 42.8746,
        longitude: 74.5698,
        phone: '+996701039009',
        workHours: '09:00 - 21:00',
        isActive: true,
      },
    }),
    prisma.store.upsert({
      where: { id: 'store-south' },
      update: {},
      create: {
        id: 'store-south',
        name: 'Ширин - Юг',
        nameRu: 'Ширин - Юг',
        nameKy: 'Ширин - Түштүк',
        address: 'ул. Ахунбаева, 120',
        addressRu: 'ул. Ахунбаева, 120',
        addressKy: 'Ахунбаев көчөсү, 120',
        latitude: 42.8456,
        longitude: 74.5912,
        phone: '+996702039009',
        workHours: '09:00 - 21:00',
        isActive: true,
      },
    }),
  ]);

  console.log('Stores created:', stores.length);

  // Create promotions
  const now = new Date();
  const oneMonthLater = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

  const promotions = await Promise.all([
    prisma.promotion.upsert({
      where: { id: 'promo-welcome' },
      update: {},
      create: {
        id: 'promo-welcome',
        title: 'Добро пожаловать!',
        titleRu: 'Добро пожаловать!',
        titleKy: 'Кош келиңиз!',
        description: 'Скидка 10% на первый заказ для новых клиентов',
        descriptionRu: 'Скидка 10% на первый заказ для новых клиентов',
        descriptionKy: 'Жаңы кардарлар үчүн биринчи заказга 10% арзандатуу',
        image: '',
        type: 'DISCOUNT',
        discountPercent: 10,
        startDate: now,
        endDate: oneMonthLater,
        isActive: true,
        sortOrder: 1,
      },
    }),
    prisma.promotion.upsert({
      where: { id: 'promo-cashback' },
      update: {},
      create: {
        id: 'promo-cashback',
        title: 'Двойной кешбэк',
        titleRu: 'Двойной кешбэк',
        titleKy: 'Кош кешбэк',
        description: 'Получите 10% кешбэк вместо 5% на заказы от 2000 сом',
        descriptionRu: 'Получите 10% кешбэк вместо 5% на заказы от 2000 сом',
        descriptionKy: '2000 сомдон ашкан заказдарга 5% ордуна 10% кешбэк алыңыз',
        image: '',
        type: 'CASHBACK',
        cashbackPercent: 10,
        minOrderAmount: 2000,
        startDate: now,
        endDate: oneMonthLater,
        isActive: true,
        sortOrder: 2,
      },
    }),
  ]);

  console.log('Promotions created:', promotions.length);

  // Create raffle
  const twoWeeksLater = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);

  const raffle = await prisma.raffle.upsert({
    where: { id: 'raffle-cake' },
    update: {},
    create: {
      id: 'raffle-cake',
      title: 'Розыгрыш торта!',
      titleRu: 'Розыгрыш торта!',
      titleKy: 'Торт утуштуруу!',
      description: 'Участвуйте в розыгрыше и выиграйте торт на выбор!',
      descriptionRu: 'Участвуйте в розыгрыше и выиграйте торт на выбор!',
      descriptionKy: 'Утуштурууга катышып, өзүңүз тандаган тортту утуп алыңыз!',
      image: '',
      prize: 'Торт на выбор до 2000 сом',
      minPurchaseAmount: 500,
      startDate: now,
      endDate: twoWeeksLater,
      drawDate: twoWeeksLater,
      isActive: true,
    },
  });

  console.log('Raffle created:', raffle.title);

  console.log('Database seeded successfully!');
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
