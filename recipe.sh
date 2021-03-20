#!/bin/sh

input_query(){
	printf "Search query: "
	read -r query
}

query="$*"

[ -z "$query" ] && input_query

printf "\033[0;33mSearching for \033[1;34m%s \033[0;33mon based.cooking\n" "$query"

links="$(curl "based.cooking" -Ls | grep "<li><a href=\".*\">.*</a></li>")"
results="$(printf "%s" "$links" | grep -i "$query")"
names="$(printf "%s" "$results" | sed -e 's|<li><a href=".*">||g' -e 's|</a></li>||g')"

hyperlink="$(printf "%s" "$links" | grep "$(printf "%s" "$names" | fzf)")"
link="$(printf "%s" "$hyperlink" | sed -e 's|<li><a href="||g' -e 's|">.*</a></li>||g')"

recipe="$(curl "based.cooking/$link" -Ls | sed -e "s|&rsquo;|'|g" -e 's|&ndash;|–|g' -e 's|&frac14;|1/4|g')"

title="$(printf "%s" "$recipe" | head -10 | grep "<h1>.*</h1>" | sed -e 's|<h1>||g' -e 's|</h1>||g')"
printf "\n\033[1;34m%s\n\033[0;33m" "$title"
for i in $(seq "$(printf "%s" "$title" | wc -m)"); do
	printf "–"
done
printf "\n"

description="$(printf "%s" "$recipe" | head -15 | grep "<p>.*" | sed -e 's|<p>||g' -e 's|</p>||g' -e 's|<img src=".*"||g' -e 's|alt=".*" />||g' -e 's|/>||g' | grep .)"
printf "\n  %s\n\n\033[1;34mIngredients\n\033[0;33m–––––––––––\n" "$description"

for i in $(seq "$(printf "%s" "$recipe" | wc -l)"); do
	currentLine="$(printf "%s" "$recipe" | sed "$i"'q;d')"
	if [ "$currentLine" = "<h2>Ingredients</h2>" ]; then
		ingredientList=""
		for j in $(seq 30); do
			number=$(( i + j ))
			[ -n "$(printf "%s" "$recipe" | sed "$number"'q;d' | grep "</ul>")" ] && break

			if [ -n "$(printf "%s" "$recipe" | sed "$number"'q;d' | grep "<li>")" ]; then
				ingredientList="$ingredientList§  * $(printf "%s" "$recipe" | sed "$number"'q;d')"
			fi
		done

		printf "%s\n" "$(printf "%s" "$ingredientList" | tr '§' '\n' | sed -e 's|<li>||g' -e 's|</li>||g' | grep -s .)"
	fi
done

printf "\n\033[1;34mDirections\n\033[0;33m––––––––––\n"
for i in $(seq "$(printf "%s" "$recipe" | wc -l)"); do
	currentLine="$(printf "%s" "$recipe" | sed "$i"'q;d')"
	if [ "$currentLine" = "<h2>Directions</h2>" ] || [ "$currentLine" = "<h2>Instructions</h2>" ]; then
		directionList=""
		stepCounter=1
		for j in $(seq 50); do
			number=$(( i + j ))
			[ -n "$(printf "%s" "$recipe" | sed "$number"'q;d' | grep "</ol>")" ] && break

			if [ -n "$(printf "%s" "$recipe" | sed "$number"'q;d' | grep "<li>")" ]; then
				directionList="$directionList§  $stepCounter * $(printf "%s" "$recipe" | sed "$number"'q;d')"
				stepCounter=$(( stepCounter + 1 ))
			fi
		done

		printf "%s\n" "$(printf "%s" "$directionList" | tr '§' '\n' | sed -e 's|<li>||g' -e 's|</li>||g' | grep -s .)"
	fi
done

printf "\n\033[1;34mContributed by\n\033[0;33m––––––––––––––\n"

for i in $(seq "$(printf "%s" "$recipe" | wc -l)"); do
	currentLine="$(printf "%s" "$recipe" | sed "$i"'q;d')"
	if [ "$currentLine" = "<h2>Contribution</h2>" ]; then
		contribList=""
		for j in $(seq 10); do
			number=$(( i + j ))
			[ -n "$(printf "%s" "$recipe" | sed "$number"'q;d' | grep "</ul>")" ] && break

			if [ -n "$(printf "%s" "$recipe" | sed "$number"'q;d' | grep "<li>")" ]; then
				contribList="$contribList§  * $(printf "%s" "$recipe" | sed "$number"'q;d' | awk -F' . ' '{print $1}')"
			fi
		done

		printf "%s\n" "$(printf "%s" "$contribList" | tr '§' '\n' | sed -e 's|<li>||g' -e 's|</li>||g' | grep -s .)"
	fi
done
