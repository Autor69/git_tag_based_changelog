#!/bin/sh
############################################################
# Searches all tags in Git and commits between them with   #
# prefix FIX: or FEATURE: puts in json. Example:	       #
# "v1.1.1":{"fixes":["commit1"], features:[commit2]}	   #
############################################################

changelog_file="/tmp/changelog.json"

generate_header () {
	echo -n "{" > $changelog_file
	echo -ne "\"newest_version\":\"$1\"," >> $changelog_file
	echo -ne "\"versions\":{" >> $changelog_file
}

generate_footer() {
	echo -n "}" >> $changelog_file
	echo -n "}" >> $changelog_file
}

get_fixes () {
	IFS=$'\n' # so we can read whole lin
	echo -ne "\"fixes\":[" >> $changelog_file
	first=0
	for line in $(git log --pretty=format:"%s" "$1"..."$2"); do
		if [[ $line == FIX:* ]] ; then
			if [[ "$first" -gt 0 ]]; then
				echo -n "," >> $changelog_file
			fi
			echo -ne "\"${line:5}\"" >> $changelog_file
			first+=1
		fi
	done

	echo -n "]," >> $changelog_file
	unset IFS
	
}

get_features () {
	IFS=$'\n' # so we can read whole lin
	echo -ne "\"features\":[" >> $changelog_file
	first=0
	for line in $(git log --pretty=format:"%s" "$1"..."$2"); do
				if [[ $line == FEATURE:* ]] ; then
					if [[ "$first" -gt 0 ]]; then
						echo -n "," >> $changelog_file
					fi
					echo -ne "\"${line:9}\"" >> $changelog_file
					first+=1
				fi
			done
	echo -n "]}" >> $changelog_file
	unset IFS
}

get_previous_version () {
	echo $(git describe --abbrev=0 "$1"^)
}

while read oldrev newrev refname
do
	is_tag=$(cut -d/ -f2 <<<"$refname")
	newest_version=$(cut -d/ -f3 <<<"$refname")

	if [[ "$is_tag" == "tags" ]] ; then
			generate_header $newest_version
			first=0
			git tag --list | while read line ; do
				version=$line
				previous_version=$(get_previous_version "$version")
				if [[ "$first" -gt 0 ]]; then
					echo -n "," >> $changelog_file
				fi
				echo -ne "\"$version\":{" >> $changelog_file
				get_fixes $version $previous_version
				get_features $version $previous_version
				first+=1
			done
			generate_footer
	fi
done