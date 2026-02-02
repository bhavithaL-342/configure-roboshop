#!/bin/bash

USERID=$(id -u)

LOGS_FOLDER="/var/log/configure-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"          #-e must to enable colour code
Y="\e[33m"
N="\e[0m" #normal

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

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling NodeJS default version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "enabling NodeJS 20"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating System User"

mkdir /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
VALIDATE $? "Downloading Catalogue code"

