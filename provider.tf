
//organization: Sonata software Limited
//developed by: Devops-team
//code :  variables creation
//created on : 20-06-2022


// assigning the credentials,project_ID, region
provider"google"{

    project= var.project
    region= var.region
    credentials = file(var.credentials_file)

}

provider "google-beta"{

    project= var.project
    region= var.region
    credentials = file(var.credentials_file)

}