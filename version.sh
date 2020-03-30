#!/bin/bash

noGitDirectory(){
  echo "Can't find .git directory"
}

gitCheckout(){
  git checkout -f $1
  git pull -p
}

gitAdd(){
  git add $*
}

gitCommit(){
  git commit -m "${1}"
  git push origin master
}

gitTag(){
  git tag -a "v${1}" -m "${2}"
  git push --tags
}

findGitDirectory(){
  COUNT=0
  while [ $COUNT -lt 5 ]
  do
    if [ ! -e ".git" ]
    then
      cd ../
    fi
    COUNT=$(expr $COUNT + 1)
  done

  if [ ! -e ".git" ]; then
    noGitDirectory
    exit 1
  fi
}

getTagMode() {
  line=$(git log --pretty=oneline --abbrev-commit --merges -n 1)
  param=$(echo $line | grep "tag")
  if [ "$param" != "" ];
  then
    exit 0
  fi

  param=$(echo $line | grep "feature")
  if [ "$param" != "" ];
  then
    echo "minor"
    return
  fi

  param=$(echo $line | grep "develop")
  if [ "$param" != "" ];
  then
    echo "minor"
    return
  fi

  param=$(echo $line | grep "hotfix")
  if [ "$param" != "hotfix" ];
  then
    echo "hotfix"
    return
  fi
  
  echo "hotfix"
}

getChangeLog(){
  git log "${1}".."${2}" | egrep -v "^commit|^Date:|^Author|Merge:|Merge pull request|^\s*$" | sed  "s/^ */- /g"
}

createChangeLogFile(){
  log=$(getChangeLog "${1}" "${2}")

  if [ $log = "" ];
  then
    exit 1
  fi

  current_log=$(cat ./CHANGELOG.md)
  echo -e "## v$(cat ./version.txt) $(date '+%Y-%m-%d')"
  echo -e "
$log

$current_log
"
}

findGitDirectory
PREV=$(git tag -l  | tail -1)
MODE=$(getTagMode)

gitCheckout "master"

if [ ! -e version.txt ];then
   echo "0.0.0" > version.txt
fi

major=$(cat version.txt | cut -d '.' -f 1)
minor=$(cat version.txt | cut -d '.' -f 2)
hotfix=$(cat version.txt | cut -d '.' -f 3)

if [ "$MODE" = major ];then
  major=$(expr $major + 1)
  minor=0
  hotfix=0
fi

if [ "$MODE" = minor ];then
  minor=$(expr $minor + 1)
  hotfix=0
fi

if [ "$MODE" = hotfix ];then
  hotfix=$(expr $hotfix + 1)
fi

echo "$major.$minor.$hotfix" | tee version.txt
current_log=$(getChangeLog "tags/$PREV" "origin/master")
log=$(createChangeLogFile "tags/$PREV" "origin/master")

echo -e "$log" > ./CHANGELOG.md

gitAdd "version.txt" "./CHANGELOG.md"
gitCommit "v$(cat ./version.txt) release!"
gitTag "$(cat ./version.txt)"  "$(echo -e $current_log)"

