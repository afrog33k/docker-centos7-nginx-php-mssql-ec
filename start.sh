#!/bin/bash
# SET DEFAULT $PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
    $PROJECT_NAME = "project"
    mkdir -p /$PROJECT_NAME
fi

# GIT
mkdir -p -m 0700 /root/.ssh
# Prevent config files from being filled to infinity by force of stop and restart the container
echo "" > /root/.ssh/config
echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

echo "192.30.253.113 github.com" >> /etc/hosts

if [[ "$GIT_USE_SSH" == "1" ]] ; then
  echo -e "Host *\n\tUser ${GIT_USERNAME}\n\n" >> /root/.ssh/config
fi

if [ ! -z "$SSH_KEY" ]; then
 echo $SSH_KEY > /root/.ssh/id_rsa.base64
 base64 -d /root/.ssh/id_rsa.base64 > /root/.ssh/id_rsa
 chmod 600 /root/.ssh/id_rsa
fi

# Setup git variables
if [ ! -z "$GIT_EMAIL" ]; then
 git config --global user.email "$GIT_EMAIL"
fi
if [ ! -z "$GIT_NAME" ]; then
 git config --global user.name "$GIT_NAME"
 git config --global push.default simple
fi

if [ ! -z "$GIT_REPO" ]; then
    GIT_COMMAND='git clone '
    if [ ! -z "$GIT_BRANCH" ]; then
      GIT_COMMAND=${GIT_COMMAND}" --branch ${GIT_BRANCH}"
    fi

    if [[ "$GIT_USE_SSH" == "1" ]]; then
      GIT_COMMAND=${GIT_COMMAND}" ${GIT_REPO}"
    else
      GIT_COMMAND=${GIT_COMMAND}" https://${GIT_USERNAME}:${GIT_PERSONAL_TOKEN}@${GIT_REPO}"
    fi

    ${GIT_COMMAND} /${PROJECT_NAME} || exit 1
fi

# SETTING NGINX ROOT
sed -i "s|/var/www/html|/$PROJECT_NAME|g" /etc/nginx/sites-available/default.conf

if [[ "$LARAVEL" == "true" ]]; then
  mkdir -p /$PROJECT_NAME/storage
  chmod -R 777 /$PROJECT_NAME/storage
  mkdir -p /$PROJECT_NAME/bootstrap
  chmod -R 777 /$PROJECT_NAME/bootstrap
  mkdir -p /$PROJECT_NAME/storage/sql
  chmod -R 755 /$PROJECT_NAME/storage/sql

  if [ ! -z "$USE_GIT" ]; then
      if [[ "$USE_GIT" == "true" ]]; then
          cp /$PROJECT_NAME/.env.example /$PROJECT_NAME/.env
          sed -i "s|APP_ENV=local|APP_ENV=$APP_ENV|g" /$PROJECT_NAME/.env
          sed -i "s|APP_URL=http://localhost|APP_URL=$DOMAIN|g" /$PROJECT_NAME/.env
          sed -i "s|DB_HOST=127.0.0.1|DB_HOST=$DB_HOST|g" /$PROJECT_NAME/.env
          sed -i "s|DB_PORT=3306|DB_PORT=$DB_PORT|g" /$PROJECT_NAME/.env
          sed -i "s|DB_DATABASE=homestead|DB_DATABASE=$DB_NAME|g" /$PROJECT_NAME/.env
          sed -i "s|DB_USERNAME=homestead|DB_USERNAME=$DB_USERNAME|g" /$PROJECT_NAME/.env
          sed -i "s|DB_PASSWORD=secret|DB_PASSWORD=$DB_PASSWORD|g" /$PROJECT_NAME/.env
          sed -i "s|SESSION_DRIVER=file|SESSION_DRIVER=$SESSION_DRIVER|g" /$PROJECT_NAME/.env
      fi
  fi

  # crontab schedule
  echo "* * * * * cd /$PROJECT_NAME && php artisan schedule:run >> /dev/null 2>&1" >> /etc/crontab

  if [[ "$APP_ENV" == "production" ]]; then
    cd /$PROJECT_NAME && composer install --no-dev --optimize-autoloader
  else
    cd /$PROJECT_NAME && composer install
  fi

  if [ ! -z "$APP_KEY" ]; then
    sed -i "s|APP_KEY=|APP_KEY=$APP_KEY|g" /$PROJECT_NAME/.env
  else
    php artisan key:generate
  fi

fi

systemctl restart php72-php-fpm
systemctl restart supervisord
systemctl restart nginx
