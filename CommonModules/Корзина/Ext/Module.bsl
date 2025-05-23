﻿
Процедура ДобавитьВКорзину(Артикул, user_id) Экспорт  
	СтрокаID = Строка(user_id);
	
	// 1. Ищем существующую строку корзины
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ ПЕРВЫЕ 1
	|   Корзина.Ссылка КАК Ссылка
	|ИЗ
	|   Справочник.КорзинаПользователей КАК Корзина
	|ГДЕ
	|   Корзина.Пользователь = &Пользователь
	|   И Корзина.Артикул = &Артикул";

	Запрос.УстановитьПараметр("Пользователь", СтрокаID);
	Запрос.УстановитьПараметр("Артикул", Артикул);

	Результат = Запрос.Выполнить().Выбрать();

	Если Результат.Следующий() Тогда
	    // Если уже есть — увеличим количество
	    Элемент = Результат.Ссылка.ПолучитьОбъект();
	    Элемент.Количество = Элемент.Количество + 1;
	    Элемент.Записать();
	Иначе
	    // Если нет — создадим новый элемент
	    Элемент = Справочники.КорзинаПользователей.СоздатьЭлемент(); 
		//Гсч = Новый ГенераторСлучайныхЧисел();
		//Элемент.Код = Гсч.СлучайноеЧисло(10, 1000000);
		Элемент.Пользователь = СтрокаID;
	    Элемент.Артикул = Артикул;
	    Элемент.Количество = 1;
	    Элемент.Записать();
	КонецЕсли;
    
КонецПроцедуры      

// Удалить все записи корзины для пользователя
Процедура УдалитьЗаписиКорзины(UserId) Экспорт
    Запрос = Новый Запрос;
    Запрос.Текст =
    "ВЫБРАТЬ
    |   Корзина.Ссылка КАК Ссылка
    |ИЗ
    |   Справочник.КорзинаПользователей КАК Корзина
    |ГДЕ
    |   Корзина.Пользователь = &Пользователь";
    Запрос.УстановитьПараметр("Пользователь", UserId);

    Выборка = Запрос.Выполнить().Выбрать();
    Пока Выборка.Следующий() Цикл
        Справочники.КорзинаПользователей.Удалить(Выборка.Ссылка);
    КонецЦикла;
КонецПроцедуры  

Функция ПолучитьТекстКорзины(from_id) Экспорт 
    // 1. Собираем данные из справочника «КорзинаПользователей»
    Запрос = Новый Запрос;
    Запрос.Текст = 
    "ВЫБРАТЬ
    |   Корзина.Артикул КАК Артикул,
    |   Корзина.Количество КАК Количество
    |ИЗ
    |   Справочник.КорзинаПользователей КАК Корзина
    |ГДЕ
    |   Корзина.Пользователь = &Пользователь";
    Запрос.УстановитьПараметр("Пользователь", Строка(from_id));
    
    Результат = Запрос.Выполнить().Выбрать();
    
    // 2. Подготовим переменные
    Текст           = "";
    КоличПозиций    = 0;
    ОбщаяСумма      = 0;
    
    // 3. Обходим результаты
    Пока Результат.Следующий() Цикл
        Если КоличПозиций = 0 Тогда
            // первая запись — формируем заголовок
            Текст = "У вас в корзине:" + Символы.ПС;
        КонецЕсли;
        
        Артикул = Результат.Артикул;
        Колво   = Результат.Количество;
		
        // Ищем саму номенклатуру
        Номенклатура = Каталог.НайтиПоАртикулу(Артикул);
        Если Номенклатура = Неопределено Тогда
            Название = "[не найден товар]";     
		Иначе
            Название = Номенклатура.Наименование;
        КонецЕсли;
		
		КоличПозиций = КоличПозиций + 1;
        Цена         = Каталог.ПолучитьЦену(Номенклатура);
		Сумма        = Цена * Колво;
		ОбщаяСумма   = ОбщаяСумма + Сумма;
		
        // Добавляем строку с позицией
        Текст = Текст + Строка(КоличПозиций) + ". " + Название +
            " — " + Формат(Цена, "ЧДЦ=2") + "₽ х " + Строка(Колво) + " шт." + 
		    " = " + Формат(Сумма, "ЧДЦ=2") + Символы.ПС;
    КонецЦикла;
    
    // 4. Если не было ни одной записи
    Если КоличПозиций = 0 Тогда
        Возврат "Ваша корзина пуста.";
    КонецЕсли;
	
	Текст = Текст + Символы.ПС + Символы.ПС + 
	    "Общая сумма: " + Формат(ОбщаяСумма, "ЧДЦ=2") + "₽"; 
  
    Возврат Текст;
КонецФункции   
