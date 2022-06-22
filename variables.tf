//organization: Sonata software Limited
//developed by: Devops-team
//code :  variables creation
//created on : 20-06-2022


//creating variable for project
variable "project"{
    default="tokyo-dynamo-349216"
}
//creating a variable for region
variable "region"{
    default="us-central1"
}

//creating a variable for credentials_file
variable "credentials_file"{
       
       default="jenkinsgcp.json"
}

//creating a variable for sql_db name
variable "sql_db_name"{
    default="mysql-8-db-1"
}

//creating a variable for sql_db_instance
variable "sql_db_instance_name"{
    default="mysql-db-instance-1"
}