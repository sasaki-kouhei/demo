#!/bin/bash

showUsage(){
  echo "
  USAGE:$0 -t [hotfix|minar|major] -m message
           -h help.
  "
}

noGitDirectory(){
  echo "Can't find .git directory"
}

gitCheckout(){
  git checkout -f $1
  git pull -p
}

gitAdd(){
  git add $1
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
}

findGitDirectory

if [ ! -e ".git" ]; then
  noGitDirectory
  exit 1
fi

MODE="" #
MESSAGE="" # commit message.
while getopts t:m:h OPT
do
  case $OPT in
    t) case $OPTARG in
         "hotfix" | "minor" | "major") MODE="$OPTARG";;
         * ) echo "$OPTARG" ;showUsage ; exit 1 ;;
       esac ;;

    m) MESSAGE=$OPTARG ;;
    h) showUsage ;  exit 0 ;;
    \?) showUsage ; exit 1 ;;
  esac
done

if [ "$MODE" = "" ] || [ "$MESSAGE" = "" ]; then
  showUsage
  exit 1
fi

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

gitAdd "version.txt"
gitCommit "$MESSAGE"
gitTag "$(cat ./version.txt)" "$MESSAGE"
