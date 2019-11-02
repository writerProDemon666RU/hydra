#!/bin/sh
set -e

mkdir -p './catalog/page'
PAGEDIR="./catalog/page"

# переменная с кукисой пользователя. залогиньтесь на сайте и вставьте свою
export COOKIE='<SESSION COOKIE HERE>'

get_catalog() {
	PAGES="$1"
	COOKIE="$2"
	PAGEDIR="$3"
	for (( i = 0; i < "$PAGES"; i+=1 )); do
		touch "$PAGEDIR/$i"
		torsocks curl "$TARGET_URL/catalog?query=&sort_direction=desc&sort=rate&page=$i" \
			-H "Host: $TARGET_URL" \
			-H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; rv:60.0) Gecko/20100101 Firefox/60.0' \
			-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
			-H 'Accept-Language: en-US,en;q=0.5' \
			--compressed \
			-H "Referer: $TARGET_URL/catalog" \
			-H "$COOKIE" \
			-H 'Connection: keep-alive' \
			-H 'Upgrade-Insecure-Requests: 1' \
		> "$PAGEDIR/$i"
	done
}

cat shops/page/* \
	| pup 'a json{}'							\
    | jq 'map(.href)'							\
    | grep '/market/'							\
    | grep -v 'http'							\
    | grep -v 'create'							\
    >> markets.txt

sed -i \
	-e 's/,//g'									\
	-e 's/"//g'									\
	-e 's/ //g' 								\
	markets.txt

while read -r MARKET; do
	echo "$MARKET"
	torsocks curl "$TARGET_URL/market/$MARKET/profile" \
		-H "Host: $TARGET_URL" \
		-H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; rv:60.0) Gecko/20100101 Firefox/60.0' \
		-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
		-H 'Accept-Language: en-US,en;q=0.5' \
		--compressed \
		-H "Referer: $TARGET_URL/catalog" \
		-H "$COOKIE" \
		-H 'Connection: keep-alive' \
		-H 'Upgrade-Insecure-Requests: 1' \
	> "$MARKET"
done < markets.txt

products_extract() {
	cat "$PAGEDIR"/* 							\
		| pup 'a json{}'						\
		| jq 'map(.href)'						\
		| grep 'product'						\
		| sed 's/,//g'							\
		| sed 's/"//g'							\
		| sed 's/ //g'							\
		> "$PAGEDIR"/products.txt
}

while read -r p; do
	echo "$p"
	touch ".$p"
	torsocks curl "$TARGET_URL$p" \
		-H "Host: $TARGET_URL" \
		-H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; rv:60.0) Gecko/20100101 Firefox/60.0' \
		-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
		-H 'Accept-Language: en-US,en;q=0.5' \
		--compressed \
		-H "Referer: $TARGET_URL/catalog" \
		-H "$COOKIE" \
		-H 'Connection: keep-alive' \
		-H 'Upgrade-Insecure-Requests: 1' \
	> ".$p"
done < products.txt

for filename in ./*; do
	pup 'a json{}' < "$filename" 				\
    | jq 'map(.href)' 							\
    | grep '/market/.*/profile?product_id='		\
    | grep -v 'region_id'						\
    | sed 's/,//g' 								\
	| sed 's/"//g' 								\
	| sed 's/ //g'								\
	>> expiriences.txt
done

while read -r p; do
	PAGES=$(
		pup 'ul[class="pagination"] li:nth-last-of-type(3) text{}' \
		< "expiriences$p/1"
		)
	echo "$p,$PAGES" \
		>> expiriences_pages.txt
done < expiriences.txt

while read -r record; do
	PAGES=$(echo "$record" | cut -d',' -f2)
	LINK=$(echo "$record" | cut -d',' -f1)
	for (( i = 2; i < $PAGES+1; i++ )); do
		mkdir -p "expiriences/$LINK"
		touch "expiriences/$LINK/$i"
		torsocks curl \
			"$TARGET_URL$LINK&page=$i" \
			-H "Host: $TARGET_URL" \
			-H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; rv:60.0) Gecko/20100101 Firefox/60.0' \
			-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
			-H 'Accept-Language: en-US,en;q=0.5' \
			--compressed \
			-H "Referer: $TARGET_URL/catalog" \
			-H "$COOKIE" \
			-H 'Connection: keep-alive' \
			-H 'Upgrade-Insecure-Requests: 1' \
		> "expiriences$LINK/$i"
	done
done < expiriences_pages.txt

get_user() {
	USER="$1"
	COOKIE="$COOKIE"
	echo "$USER" >> users_seen.txt
	torsocks curl "$TARGET_URL/$USER" \
		-H "Host: $TARGET_URL" \
		-H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; rv:60.0) Gecko/20100101 Firefox/60.0' \
		-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
		-H 'Accept-Language: en-US,en;q=0.5' \
		--compressed \
		-H "Referer: $TARGET_URL/catalog" \
		-H "$COOKIE" \
		-H 'Connection: keep-alive' \
		-H 'Upgrade-Insecure-Requests: 1' \
	> ./"$USER"
}
export -f get_user

parallel -j20 -a users1.txt get_user

wget \
	--mirror \
	--no-parent \
	--load-cookies cookies.txt \
	"$MARKET_URL/forum"
