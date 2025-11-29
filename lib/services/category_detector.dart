import '../models/expense.dart';

/// Сервис для автоматического определения категории расхода
/// на основе названия магазина/продавца
class CategoryDetector {
  // Ключевые слова для каждой категории
  static const Map<ExpenseCategory, List<String>> _categoryKeywords = {
    ExpenseCategory.food: [
      // Казахстанские магазины и рестораны
      'magnum', 'магнум', 'small', 'смол',
      'arbuz', 'арбуз', 'arbuz.kz',
      'metro', 'метро', 'galmart', 'галмарт',
      'anvar', 'анвар', 'ramstore', 'рамстор',
      'interfood', 'интерфуд', 'skif', 'скиф',
      'arai', 'арай', 'gros', 'грос',
      'green', 'грин', 'marwin', 'марвин',
      
      // Доставка еды КЗ
      'glovo', 'глово', 'wolt', 'волт',
      'chocofood', 'чокофуд', 'express24',
      'яндекс еда', 'yandex food', 'yandex eats',
      
      // Рестораны и кафе
      'макдональдс', 'mcdonalds', 'mcdonald', 'kfc', 'кфс',
      'burger king', 'бургер кинг', 'subway', 'сабвей',
      'starbucks', 'старбакс', 'coffee', 'кофе', 'кофейня',
      'costa', 'коста', 'coffeedelia', 'кофеделия',
      'пицца', 'pizza', 'hut', 'domino', 'домино',
      'dodo', 'додо', 'papa john', 'папа джонс',
      'суши', 'sushi', 'роллы', 'wok', 'вок',
      'ресторан', 'restaurant', 'кафе', 'cafe', 'столовая',
      'бар', 'bar', 'паб', 'pub', 'гриль', 'grill',
      'шаурма', 'шашлык', 'фастфуд', 'fast food',
      'hardees', 'хардис', 'paul', 'пауль',
      'del papa', 'дель папа', 'la prima', 'ла прима',
      
      // Продуктовые магазины
      'пятёрочка', 'пятерочка', 'pyaterochka',
      'магнит', 'magnit', 'перекрёсток', 'перекресток',
      'ашан', 'auchan', 'лента', 'lenta',
      'продукты', 'grocery', 'супермаркет', 'supermarket',
      'мясо', 'meat', 'рыба', 'fish', 'овощи', 'фрукты',
      'пекарня', 'bakery', 'хлеб', 'bread',
      'молоко', 'milk', 'dairy', 'food',
      'еда', 'delivery', 'доставка',
    ],
    
    ExpenseCategory.transport: [
      // Казахстанские такси
      'yandex go', 'яндекс го', 'яндекс такси', 'yandex taxi',
      'indriver', 'индрайвер', 'in driver',
      'uber', 'убер', 'bolt', 'болт',
      'такси', 'taxi', 'cab',
      'onay', 'онай', // Транспортная карта Алматы
      
      // Общественный транспорт
      'метро', 'metro', 'subway', 'автобус', 'bus',
      'троллейбус', 'трамвай', 'электричка',
      'поезд', 'train', 'ржд', 'кзт', 'ktj',
      'казахстан темир жолы',
      
      // Авиа
      'air astana', 'эйр астана', 'fly arystan', 'флай арыстан',
      'scat', 'скат', 'qazaq air', 'казак эйр',
      
      // Каршеринг
      'anytime', 'энитайм', 'jetcar', 'джеткар',
      'delimobil', 'делимобиль', 'carsharing', 'каршеринг',
      
      // АЗС
      'азс', 'gas', 'бензин', 'petrol', 'fuel', 'топливо',
      'qazaq oil', 'казак ойл', 'kaz munai gas', 'казмунайгаз',
      'helios', 'гелиос', 'shell', 'шелл',
      'royal petrol', 'роял петрол', 'sinooil', 'синооил',
      'gazpromneft', 'газпромнефть',
      
      // Парковка
      'parking', 'парковка', 'стоянка',
      
      // Самокаты
      'whoosh', 'вуш', 'jet', 'kick', 'самокат', 'scooter',
    ],
    
    ExpenseCategory.shopping: [
      // Казахстанские маркетплейсы
      'kaspi', 'каспи', 'kaspi магазин', 'kaspi shop',
      'halyk market', 'халык маркет',
      'satu', 'сату', 'satu.kz',
      'olx', 'колеса', 'krisha',
      
      // Международные
      'wildberries', 'вайлдберриз', 'wb',
      'ozon', 'озон', 'amazon', 'амазон',
      'aliexpress', 'алиэкспресс', 'али',
      'яндекс маркет', 'yandex market',
      
      // Электроника КЗ
      'sulpak', 'сулпак', 'technodom', 'технодом',
      'alser', 'алсер', 'mechta', 'мечта',
      'evrika', 'эврика', 'white wind', 'вайт винд',
      'ispace', 'айспейс',
      
      // Одежда
      'zara', 'зара', 'h&m', 'uniqlo', 'юникло',
      'bershka', 'бершка', 'mango', 'манго',
      'lcwaikiki', 'вайкики', 'defacto', 'дефакто',
      'colin\'s', 'коллинз', 'adidas', 'адидас',
      'nike', 'найк', 'puma', 'пума',
      'спортмастер', 'sportmaster',
      
      // ТЦ
      'mega', 'мега', 'dostyk plaza', 'достык плаза',
      'esentai', 'есентай', 'keruen', 'керуен',
      'forum', 'форум', 'aport', 'апорт',
      'тц', 'трц', 'mall', 'молл', 'магазин', 'shop', 'store',
      
      // Строительные магазины
      'leroy merlin', 'леруа мерлен', 'obi', 'оби',
      'стройка', 'строймарт', 'строительный',
      
      // Общие
      'одежда', 'clothes', 'обувь', 'shoes',
      'товары', 'goods', 'покупка', 'purchase',
    ],
    
    ExpenseCategory.entertainment: [
      // Кинотеатры КЗ
      'chaplin', 'чаплин', 'kinopark', 'кинопарк',
      'cinemax', 'синемакс', 'arsenal', 'арсенал',
      
      // Развлечения
      'кино', 'cinema', 'movie', 'фильм', 'imax',
      'theatre', 'театр', 'концерт', 'concert',
      'билет', 'ticket', 'ticketon', 'тикетон',
      'afisha', 'афиша', 'kassir',
      
      // Стриминг
      'netflix', 'нетфликс', 'кинопоиск', 'kinopoisk',
      'ivi', 'иви', 'okko', 'окко',
      'spotify', 'спотифай', 'apple music', 'deezer',
      'youtube', 'ютуб', 'premium', 'премиум',
      
      // Игры
      'игра', 'game', 'steam', 'стим', 'playstation', 'xbox',
      'epic games', 'эпик геймс', 'nintendo',
      
      // Активности
      'боулинг', 'bowling', 'бильярд', 'billiard',
      'квест', 'quest', 'escape', 'эскейп',
      'караоке', 'karaoke', 'клуб', 'club',
      'парк', 'park', 'аттракцион', 'attraction',
      'музей', 'museum', 'выставка', 'exhibition',
      'зоопарк', 'zoo', 'аквапарк', 'aquapark',
      
      // Ночная жизнь
      'bar', 'бар', 'lounge', 'лаундж',
      'chocolife', 'шоколайф', 'chocofamily',
    ],
    
    ExpenseCategory.bills: [
      // Казахстанские операторы
      'kcell', 'кселл', 'activ', 'актив',
      'beeline', 'билайн', 'altel', 'алтел',
      'tele2', 'теле2',
      
      // Интернет
      'kazakhtelecom', 'казахтелеком', 'megaline', 'мегалайн',
      'idnet', 'идент', 'transtelecom', 'транстелеком',
      'интернет', 'internet', 'wifi', 'вай-фай',
      
      // ЖКХ
      'жкх', 'коммуналка', 'utilities',
      'электричество', 'electricity', 'свет',
      'газ', 'gas', 'вода', 'water', 'отопление', 'heating',
      'ivc', 'ивц', // ИВЦ Алматы
      'samruk energy', 'самрук энерджи',
      
      // Финансовые
      'аренда', 'rent', 'квартплата', 'ипотека', 'mortgage',
      'кредит', 'credit', 'loan', 'займ',
      'страховка', 'insurance',
      'налог', 'tax', 'штраф', 'fine', 'пеня',
      'подписка', 'subscription',
      'телефон', 'phone', 'мобильная связь', 'mobile',
    ],
    
    ExpenseCategory.health: [
      // Казахстанские аптеки
      'europharma', 'еврофарма', 'alma', 'алма',
      '36.6', 'аптека', 'pharmacy', 'дарухана',
      'biospharm', 'биосфарм', 'sadyhan', 'садыхан',
      
      // Клиники КЗ
      'invivo', 'инвиво', 'olympic', 'олимпик',
      'interteach', 'интертич', 'med center',
      'sunkar', 'сункар', 'сиуан',
      'kdl', 'кдл', 'olymp', 'олимп',
      
      // Медицина общее
      'лекарства', 'medicine', 'врач', 'doctor',
      'клиника', 'clinic', 'hospital', 'больница',
      'медицина', 'medical', 'здоровье', 'health',
      'стоматология', 'dental', 'зуб', 'tooth',
      'анализы', 'analysis', 'lab', 'лаборатория',
      
      // Фитнес
      'фитнес', 'fitness', 'gym', 'спортзал', 'тренажёрный',
      'world class', 'x-fit', 'world gym',
      'йога', 'yoga', 'пилатес', 'pilates',
      'массаж', 'massage', 'spa', 'спа', 'салон',
      'оптика', 'optic', 'очки', 'glasses', 'линзы',
    ],
    
    ExpenseCategory.education: [
      // Казахстанские платформы
      'narxoz', 'нархоз', 'kimep', 'кимеп',
      'казну', 'kaznu', 'сдту', 'sdtu',
      'билим', 'bilim', 'umit', 'умит',
      
      // Международные
      'курсы', 'courses', 'course',
      'обучение', 'education', 'learning',
      'школа', 'school', 'университет', 'university',
      'институт', 'institute', 'колледж', 'college',
      
      // Онлайн обучение
      'coursera', 'курсера', 'udemy', 'юдеми',
      'skillbox', 'скиллбокс', 'geekbrains', 'гикбрейнс',
      'duolingo', 'дуолинго', 'skyeng', 'скаенг',
      
      // Книги
      'книга', 'book', 'учебник', 'textbook',
      'meloman', 'меломан', 'книжный', 'bookstore',
      
      // Другое
      'репетитор', 'tutor', 'урок', 'lesson',
      'семинар', 'seminar', 'вебинар', 'webinar',
      'конференция', 'conference', 'тренинг', 'training',
    ],
    
    ExpenseCategory.travel: [
      // Казахстанские авиалинии
      'air astana', 'эйр астана', 'fly arystan', 'флай арыстан',
      'scat', 'скат', 'qazaq air', 'казак эйр',
      
      // Международные авиа
      'авиа', 'avia', 'flight', 'самолёт', 'airplane',
      'аэрофлот', 'aeroflot', 's7', 'turkish', 'emirates',
      
      // Отели
      'отель', 'hotel', 'гостиница', 'hostel', 'хостел',
      'booking', 'букинг', 'airbnb', 'эйрбнб',
      'hotels.kz', 'chocotravel', 'чокотревел',
      'aviata', 'авиата',
      
      // Туризм
      'тур', 'tour', 'путёвка', 'travel',
      'турагентство', 'travel agency',
      'виза', 'visa', 'паспорт', 'passport',
      'экскурсия', 'excursion', 'guide', 'гид',
      'прокат', 'rental', 'car rental',
    ],
    
    ExpenseCategory.transfer: [
      // Казахстанские банки
      'kaspi', 'каспи', 'kaspi bank', 'каспи банк',
      'halyk', 'халык', 'halyk bank', 'народный банк',
      'jusan', 'жусан', 'jusan bank',
      'forte', 'форте', 'forte bank',
      'bereke', 'береке', 'bereke bank',
      'freedom', 'фридом', 'freedom finance',
      'eurasian', 'евразийский',
      
      // Российские банки
      'сбербанк', 'sberbank', 'сбер', 'sber',
      'тинькофф', 'tinkoff', 'тиньков',
      'альфа', 'alfa', 'alpha',
      
      // Переводы
      'перевод', 'transfer', 'p2p',
      'bank', 'банк', 'перевод на карту',
      'золотая корона', 'contact', 'контакт',
      'western union', 'вестерн юнион',
    ],
  };

  ExpenseCategory detectCategory(String merchantName) {
    final lowerMerchant = merchantName.toLowerCase();
    
    // Проверяем каждую категорию
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerMerchant.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return ExpenseCategory.other;
  }
  
  /// Получить список ключевых слов для категории
  List<String> getKeywordsForCategory(ExpenseCategory category) {
    return _categoryKeywords[category] ?? [];
  }
  
  /// Добавить пользовательское правило для определения категории
  /// В будущем можно добавить сохранение пользовательских правил
  static final Map<String, ExpenseCategory> _customRules = {};
  
  void addCustomRule(String keyword, ExpenseCategory category) {
    _customRules[keyword.toLowerCase()] = category;
  }
  
  void removeCustomRule(String keyword) {
    _customRules.remove(keyword.toLowerCase());
  }
}
