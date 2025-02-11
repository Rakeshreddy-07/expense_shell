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

dnf list installed nginx
if  [ $? -ne 0 ]; then
    echo "Installing nginx"
    dnf install nginx -y &>> $log_file_name
    VALIDATE $? "nginx install"
else
    echo -e "nginx already installed.. $Y skipping installtion $N"
fi

systemctl enable nginx &>> $log_file_name
VALIDATE $? "nginx enable"

systemctl start nginx &>> $log_file_name
VALIDATE $? "nginx start"

rm -rf /usr/share/nginx/html/*

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>> $log_file_name
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html


unzip /tmp/frontend.zip &>> $log_file_name
VALIDATE $? "copying the forntend code"

cp /home/ec2-user/expense_shell/expense.txt /etc/nginx/default.d/expense.conf

systemctl restart nginx &>> $log_file_name
VALIDATE $? "nginx restart"