﻿
Функция documentsGET(Запрос)
	Ответ = Новый HTTPСервисОтвет(200);  
	Ответ.УстановитьТелоИзСтроки("ok", "UTF-8");
	Возврат Ответ;
КонецФункции

Функция documentsPOST(Запрос)
    Ответ = Новый HTTPСервисОтвет(200);    
	VK.ОбработатьСообщениеИзВК(Запрос, Ответ);
	Возврат Ответ; 
КонецФункции   


