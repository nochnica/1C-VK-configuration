﻿	
#Область Переопределяемые 

Функция ПолучитьAccessToken()   
	AccessToken = Константы.Токен.Получить();	
	Возврат AccessToken;
КонецФункции

#КонецОбласти


#Область ВходящиеСообщения

// Процедура обрабатывает входящее HTTP-сообщение от сервера ВКонтакте
Процедура ОбработатьСообщениеИзВК(Запрос, Ответ) Экспорт
	СтрокаJSON = Запрос.ПолучитьТелоКакСтроку(); //получаем весь json одной длинной строкой	
	СтруктураДанных = ФункцииJSON.ОбработатьJSON(СтрокаJSON); // Получили структуру из JSON-а
	// Обрабатываем сообщение в зависимости от его типа (confirmation, message_new и т.д.)
	ОбработатьДанныеСообщения(СтруктураДанных, Ответ);
КонецПроцедуры

// Формат запроса ВК:
//{
//    "group_id": 230152621,
//    "type": "message_new",
//    "event_id": "4ffab9fc1d5787be222141c390e3622274a8fcd3",
//    "v": "5.199",
//    "object": {
//        "client_info": {
//           <всякая информация> 
//        },
//        "message": {
//            "date": 1745157177,
//            "from_id": 552360884,
//            "id": 45,
//            "version": 10000118,
//            "out": 0,
//            "fwd_messages": [],
//            "important": false,
//            "is_hidden": false,
//            "attachments": [],
//            "conversation_message_id": 36,
//            "payload": "{\"command\":\"start\"}",
//            "text": "Start",
//            "peer_id": 552360884,
//            "random_id": 0
//        }
//    }
//}
Процедура ОбработатьДанныеСообщения(СтруктураДанных, Ответ)  
	// Если ВК пытается подтвердить адрес сервера, возвращаем ему нужную строку
	// Тут надо бы тащить строку из константы СтрокаПодтверждения, наверное
	Если СтруктураДанных.Свойство("type") И СтруктураДанных.type = "confirmation" Тогда
		Ответ.УстановитьТелоИзСтроки("61172d7c", "UTF-8"); 
		
	// Если пришло новое сообщение
    ИначеЕсли СтруктураДанных.Свойство("type") И СтруктураДанных.type = "message_new" Тогда   
		Ответ.УстановитьТелоИзСтроки("ok", "UTF-8");
	    // Если object на месте
		Если СтруктураДанных.Свойство("object") Тогда  
						
			Попытка      
				ОбъектСообщение = СтруктураДанных.object.message; 
				Гсч = Новый ГенераторСлучайныхЧисел();
				random_id = Формат(Гсч.СлучайноеЧисло(), "ЧРГ=''; ЧГ=0"); // В качестве рендом_ид лучше не использовать 0
				peer_id   = Формат(ОбъектСообщение.peer_id, "ЧРГ=''; ЧГ=0");
				from_id   = Формат(ОбъектСообщение.from_id, "ЧРГ=''; ЧГ=0");
				
				Если ОбъектСообщение.Свойство("payload") Тогда
					payload = ФункцииJSON.ОбработатьJSON(ОбъектСообщение.payload);
					Если payload.Свойство("button") Тогда
						Данные = Клавиатура.СформироватьКлавиатуру(payload.button, from_id);
					Иначе
						Данные = Клавиатура.СформироватьКлавиатуру();
					КонецЕсли; 
				Иначе 
					Данные = Клавиатура.СформироватьКлавиатуру(, from_id, ОбъектСообщение.text);
				КонецЕсли;
				         
				Если Данные.Свойство("template") Тогда
					ВсеТовары   = Данные.template;
					РазмерЧанка = 10;
					НомерЧанка  = 1;
					Индекс      = 0; 
					ОбщееКол    = ВсеТовары.Количество();
					
					Пока Индекс < ОбщееКол Цикл
					    Подмассив = Новый Массив;
						//КонецЧанка = Минимум(Индекс + РазмерЧанка - 1, ОбщееКол); 
						КонецЧанка = ?((Индекс + РазмерЧанка - 1) < ОбщееКол, Индекс + РазмерЧанка - 1, ОбщееКол - 1);
						Для i = Индекс по КонецЧанка Цикл
							Подмассив.Добавить(ВсеТовары[i]);	
						КонецЦикла;
						//message_send(random_id, peer_id, Данные.message, Неопределено, JSONПодмассив);
						Карусель = Новый Структура;
						Карусель.Вставить("type", "carousel");
						Карусель.Вставить("elements", Подмассив); 
						СтрКарусели = ФункцииJSON.СформироватьJSON(Карусель);
						
						message_send(random_id + НомерЧанка, peer_id, "Страница каталога №" + Строка(НомерЧанка), Неопределено, СтрКарусели);
						
						Индекс = Индекс + РазмерЧанка;
						НомерЧанка = НомерЧанка + 1;
					КонецЦикла;
				ИначеЕсли Не Данные = Неопределено Тогда
					message_send(random_id, peer_id, Данные.message, Данные.keyboard);
					//message_send(random_id, peer_id, Данные.keyboard);
				Иначе	
				КонецЕсли;
				//message_send(random_id, peer_id, Данные.message, Данные.keyboard);
			Исключение   
				Ответ.УстановитьТелоИзСтроки(ОписаниеОшибки(), "UTF-8");
			КонецПопытки;
		КонецЕсли;
		
	// Если нажата callback-кнопка
	ИначеЕсли СтруктураДанных.Свойство("type") И СтруктураДанных.type = "message_event" Тогда
		Ответ.УстановитьТелоИзСтроки("ok", "UTF-8");
		// Если object на месте
		Если СтруктураДанных.Свойство("object") Тогда  
						
			Попытка      
				ОбъектСообщение = СтруктураДанных.object;     
				
				user_id   = Формат(ОбъектСообщение.user_id, "ЧРГ=''; ЧГ=0");
				peer_id   = Формат(ОбъектСообщение.peer_id, "ЧРГ=''; ЧГ=0");
				event_id  = Формат(ОбъектСообщение.event_id, "ЧРГ=''; ЧГ=0");
								
				Если ОбъектСообщение.Свойство("payload") Тогда
					payload = ОбъектСообщение.payload;   
				    Если payload.Свойство("button") Тогда
						Корзина.ДобавитьВКорзину(payload.button, user_id);	
					Иначе 
					КонецЕсли; 
				Иначе 
				КонецЕсли;
				
				sendMessageEventAnswer(event_id, user_id, peer_id);
				
			Исключение   
				Ответ.УстановитьТелоИзСтроки(ОписаниеОшибки(), "UTF-8");
			КонецПопытки;
		КонецЕсли;	
		
	КонецЕсли;
КонецПроцедуры

#КонецОбласти



#Область МетодыAPI

Процедура message_send(random_id = Неопределено, peer_id = Неопределено, 
					 message = Неопределено, keyboard = Неопределено, 
					 template = Неопределено) Экспорт
					  
	parameters = Новый Массив;
	Если НЕ random_id = Неопределено Тогда
		parameters.Добавить("random_id=" + random_id);
	КонецЕсли;
	Если НЕ peer_id = Неопределено Тогда
		parameters.Добавить("peer_id=" + peer_id);		
	КонецЕсли; 
	Если НЕ template = Неопределено Тогда
		parameters.Добавить("template=" + template);
		//message = template;
	КонецЕсли;	
	Если НЕ keyboard = Неопределено Тогда
		parameters.Добавить("keyboard=" + keyboard);
		//message = "я дебил с кибордом";
	КонецЕсли;
	Если НЕ message = Неопределено Тогда
		parameters.Добавить("message=" + message);		
	КонецЕсли; 
	
	ОтправитьЗапросВВК(ПолучитьAccessToken(), "messages.send", parameters);
	
КонецПроцедуры

Процедура sendMessageEventAnswer(event_id, user_id, peer_id)
	parameters = Новый Массив;
	Если НЕ event_id = Неопределено Тогда
		parameters.Добавить("event_id=" + event_id);
	КонецЕсли;
	Если НЕ user_id = Неопределено Тогда
		parameters.Добавить("user_id=" + user_id);		
	КонецЕсли; 
	Если НЕ peer_id = Неопределено Тогда
		parameters.Добавить("peer_id=" + peer_id);
		//message = template;
	КонецЕсли;	
	
	event_data = Новый Структура;    
    event_data.Вставить("type", "show_snackbar");
    event_data.Вставить("text", "Товар добавлен в корзину!");
	
	event_dataJSON = ФункцииJSON.СформироватьJSON(event_data);
		
	Если НЕ event_dataJSON = Неопределено Тогда
		parameters.Добавить("event_data=" + event_dataJSON);		
	КонецЕсли;
	
	ОтправитьЗапросВВК(ПолучитьAccessToken(), "messages.sendMessageEventAnswer", parameters);	 	
КонецПроцедуры

#КонецОбласти



#Область ИсходящиеСообщения

Процедура ОтправитьЗапросВВК(access_token, method, parameters) Экспорт
    Результат = "";   

    Попытка
        ssl = Новый ЗащищенноеСоединениеOpenSSL();
        // Исправлен порт на 443
        СоединениеHTTP = Новый HTTPСоединение("api.vk.com", 443,,,, 180, ssl, Ложь);
        
        // Сформировать параметры строки
        ПараметрыМетода = "";  
		
        Для каждого Строка Из parameters Цикл
            ПараметрыМетода = ПараметрыМетода + Строка + "&";
        КонецЦикла;

        ПолныйАдрес = "/method/" + method + "?" + ПараметрыМетода +
                      "access_token=" + access_token + "&v=5.199";          
        HTTPЗапрос = Новый HTTPЗапрос;          
		
        HTTPЗапрос.АдресРесурса = ПолныйАдрес;   
		
		
        РезультатЗапрос = СоединениеHTTP.Получить(HTTPЗапрос);
        //СыроеТело = РезультатЗапрос.ПолучитьТелоКакСтроку();  
		//Результат = СформироватьJSON(ОбработатьJSON(СыроеТело));
    Исключение
    КонецПопытки;

    //Возврат Результат;
КонецПроцедуры
#КонецОбласти
 