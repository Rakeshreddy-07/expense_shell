#!/bin/bash

#colors
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#log file location
timestamp=$(date +%Y-%m-%d-%H:%M:%S)
log_location="/var/log/expense_logs"
log_file=$(echo $0 | cut -d "." -f1)
log_file_name="$log_location/$log_file-$timestamp.log"



mkdir -p $log_location


#check user id sudo access to run the script
CHECK_ROOT(){
uid=$(id -u)
    if [ $uid -ne 0 ]; then
        echo "user does not have the required permission to run the script, use sudo access to run the script"
        exit 1
    else
        echo "user has the required permission to run the script, excuting script now"
    fi 
}

#To validate the install process
VALIDATE () {
    if [ $1 -eq 0 ]; then
        echo -e "$2.. $G SUCCESS $N"
    else
        echo -e "$2.. $R FAILURE $N"
        exit 1
    fi    
}

#calling this function to check if sudo access is enabled or not
CHECK_ROOT

dnf module disable nodejs -y &>> $log_file_name
VALIDATE $? "nodejs disable"

dnf module enable nodejs:20 -y &>> $log_file_name
VALIDATE $? "nodejs:20 enable"

dnf install nodejs -y &>> $log_file_name
VALIDATE $? "nodejs install"

awk -F ':' '{ print $1 }' /etc/passwd | grep expense &>> $log_file_name
if [ $? -ne 0 ]; then
    useradd expense &>> $log_file_name
    VALIDATE $? "user add"
else
    echo -e "user already exists.. $Y user creation skipped"
fi

rm -rf /app

mkdir -p /app &>> $log_file_name
VALIDATE $? "creating Directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> $log_file_name

cd /app

unzip /tmp/backend.zip &>> $log_file_name

#install dependencies
cd /app
npm install &>> $log_file_name
VALIDATE $? "install dependencies"

cp /home/ec2-user/backend.txt /etc/systemd/system/backend.service

systemctl daemon-reload &>> $log_file_name
VALIDATE $? "Deamon reload"

systemctl enable backend &>> $log_file_name
VALIDATE $? "enable backend"

systemctl start backend &>> $log_file_name
VALIDATE $? "backend started"

dnf install mysql -y &>> $log_file_name
VALIDATE $? "mysql client install"

#Load Schema
mysql -h mysql.devopsaws82s.online -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "transaction schema creation"

mysql -h mysql.devopsaws82s.online -u root -pExpenseApp@1 -e "show databases;" &>> $log_file_name
VALIDATE $? "check transaction schema"

systemctl restart backend &>> $log_file_name
VALIDATE $? "re-start backend"