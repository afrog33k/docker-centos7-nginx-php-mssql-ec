# Docker - CentOS7 - nginx - php(Laravel)

## Overview

快速架起 docker with php & nginx

使用 PHP 7.2、CentOS、原始安裝 nginx

包括 mount nginx 和 sql log 到 host 和 mssql

參數帶入正確，clone 完即可快速架起 Laravel 專案

### ENV Parameters
```
ENV PROJECT_NAME=project_name
ENV APP_ENV=local

# ENV GITPROJECT
$GIT_USE_SSH = 1 // GIT 使用 ssh
$GIT_REPO // GIT SSH or HTTP url
$GIT_PERSONAL_TOKEN // GIT HTTP CLONE 時可用 token
$GIT_BRANCH // git clone 的 branch
$GIT_USERNAME // GIT 帳號
$GIT_EMAIL // GIT EMAIL
$GIT_NAME // GIT NAME

$SSH_KEY // SSH KEY

# ENV DOMAIN INFO
ENV DOMAIN=null

# ENV DATABASE INFO
ENV DB_HOST=null
ENV DB_PORT=null
ENV DB_NAME=null
ENV DB_USERNAME=null
ENV DB_PASSWORD=null
```

### BUILD
```
sudo docker build -t defsrisars/centos7-nginx-php:php-7.2.17 --no-cache .
```

#### RUN
--net project-network 為自訂 docker network (選用)

mount
```
sudo docker run -d --name project \
--restart always -p 8888:80 \
--cap-add=SYS_ADMIN \
-v /sys/fs/cgroup:/sys/fs/cgroup \
-v /home/code/project:/file-server-backend \
-v /home/user/laravel-test/logs/nginx:/var/log/nginx \ 
-v /home/user/laravel-test/db:/var/log/sql \
-e "PROJECT_NAME=laravel-test" \
-e "APP_ENV=local" \
-e "DB_HOST=localhost" \
-e "DB_PORT=3306" \
-e "DB_NAME=localhost" \
-e "DB_USERNAME=root" \
-e "DB_PASSWORD=root" \
-e "DOMAIN=localhost" \
--net project-network \
defsrisars/centos7-nginx-php:php-7.2.17
```

git
```
sudo docker run -d --name project \
--restart always -p 8888:80 \
--cap-add=SYS_ADMIN \
-v /sys/fs/cgroup:/sys/fs/cgroup \
-v /home/user/laravel-test/logs/nginx:/var/log/nginx \
-v /home/user/laravel-test/db:/var/log/sql \
-e "USE_GIT=true" \
-e "GIT_REPO=github.com/defsrisars/laravel-test.git" \
-e "GIT_PERSONAL_TOKEN=..." \
-e "GIT_USERNAME=defsrisars" \
-e "GIT_EMAIL=defsrisars@gmail.com" \
-e "GIT_NAME=defsrisars" \
-e "PROJECT_NAME=laravel-test" \
-e "APP_ENV=local" \
-e "BRANCH_NAME=master" \
-e "DB_HOST=localhost" \
-e "DB_PORT=3306" \
-e "DB_NAME=localhost" \
-e "DB_USERNAME=root" \
-e "DB_PASSWORD=root" \
-e "DOMAIN=localhost" \
--net project-network \
defsrisars/centos7-nginx-php:php-7.2.17
```



#### Run 起來後需執行 
目前因為 CentOS 需要執行 `/usr/sbin/init` 啟動 systemctl，因為不想開 --privileged ，故目前啟動後需手動執行
```
sh /start.sh
```
