#!/bin/bash

BASE_DIR=$(pwd)
TMP_DIR=$(echo $BASE_DIR/tmp)
BOWER_DIR=$(echo $TMP_DIR/bower-repo)
DIST_DIR=$(echo $BASE_DIR/dist)

if [ -z "$TRAVIS_TAG" ]; then
  echo "no tag found, skipping bower publish"
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

  git clone git@github.com:dadleyy/flyby-bower.git $BOWER_DIR

  cp "${BASE_DIR}/bower.json" $BOWER_DIR
  cp "${DIST_DIR}/flyby.min.js" $BOWER_DIR
  cp "${DIST_DIR}/flyby.js" $BOWER_DIR

  cd $BOWER_DIR
  git status
  git add --all
  echo "committing changes to flyby bower repo: ${commit_msg}"
  cd $BASE_DIR
}

function latestCommit {
  cd $BASE_DIR
  echo $(git log -1 --pretty=format:%h)
}

GIT_COMMIT=$(latestCommit)

if [ -s "${BASE_DIR}/package.json" ]; then
  publish
else
  echo "bower_publish must be run from the root of the flyby repo"
  exit 1
fi
