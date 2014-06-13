#!/bin/bash

FORCE_DEPLOY=${FORCE_DEPLOY-false}

duplicate_exit() {
  echo "duplicate run"
  exit 1
}

run_testcode() {
  # Rails
  bundle install --path=${CI_BUNDLE_DIR}
  RAILS_ENV=test bundle exec rake spec
  retval=$?

  if [ $retval -ne 0 ]; then
    echo "test failed" >&2
    curl -sS -X POST --data-urlencode "payload={\"channel\": \"#development\", \"username\": \"cy-deploy\", \"text\": \"[FAILED] compathy: ${APP_ENV}: test failed\", \"icon_emoji\": \"${SLACK_ICON}\"}" "${SLACK_URL}"
    rmdir ${LOCK_DIR}
    exit 1
  fi

  # AngularJS
  # TODO
}

notify_start() {
  curl -sS -X POST --data-urlencode "payload={\"channel\": \"#development\", \"username\": \"cy-deploy\", \"text\": \"[INFO] compathy: ${APP_ENV}: start\", \"icon_emoji\": \"${SLACK_ICON}\"}" "${SLACK_URL}"
}

notify_fail() {
  curl -sS -X POST --data-urlencode "payload={\"channel\": \"#development\", \"username\": \"cy-deploy\", \"text\": \"[FAILED] compathy: ${APP_ENV}: deploy failed\", \"icon_emoji\": \"${SLACK_ICON}\"}" "${SLACK_URL}"
  cat ${DEPLOY_LOG} | mail -s "[FAILED] compathy: ${APP_ENV}: deploy failed" ${MAILTO}
}

notify_success() {
  curl -sS -X POST --data-urlencode "payload={\"channel\": \"#development\", \"username\": \"cy-deploy\", \"text\": \"[SUCCESS] compathy: ${APP_ENV}: hooray!\", \"icon_emoji\": \"${SLACK_ICON}\"}" "${SLACK_URL}"
}

# /////////////////////////////////
# main

if [ $# -ne 1 ]; then
  echo "USAGE: $0 (conf file)"
  exit 1
fi

source ./$1

echo "`date`: start"

mkdir ${LOCK_DIR} > /dev/null 2>&1 || duplicate_exit

cd ${CI_WORK_DIR}

git co ${CI_WORK_BR} 2>&1
git fetch ${WATCH_REPO} 2>&1

st=`git diff ${WATCH_REPO}/${WATCH_BR}`

if [ -z "${st}" -a "${FORCE_DEPLOY}" != "true" ]; then
  echo "no update"
  rmdir ${LOCK_DIR}
  exit 0
fi

notify_start

git reset --hard ${WATCH_REPO}/${WATCH_BR}

if [ "$APP_ENV" = "staging" ]; then
  run_testcode
fi

echo "find the deploy log at: ${DEPLOY_LOG}"
date > ${DEPLOY_LOG}

make deploy_${APP_ENV} >> ${DEPLOY_LOG} 2>&1

echo "grep ----" >> ${DEPLOY_LOG}
grep -Ev "(Done, without errors.|networkerror.html|better_errors)" ${DEPLOY_LOG} | grep -iE "(error|fatal)" >> ${DEPLOY_LOG}
retval=$?

if [ $retval -eq 0 ]; then
  notify_fail
else
  notify_success
fi

rmdir ${LOCK_DIR}

exit 0

