#!/bin/bash

DIR=`pwd`
if ! [ $DIR != "" -a -d $DIR/.git ]; then
  echo "Not a versioned directory"
  exit 1
fi

echo "Hotfix branch: "
read HOTFIX_BRANCH

if [ -z $HOTFIX_BRANCH ]; then
  echo "FATAL: Hotfix branch is necessary"
  exit 1
fi

echo "Hotfix to branch (production): "
read HOTFIX_TO_BRANCH

if [[ -z $HOTFIX_TO_BRANCH ]]; then
  HOTFIX_TO_BRANCH='production'
  BRANCH_EXISTS=`git branch -a | grep $HOTFIX_TO_BRANCH`

  if [[ -z $BRANCH_EXISTS ]]; then
    echo "FATAL: Branch '${HOTFIX_TO_BRANCH}' doesn't exist"
    exit 1
  fi
fi

# make the resulting branch
HOTFIX_RESULTING_BRANCH="${HOTFIX_TO_BRANCH}_${HOTFIX_BRANCH}"

git checkout $HOTFIX_TO_BRANCH
echo "Pulling latest code from remote/${HOTFIX_TO_BRANCH}"
git pull

# check out a local clone of the remote branch that was approved
git checkout -b $HOTFIX_RESULTING_BRANCH origin/$HOTFIX_BRANCH

# confirm the list of chages to be patched onto production
ANCESTOR=`git ancestor`

while [ -z $CORRECT ] || [ $CORRECT == 'n' ] || [ $CORRECT == 'N' ]; do
  git log --pretty=oneline --no-merges --first-parent $ANCESTOR..HEAD

  echo "Is this what you want to hotpatch? (y|N)"
  read CORRECT

  if [ $CORRECT == 'n' ] || [ $CORRECT == 'N' ] || [ -z $CORRECT ]; then
    echo "Ancestor commit: "
    read ANCESTOR

    if [[ -z $ANCESTOR ]]; then
      echo "FATAL: Ancestor is required"
      exit 1
    fi
  fi
done

# rebase the hotfix branch "onto" production
git rebase --onto $HOTFIX_TO_BRANCH $ANCESTOR $HOTFIX_RESULTING_BRANCH

# open a pull request for your hotfix branch
git push -u origin $HOTFIX_RESULTING_BRANCH

TEMPLATE="https://gist.githubusercontent.com/Lordnibbler/11002759/raw/08bf3832fe7b7bb0e24d4ecdef6dbc5a801c8554/pull-request-template.md"
FILENAME=`mktemp /tmp/pr_templateXXX`
curl $TEMPLATE > $FILENAME
vi --nofork $FILENAME

hub pull-request -b onelogin:$HOTFIX_TO_BRANCH -h onelogin:$HOTFIX_RESULTING_BRANCH --file $FILENAME

rm $FILENAME
