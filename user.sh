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

dnf module disable nodejs -y
dnf module enable nodejs:20 -y
VALIDATE $? "Enabling NodeJS"

dnf install nodejs -y
VALIDATE $? "Installing Nodejs"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating System User"
else
    echo -e "Roboshop user already exist...$Y SKIPPING $N"
fi 

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading User code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/* 
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>$LOGS_FILE
VALIDATE $? "Unzip user code"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOGS_FILE
VALIDATE $? "Creating systemctl service"

systemctl daemon-reload
systemctl enable user &>>$LOGS_FILE
systemctl start user
VALIDATE $? "Enabling and starting user"