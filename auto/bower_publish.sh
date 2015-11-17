#!/bin/bash

if [ -z "$GH_TOKEN" ]; then
  echo "must provide a github oauth token"
  exit 0
fi

BASE_DIR=$(pwd)
TMP_DIR=$(echo $BASE_DIR/tmp)
BOWER_DIR=$(echo $TMP_DIR/bower-repo)
DIST_DIR=$(echo $BASE_DIR/dist)

function latestCommit {
  if [ -z "$1" ]; then
    return 0
  fi

  if [ ! -d "$1" ]; then
    return 0
  fi

  cd $1
  echo $(git log -1 --pretty=format:%h)
}

function latestTag {
  if [ -z "$1" ]; then
    return 0
  fi

  if [ ! -d "$1" ]; then
    return 0
  fi

  local commit=$(latestCommit $1)
  local latest_tag=$(git tag | sed -n 1p)

  if [ -z $latest_tag ]; then
    exit 0
  fi

  echo "${latest_tag}-${commit}"
}

GIT_COMMIT=$(latestCommit $BASE_DIR)

if [ -z "$TRAVIS_TAG" ]; then
  TRAVIS_TAG=$(latestTag $BASE_DIR)

  if [ -z "$TRAVIS_TAG" ]; then
    echo "unable to find any tags to riff off, exiting"
    exit 0
  fi

  echo "no travis tag found, using latest tag with commit hash - $TRAVIS_TAG"
  exit 0
fi

function publish {
  local commit_msg="[auto](${GIT_COMMIT})"

  mkdir -p TMP_DIR

  if [ -d $BOWER_DIR ]; then
    echo "previous build present, deleting"
    rm -rf $BOWER_DIR
  fi

  if [ ! -f "${DIST_DIR}/flyby.js" ]; then
    echo "missing un-minified file, was grunt release run?"
    exit 1
  fi

  if [ ! -f "${DIST_DIR}/flyby.min.js" ]; then
    echo "missing minified file, was grunt release run?"
    exit 1
  fi

  git clone https://github.com/dadleyy/flyby-bower.git $BOWER_DIR

  cp "${BASE_DIR}/bower.json" $BOWER_DIR
  cp "${DIST_DIR}/flyby.min.js" $BOWER_DIR
  cp "${DIST_DIR}/flyby.js" $BOWER_DIR

  cd $BOWER_DIR
  local changes=$(git status --short)

  if [ -z "$changes" ]; then
    echo "no changes detected, skipping build"
    exit 0
  fi

  echo "committing changes to flyby bower repo: ${commit_msg} | files: \n $changes"

  if [ ! -x $DRY_RUN ]; then
    echo "exiting before committing"
    cd $BASE_DIR
    exit 0
  fi

  git config user.name "$GH_USER"
  git config user.email "$GH_EMAIL"
  git config credential.helper "store --file=.git/credentials"
  echo "https://${GH_TOKEN}:@github.com" > .git/credentials

  git add --all
  git commit -a -m $commit_msg
  git tag $TRAVIS_TAG
  git push origin master
  git push --tags
  cd $BASE_DIR
}

if [ -s "${BASE_DIR}/package.json" ]; then
  publish
else
  echo "bower_publish must be run from the root of the flyby repo"
  exit 1
fi
