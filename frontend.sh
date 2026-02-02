#!/bin/bash

USERID=$(id -u)

LOGS_FOLDER="/var/log/configure-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"          #-e must to enable colour code
Y="\e[33m"
N="\e[0m" #normal
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.exploreops.online

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
if [ $1 -ne 0 ]; then 
    echo -e "$2 is $R FAILURE $N" | tee -a $LOGS_FILE #tee -> prints log/output on screen and in log file, -a is append(without override)
else 
    echo -e "$2 is $G SUCCESS $N" | tee -a $LOGS_FILE
fi
}


dnf module disable nginx -y
dnf module enable nginx:1.24 -y
dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOGS_FILE
systemctl start nginx 
VALIDATE $? "Enabling and starting nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOGS_FILE 
VALIDATE $? "Downloaded and Unzipped frontend"

rm -rf /etc/nginx/nginx.conf

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied nginx conf file"

systemctl restart nginx 
VALIDATE $? "Restarted Nginx"
