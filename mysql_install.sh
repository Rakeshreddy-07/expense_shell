#!/bin/bash

#colors
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#log file location
timestamp=$(date +%Y-%m-%d-%H:%M:%S)
log_location="/var/log/shellscript_logs"
log_file=$(echo $0 | cut -d "." -f1)
log_file_name="$log_location/$log_file-$timestamp.log"



mkdir -p /var/log/shellscript_logs


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

#Install MySQL Server 8.0.x
dnf list installed mysql
if [ $? -ne 0 ]; then
    dnf install mysql-server -y &>> $log_file_name
    VALIDATE $? "MYSQL installation"
    else
    echo -e "mysql already $Y installed $N"
fi


#Start MySQL Service and enable
systemctl enable mysqld &>> $log_file_name
VALIDATE $? "enabling mysql server"

systemctl restart mysqld &>> $log_file_name
VALIDATE $? "starting mysql server"

systemctl status mysqld &>> $log_file_name

#change the default root password
mysql_secure_installation --set-root-pass ExpenseApp@1 &>> $log_file_name
VALIDATE $? "Password change"


