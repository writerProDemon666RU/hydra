# Подвальный Data Science

Репозиторий с исходными кодами и данными для спецпроекта darknark.lenta.ru.

Файл collect.sh — набор shell функций для сбора данных. Прочитали, разобрались, выставили кукису, скопировали функцию — выполнили.
Ожидаемый результат — много HTML страниц.

Немного полезной инфы:

Страницы магазинов имеют URL вида:
/market/"$market_id"
Страницы товаров имеют URL вида:
/product/"$product_id"
Страницы с отзывами имеют URL вида:
/market/"$market_id"/profile?product_id="$product_id"?page="$page_num", где

$market_id - уникальный ID магазина
$product_id - уникальный ID позиции
$page_num - номер страницы от 1 до 100

$MARKET_URL — адрес сайта для выкачки

У каждого пользователя есть персональная страница. Страница содержит имя пользователя, дату его регистрации и количество покупок.
Страницы пользователей имеют URL вида:
/user/$username, где

$username -- имя пользователя.

Иногда качать в один поток очень долго и стоит распараллелить.

```shell

get_user() {
	USER="$1"
	COOKIE="$2"
	echo "$USER" >> users_seen.txt
	torsocks curl "$MARKET_URL/$USER" \
		-H "Host: $MARKET_URL" \
		-H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; rv:60.0) Gecko/20100101 Firefox/60.0' \
		-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
		-H 'Accept-Language: en-US,en;q=0.5' \
		--compressed \
		-H "Referer: $MARKET_URL/catalog" \
		-H "$COOKIE" \
		-H 'Connection: keep-alive' \
		-H 'Upgrade-Insecure-Requests: 1' \
	> ./"$USER"
}
export -f get_user

parallel -j20 -a users.txt get_user $COOKIE

```

Файл parse.ipynb — обработка (парсинг) и очистка собранных данных. Ожидаемый результат — несколько csv таблиц.

Файл anal.ipynb — простые примеры анализа данных из csv таблиц.

Архив tables.zip содержит два файла:
- all_comments.csv — отзывы, выкачка от 1 августа
- markets.csv — магазины, выкачка от 1 августа
