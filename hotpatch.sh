#!/bin/bash

DIR=`pwd`
if ! [ $DIR != "" -a -d $DIR/.git ]; then
  echo "Not a versioned directory"
  exit 1
fi

echo "Hotfix branch: "
read HOTFIX_BRANCH

if [ -z $HOTFIX_BRANCH ]; then
  echo "Hotfix branch is necessary"
  exit 1
fi

echo "Hotfix to branch (production): "
read HOTFIX_TO_BRANCH

if [ -z $HOTFIX_TO_BRANCH ]; then
  HOTFIX_TO_BRANCH='production'
fi

# make the resulting branch
HOTFIX_RESULTING_BRANCH="${HOTFIX_TO_BRANCH}_${HOTFIX_BRANCH}"

git checkout $HOTFIX_TO_BRANCH
git pull

# check out a local clone of the remote branch that was approved
git checkout -b $HOTFIX_RESULTING_BRANCH origin/$HOTFIX_BRANCH

# confirm the list of chages to be patched onto production
ANCESTOR=`git ancestor`

for [ -z $CORRECT || $CORRECT == 'n' || $CORRECT == 'N' ]; do
  git log --pretty=oneline --no-merges --first-parent $ANCESTOR..HEAD

  echo "Is this what you want to hotpatch? (Y|n)"
  read CORRECT

  if ![ $CORRECT == 'y' || $CORRECT == 'Y' || -z $CORRECT ]; then
    echo "Ancestor commit: "
    read ANCESTOR
  fi
done

# rebase the hotfix branch "onto" production
git rebase --onto $HOTFIX_TO_BRANCH $ANCESTOR $HOTFIX_RESULTING_BRANCH

# open a pull request for your hotfix branch
git push -u origin $HOTFIX_RESULTING_BRANCH
hub pull-request -b onelogin:$HOTFIX_TO_BRANCH -h onelogin:$HOTFIX_RESULTING_BRANCH

