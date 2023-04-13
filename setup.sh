#!/bin/bash

# description: This script creates a new Azure DevOps project and repository using the Azure DevOps CLI. 
#              It also adds users to the organization and project, and creates a new repository.
# author: Ivan Porta
# date: 2021-05-18

function out {
    case "$1" in
        success)
            echo -e "\033[32m${@:2}\033[0m"
            ;;
        warning)
            echo -e "\033[33m${@:2}\033[0m"
            ;;
        error)
            echo -e "\033[31m${@:2}\033[0m"
            ;;
        *)
            echo "${@:1}"
            ;;
    esac
}
function authenticate_to_azure_devops {
    local ORG_NAME=$1
    out "Authenticating to Azure DevOps"
    az devops login --organization https://dev.azure.com/$ORG_NAME --verbose
    if [ $? -eq 0 ]; then
        out success "Authentication to Azure DevOps successfull"
    else
        out error "Authentication to Azure DevOps failed"
        exit 1
    fi
}
function add_users_to_organization {
    local ORG_NAME=$1
    local DEFAULT_JSON=$2
    out "Adding users to $ORG_NAME organization"
    for USER in $(echo "$DEFAULT_JSON" | jq -r '.organization.users[] | @base64'); do
        USER_JSON=$(echo "$USER" | base64 --decode | jq -r '.')
        NAME=$(echo "$USER_JSON" | jq -r '.name')
        EMAIL=$(echo "$USER_JSON" | jq -r '.email')
        out "Checking if user $NAME ($EMAIL) is already a member of $ORG_NAME organization"
        RESPONSE=$(az devops user show --user $EMAIL --organization "https://dev.azure.com/$ORG_NAME")
        if [ -z "$RESPONSE" ]; then
            out success "User $NAME ($EMAIL) is not a member of $ORG_NAME organization"
        else
            out warning  "User $NAME ($EMAIL) is already a member of $ORG_NAME organization. Skipping..."
            continue
        fi
        out "Adding user $NAME ($EMAIL) to $ORG organization"
        az devops user add --email-id "$EMAIL" --license-type "express" --send-email-invite false --organization "https://dev.azure.com/$ORG_NAME" --verbose
        if [ $? -eq 0 ]; then
            out success "User $NAME ($EMAIL) was added to $ORG_NAME organization"
        else
            out error "User $NAME ($EMAIL) was not added to $ORG_NAME organization"
            exit 1
        fi
    done
}
function install_extensions_in_organization {
    local ORG_NAME=$1
    local DEFAULT_JSON=$2
    out "Installing extensions in the $ORG_NAME organization"
    for EXRENSION in $(echo "$DEFAULT_JSON" | jq -r '.organization.extensions[] | @base64'); do
        EXRENSION_JSON=$(echo "$EXRENSION" | base64 --decode | jq -r '.')
        ID=$(echo "$EXRENSION_JSON" | jq -r '.id')
        PUBLISHER_ID=$(echo "$EXRENSION_JSON" | jq -r '.publisher_id')
        out "Checking if $ID extension is already installed"
        RESPONSE=$(az devops extension show --extension-id "$ID" --publisher-id "$PUBLISHER_ID" --organization "https://dev.azure.com/$ORG_NAME")
        if [ -z "$RESPONSE" ]; then
            out "$ID is not installed"
        else
            out warning "$ID is already installed. Skipping..."
            continue
        fi
        out "Installing $ID extension in $ORG_NAME organization"
        az devops extension install --extension-id "$ID" --publisher-id "$PUBLISHER_ID" --organization "https://dev.azure.com/$ORG_NAME" --verbose
        if [ $? -eq 0 ]; then
            out success "Extension $ID was installed to $ORG_NAME organization"
        else
            out error "Extension $ID was not installed to $ORG_NAME organization"
            exit 1
        fi
    done
}
function create_project {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Checking if $PROJECT_NAME project already exists"
    RESPONSE=$(az devops project show --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME")
    if [ -z "$RESPONSE" ]; then
        out "$PROJECT_NAME project does not exist"
    else
        out warning "Project $PROJECT_NAME already exists. Skipping..."
        return 1
    fi
    out "Creating $PROJECT_NAME project"
    az devops project create --name "$PROJECT_NAME" --description "Scrum project" --detect false --org "https://dev.azure.com/$ORG_NAME" --process scrum --source-control git --visibility private --verbose
    if [ $? -eq 0 ]; then
        out success "$PROJECT_NAME project created successfully"
    else
        out error "Failed to create $PROJECT_NAME project"
        exit 1
    fi
}
function create_security_groups {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Creating security groups in the $PROJECT_NAME project"
    for SECURITY_GROUP in $(echo "$DEFAULT_JSON" | jq -r '.organization.project.security_groups[] | @base64'); do
        SECURITY_GROUP_JSON=$(echo "$SECURITY_GROUP" | base64 --decode | jq -r '.')
        NAME=$(echo "$SECURITY_GROUP_JSON" | jq -r '.name')
        DESCRIPTION=$(echo "$SECURITY_GROUP_JSON" | jq -r '.description')
        out "Checking if $NAME security group already exists"
        RESPONSE=$(az devops security group show --name "$NAME" --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME")
        if [ -z "$RESPONSE" ]; then
            out "$NAME security group does not exist"
        else
            out warning "$NAME security group already exists. Skipping..."
            continue
        fi
        out "Creating $NAME security group in $PROJECT_NAME project"
        az devops security group create --name "$NAME" --description "$DESCRIPTION" --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME" --scope project --verbose
        if [ $? -eq 0 ]; then
            out success "User $NAME ($EMAIL) was added to $ORG_NAME organization"
        else
            out error "User $NAME ($EMAIL) was not added to $ORG_NAME organization"
            exit 1
        fi
    done
}
function create_repositories {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Creating repositories in $PROJECT_NAME project"
    for REPO in $(echo "$DEFAULT_JSON" | jq -r '.repository.repositories[] | @base64'); do
        REPO_JSON=$(echo "$REPO" | base64 --decode | jq -r '.')
        REPO_NAME=$(echo "$REPO_JSON" | jq -r '.name')
        out "Checking if $REPO_NAME repository already exists"
        RESPONSE=$(az repos show --repository "$REPO_NAME" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME")
        if [ -z "$RESPONSE" ]; then
            out "$REPO_NAME repository does not exist"
        else
            out warning "$REPO_NAME repository already exists. Skipping..."
            continue
        fi
        out "Creating $REPO_NAME repository..."
        az repos create --name "$REPO_NAME" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME" --verbose
        if [ $? -eq 0 ]; then
            out success "$REPO_NAME repository created successfully"
        else
            out error "Failed to create $REPO_NAME repository"
            exit 1
        fi
        out "Cloning $REPO_NAME repository..."
        git clone https://$PAT@dev.azure.com/$ORG_NAME/$PROJECT_NAME/_git/$REPO_NAME
        cd $REPO_NAME
        out "Configuring local git user"
        git config user.email "you@example.com"
        git config user.name "Your Name"
        out "Creating initial commit"
        out "# $REPO_NAME" > README.md
        git add README.md
        git commit -m "Initial commit"
        out "Pushing initial commit to $REPO_NAME repository"
        git push origin master
        for BRANCH in $(echo "$DEFAULT_JSON" | jq -r '.repository.branches[] | @base64'); do
            BRANCH_JSON=$(echo "$BRANCH" | base64 --decode | jq -r '.')
            BRANCH_NAME=$(echo "$BRANCH_JSON" | jq -r '.name')
            out "Checking if $BRANCH_NAME branch already exists"
            RESPONSE=$(git branch -a | grep $BRANCH_NAME)
            if [ -z "$RESPONSE" ]; then
                out "creating $BRANCH_NAME branch"
                git checkout -b $BRANCH_NAME
                git push origin $BRANCH_NAME
            else
                out warning "$BRANCH_NAME branch already exists. Skipping..."
                continue
            fi
        done
        cd ..
        out "Deleting local repository"
        rm -R $REPO_NAME
    done
}
function delete_repository {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local REPO_NAME=$3
    local DEFAULT_JSON=$4
    out "Checking if $REPO_NAME repository already exists"
    REPO_ID=$(az repos list --project "$PROJECT_NAME" --query "[?name=='$REPO_NAME'].id" --organization "https://dev.azure.com/$ORG_NAME" --output tsv)
    if [ ! -z "$REPO_ID" ]; then
        out "Repository $REPO_NAME found"
    else
        out warning "Repository $REPO_NAME not found. Skipping..."
        return 1
    fi  
    out "Deleting $REPO_NAME repository"
    az repos delete --id "$REPO_ID" --project "$REPO_NAME" --organization "https://dev.azure.com/$ORG_NAME" --yes --verbose
    if [ $? -eq 0 ]; then
        out success "$REPO_NAME repository created successfully"
    else
        out error "Failed to create $REPO_NAME repository"
        exit 1
    fi
}
function create_work_items {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Creating work items in $PROJECT_NAME project"
    for EPIC in $(echo "$DEFAULT_JSON" | jq -r '.board.epics[] | @base64'); do
        EPIC_JSON=$(echo "$EPIC" | base64 --decode | jq -r '.')
        TITLE=$(echo "$EPIC_JSON" | jq -r '.title')
        DESCRIPTION=$(echo "$EPIC_JSON" | jq -r '.description')
        out "Creating $TITLE epic"
        EPIC_ID=$(az boards work-item create --type "Epic" --title "$TITLE" --description "$DESCRIPTION" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME" | jq -r '.id')
        for FEATURE in $(echo "$EPIC_JSON" | jq -r '.features[] | @base64'); do
            FEATURE_JSON=$(echo "$FEATURE" | base64 --decode | jq -r '.')
            TITLE=$(echo "$FEATURE_JSON" | jq -r '.title')
            DESCRIPTION=$(echo "$FEATURE_JSON" | jq -r '.description')
            out "Creating $TITLE feature"
            FEATURE_ID=$(az boards work-item create --type "Feature" --title "$TITLE" --description "$DESCRIPTION" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME" | jq -r '.id')
            out "Link feature to epic"
            az boards work-item relation add --id "$FEATURE_ID" --target-id "$EPIC_ID" --relation-type "Parent" --detect false --org "https://dev.azure.com/$ORG_NAME"      
            for PRODUCT_BACKLOG_ITEM in $(echo "$FEATURE_JSON" | jq -r '.product_backlog_items[] | @base64'); do
            PRODUCT_BACKLOG_ITEM_JSON=$(echo "$PRODUCT_BACKLOG_ITEM" | base64 --decode | jq -r '.')
            TITLE=$(echo "$PRODUCT_BACKLOG_ITEM_JSON" | jq -r '.title')
            DESCRIPTION=$(echo "$PRODUCT_BACKLOG_ITEM_JSON" | jq -r '.description')
            out "Creating $TITLE product backlog item"
            PRODUCT_BACKLOG_ITEM_ID=$(az boards work-item create --type "Product Backlog Item" --title "$TITLE" --description "$DESCRIPTION" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME" | jq -r '.id')
            out "Link product backlog item to feature"
            az boards work-item relation add --id "$PRODUCT_BACKLOG_ITEM_ID" --target-id "$FEATURE_ID" --relation-type "Parent" --detect false --org "https://dev.azure.com/$ORG_NAME"
                for TASK in $(echo "$PRODUCT_BACKLOG_ITEM_JSON" | jq -r '.tasks[] | @base64'); do
                    TASK_JSON=$(echo "$TASK" | base64 --decode | jq -r '.')
                    TITLE=$(echo "$TASK_JSON" | jq -r '.title')
                    TASK_ID=$(az boards work-item create --type "Task" --title "$TITLE" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME" | jq -r '.id')
                    out "Link task to product backlog item"
                    az boards work-item relation add --id "$TASK_ID" --target-id "$PRODUCT_BACKLOG_ITEM_ID" --relation-type "Parent" --detect false --org "https://dev.azure.com/$ORG_NAME"
                done
            done
        done
    done
}
function create_pipeline_environments {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Creating environments in $PROJECT_NAME project"
    for ENVIRONMENT in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.environments[] | @base64'); do
        ENVIRONMENT_JSON=$(echo "$ENVIRONMENT" | base64 --decode | jq -r '.')
        NAME=$(echo "$ENVIRONMENT_JSON" | jq -r '.name')
        DESCRIPTION=$(echo "$ENVIRONMENT_JSON" | jq -r '.description')
        RESPONSE=$(curl --silent \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1")
        if [[ $(echo "$RESPONSE" | jq '.value[] | select(.name == "'"$NAME"'") | length') -gt 0 ]]; then
            out warning "$NAME environment already exists. Skipping..."
            continue
        else
            out "$NAME environment does not exist"
        fi
        out "Creating $NAME environment..."
        RESPONSE=$(curl --silent \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            --data-raw '{"name": "'"$NAME"'","description": "'"$DESCRIPTION"'"}' \
            "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1")
        if [ "$RESPONSE" == "200" ]; then
            out success "Environment $NAME succesfully created"
        else
            out error "Failed to create $NAME environment. $RESPONSE"
        fi
    done
}
function create_pipeline_variable_groups {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Creating variable group in $PROJECT_NAME project"
    for VARIABLE_GROUPS in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.variable_groups[] | @base64'); do
        VARIABLE_GROUPS_JSON=$(echo "$VARIABLE_GROUPS" | base64 --decode | jq -r '.')
        NAME=$(echo "$VARIABLE_GROUPS_JSON" | jq -r '.name')
        DESCRIPTION=$(echo "$VARIABLE_GROUPS_JSON" | jq -r '.description')
        VARIABLE_PARAMETER=""
        for VARIABLE in $(echo "$VARIABLE_GROUPS_JSON" | jq -r '.variables[] | @base64'); do
            KEY=$(echo "$VARIABLE" | base64 --decode | jq -r '.key')
            VALUE=$(echo "$VARIABLE" | base64 --decode | jq -r '.value')
            VARIABLE_PARAMETER="$VARIABLE_PARAMETER ${KEY}=${VALUE}"
        done
        out "Checking if $NAME variable group already exists"
        GROUP_ID=$(az pipelines variable-group list --organization "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME" --output json | jq -r '.[] | select(.name == "'"$NAME"'") | .id')
        if [ -n "$GROUP_ID" ]; then
            out warning "Variable group $NAME already exists with ID $GROUP_ID. Skipping..."
            continue
        else
            out "Variable group $NAME does not exist"
        fi
        out "Creating $NAME variable group..."
        az pipelines variable-group create --name "$NAME" --description "$DESCRIPTION" --variables $VARIABLE_PARAMETER --organization "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME" --verbose
        if [ $? -eq 0 ]; then
            out success "$NAME variable group created successfully"
        else
            out error "Failed to create $NAME variable group"
            exit 1
        fi
    done
}
function create_pipeline_pipelines {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Creating pipelines in $PROJECT_NAME project"
    for PIPELINE in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.pipelines[] | @base64'); do
        PIPELINE_JSON=$(echo "$PIPELINE" | base64 --decode | jq -r '.')
        NAME=$(echo "$PIPELINE_JSON" | jq -r '.name')
        REPO_NAME=$(echo "$PIPELINE_JSON" | jq -r '.repository_name')
        out "Checking if $NAME pipeline already exists"
        RESPONSE=$(az pipelines show --name "$NAME" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME")
        if [ -z "$RESPONSE" ]; then
            out "$NAME piepline does not exist"
        else
            out warning "$NAME piepline already exists. Skipping..."
            continue
        fi
        out "Creating $NAME pipeline..."
        # Currently the module is broken and there is a prioroty one to fix it.
        # https://github.com/MicrosoftDocs/azure-devops-docs/issues/13016
        # az pipelines create --name "$NAME" --description "$NAME pipeline" --repository "$REPO_NAME" --branch master --repository-type tfsgit --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME" --skip-first-run --debug
        # if [ $? -eq 0 ]; then
        #     echo "$NAME pipeline created successfully"
        # else
        #     echo "Failed to create $NAME pipeline"
        #     exit 1
        # fi
        # curl --silent \
        #     --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        #     --header "Content-Type: application/json" \
        #     --data-raw '{"configuration": {"repository": {"url": "'"https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_git/$REPO_NAME"'", "type": "azureReposGit", "name": "default"}},"folderPath": "/","name": "'"$NAME"'","type": "yaml","queueId": 2}' \
        #     "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/pipelines?api-version=7.0" 
        # curl --silent -v \
        #     --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        #     --header "Content-Type: application/json" \
        #     --data-raw '{"configuration": {"type": "yaml"},"folder": "/","name": "'"$NAME"'"}' \
        #     "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/pipelines?api-version=7.0" 
    done
}
function assing_security_groups_to_environments {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Assign security groups to environments in $PROJECT_NAME project"
    for ENVIRONMENT in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.environments[] | @base64'); do
        ENVIRONMENT_JSON=$(echo "$ENVIRONMENT" | base64 --decode | jq -r '.')
        ENVIRONMENT_NAME=$(echo "$ENVIRONMENT_JSON" | jq -r '.name')
        out "Get project ID by $PROJECT_NAME"
        PROJECT_ID=$(az devops project show --project $PROJECT_NAME | jq -r '.id')
         if [ $? -eq 0 ]; then
            out success "The ID of the $PROJECT_NAME project is $PROJECT_ID"
        else
            out error "Error during the reading of the property ID of the $PROJECT_ID"
            exit 1
        fi
        for SECURITY_GROUP in $(echo "${ENVIRONMENT_JSON}" | jq -r '.security_groups_name[] | @base64'); do
            SECURITY_GROUP_JSON=$(echo "${SECURITY_GROUP}" | base64 --decode)
            NAME=$(echo "${SECURITY_GROUP_JSON}" | jq -r '.name')
            ROLE=$(echo "${SECURITY_GROUP_JSON}" | jq -r '.role_name')
            out "Get security group ID for $NAME"
            SECURITY_GROUP_ID=$(az devops security group list --project $PROJECT_NAME --org https://dev.azure.com/$ORG_NAME --output json | jq -r '.graphGroups[] | select(.displayName == "'"$NAME"'") | .originId')
            if [ $? -eq 0 ]; then
                out success "The ID of the $NAME security group is $SECURITY_GROUP_ID"
            else
                out error "Error during the reading of the property ID of the $NAME security group"
                exit 1
            fi
            echo "Get evnironment ID by $ENVIRONMENT_NAME"
            RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            if [ $HTTP_STATUS != 200 ]; then
                out error "Failed to get the $NAME environment ID. $RESPONSE"
                exit 1;
            else
                out success "The ID of the $ENVIRONMENT_NAME environment was succesfully retrieved"
            fi
            ENVIRONMENT_ID=$(echo "$RESPONSE_BODY" | jq '.value[] | select(.name == "'"$ENVIRONMENT_NAME"'") | .id' | tr -d '"')  
            RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --request PUT \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '[{"roleName": "'"$ROLE"'","userId": "'"$SECURITY_GROUP_ID"'"}]' \
                "https://dev.azure.com/$ORG_NAME/_apis/securityroles/scopes/distributedtask.environmentreferencerole/roleassignments/resources/$PROJECT_ID"_"$ENVIRONMENT_ID?api-version=5.0-preview.1")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            out "Response body: $RESPONSE_BODY"
            if [ $HTTP_STATUS != 200 ]; then
                out error "Failed to associate the $NAME security group to the $ENVIRONMENT_NAME environment. $RESPONSE"
                exit 1;
            else
                out success "The $NAME security group was successfully associated to the $ENVIRONMENT_NAME environment"
            fi
        done
    done
}
function create_service_endpoints {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Create service endpoints in $PROJECT_NAME project"
    out "Read organization ID. This property is needed to get a list of service endpoints"
    RESPONSE=$(curl --silent \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            --data-raw '{"contributionIds": ["ms.vss-features.my-organizations-data-provider"],"dataProviderContext":{"properties":{}}}' \
            "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    if [ $HTTP_STATUS != 200 ]; then
        out error "Failed to get the list of existing service endpoints. $RESPONSE"
        exit 1;
    else
        out success "The list of existing service endpoints was succesfully retrieved"
    fi
    ORG_ID=$(echo "$RESPONSE_BODY" | jq '.dataProviders."ms.vss-features.my-organizations-data-provider".organizations[] | select(.name == "'"$ORG_NAME"'") | .id' | tr -d '"')
    out "The ID of the $ORG_NAME organization is $ORG_ID"
    out "Read the list of existing service endpoints"
    RESPONSE=$(curl --silent \
            --request POST \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            --data-raw '{"contributionIds":["ms.vss-distributed-task.resources-hub-query-data-provider"],"dataProviderContext":{"properties":{"resourceFilters":{"createdBy":[],"resourceType":[],"searchText":""},"sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/adminservices","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"Sample","adminPivot":"adminservices","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
            "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    SERVICE_ENDPOINT_LIST_RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    if [ $HTTP_STATUS != 200 ]; then
        out error "Failed to get the list of existing service endpoints. $RESPONSE"
        exit 1;
    else
        out success "The list of existing service endpoints was succesfully retrieved"
    fi
    out $SERVICE_ENDPOINT_LIST_RESPONSE_BODY
    for SERVICE_ENDPOINT in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.service_endpoints[] | @base64'); do
        SERVICE_ENDPOINT_JSON=$(echo "$SERVICE_ENDPOINT" | base64 --decode | jq -r '.')
        out "Creating Azure service endpoint"
        for AZURE_SERVICE_ENDPOINT in $(echo "$SERVICE_ENDPOINT_JSON" | jq -r '.azurerm[] | @base64'); do
            AZURE_SERVICE_ENDPOINT_JSON=$(echo "$AZURE_SERVICE_ENDPOINT" | base64 --decode | jq -r '.')
            NAME=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.name')
            TENANT_ID=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.tenant_id')
            SUBSCRIPTION_ID=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.subscription_id')
            SUBSCRIPTION_NAME=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.subscription_name')
            SERVICE_PRINCIPAL_ID=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.service_principal_id')
            # AZURE_SERVICE_CONNECTION_SERVICE_PRINCIPAL_KEY=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.service_principal_key')
            out "Checking if $NAME service endpoint already exists"      
            if [ $(echo "$SERVICE_ENDPOINT_LIST_RESPONSE_BODY" | jq '.dataProviders."ms.vss-distributed-task.resources-hub-query-data-provider".resourceItems[] | select(.name == "'"$NAME"'") | length') -gt 0 ]; then
                out "$NAME service endpoint already exists. Skipping..."
                continue
            else
                out "$NAME service endpoint does not exist."
            fi
            out "Creating $NAME service endpoint"
            RESPONSE=$(az devops service-endpoint azurerm create --azure-rm-service-principal-id "$SERVICE_PRINCIPAL_ID" --azure-rm-subscription-id "$SUBSCRIPTION_ID" --azure-rm-subscription-name "$SUBSCRIPTION_NAME" --azure-rm-tenant-id "$TENANT_ID" --name "$NAME" --organization "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME" --output json)
            if [ $? -eq 0 ]; then
                out success "The $NAME service endpoint was successfully created"
            else
                out error "Error during the creation of the $NAME service endpoint"
                exit 1
            fi
        done
        for GITHUB_SERVICE_ENDPOINT in $(echo "$SERVICE_ENDPOINT_JSON" | jq -r '.github[] | @base64'); do
            GITHUB_SERVICE_ENDPOINT_JSON=$(echo "$GITHUB_SERVICE_ENDPOINT" | base64 --decode | jq -r '.')
            NAME=$(echo "$GITHUB_SERVICE_ENDPOINT_JSON" | jq -r '.name')
            URL=$(echo "$GITHUB_SERVICE_ENDPOINT_JSON" | jq -r '.url')
            # AZURE_DEVOPS_EXT_GITHUB_PAT=$(echo "$GITHUB_SERVICE_ENDPOINT_JSON" | jq -r '.token')
            out "Checking if $NAME service endpoint already exists"  
            if [[ $(echo "$SERVICE_ENDPOINT_LIST_RESPONSE_BODY" | jq '.dataProviders."ms.vss-distributed-task.resources-hub-query-data-provider".resourceItems[] | select(.name == "'"$NAME"'") | length') -gt 0 ]]; then
                out "$NAME service endpoint already exists. Skipping..."
                continue
            else
                out "$NAME service endpoint does not exist."
            fi
            out "Creating $NAME service endpoint"
            RESPONSE=$(az devops service-endpoint github create --github-url "$URL" --name "$NAME" --organization "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME" --output json)
            if [ $? -eq 0 ]; then
                out success "The $NAME service endpoint was successfully created"
            else
                out error "Error during the creation of the $NAME service endpoint"
                exit 1
            fi
        done
    done
}
function create_agent_pools {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    out "Creating agent pools in $PROJECT_NAME project"
    out "Read organization ID by $ORG_NAME. This property is needed to get a list of service endpoints"
    RESPONSE=$(curl --silent \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            --data-raw '{"contributionIds": ["ms.vss-features.my-organizations-data-provider"],"dataProviderContext":{"properties":{}}}' \
            "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    if [ $HTTP_STATUS != 200 ]; then
        out error "Failed to get the list of existing service endpoints. $RESPONSE"
        exit 1;
    else
        out success "The list of existing service endpoints was succesfully retrieved"
    fi
    ORG_ID=$(echo "$RESPONSE_BODY" | jq '.dataProviders."ms.vss-features.my-organizations-data-provider".organizations[] | select(.name == "'"$ORG_NAME"'") | .id' | tr -d '"')
    out "The ID of the $ORG_NAME organization is $ORG_ID"
    out "Get project ID by $PROJECT_NAME"
    PROJECT_ID=$(az devops project show --project $PROJECT_NAME | jq -r '.id')
    if [ $? -eq 0 ]; then
        out success "The ID of the $PROJECT_NAME project is $PROJECT_ID"
    else
        out error "Error during the reading of the property ID of the $PROJECT_ID"
        exit 1
    fi
    out "Get the list of agent pools"
    RESPONSE=$(curl --silent \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/queues?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    AGENT_POOL_LIST_RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    if [ $HTTP_STATUS != 200 ]; then
        out error "Failed to get the list of existing pools. $RESPONSE"
        exit 1;
    else
        out success "The list of existing pools was succesfully retrieved"
    fi
    for AGENT_POOL in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.agent_pools[] | @base64'); do
        AGENT_POOL_JSON=$(echo "$AGENT_POOL" | base64 --decode | jq -r '.')
        out "Creating self-hosted agents"
        for SELF_HOSTED_AGENT_POOL in $(echo "$AGENT_POOL_JSON" | jq -r '.self_hosted[] | @base64'); do
            SELF_HOSTED_AGENT_POOL_JSON=$(echo "$SELF_HOSTED_AGENT_POOL" | base64 --decode | jq -r '.')
            NAME=$(echo "$SELF_HOSTED_AGENT_POOL_JSON" | jq -r '.name')
            AUTH_PIPELINES=$(echo "$AGENT_POOL_JSON" | jq -r '.authorize_pipelines')
            out "Check if the $NAME agent pool already exists"
            if [[ $(echo "$AGENT_POOL_LIST_RESPONSE_BODY" | jq '.value[] | select(.name == "'"$NAME"'") | length') -gt 0 ]]; then
                out warning "$NAME agent pool already exists. Skipping..."
                continue
            else
                out "$NAME agent pool does not exist."
            fi
            echo "Create $NAME self-hosted agent pool"
            RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"name": "'"$NAME"'"}' \
                "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/queues?authorizePipelines=$AUTH_PIPELINES&api-version=5.0-preview.1")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            if [ $HTTP_STATUS != 200 ]; then
                out error "Failed to create the $NAME agent pool. $RESPONSE"
                exit 1;
            else
                out success "The $NAME agent pool was successfully created"
            fi
        done
        out "Creating azure virtual machine scale set agents"
        for AZURE_HOSTED_AGENT_POOL in $(echo "$AGENT_POOL_JSON" | jq -r '.azure_virtual_machine_scale_sets[] | @base64'); do
            AZURE_HOSTED_AGENT_POOL_JSON=$(echo "$AZURE_HOSTED_AGENT_POOL" | base64 --decode | jq -r '.')
            NAME=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.name')
            AUTH_PIPELINES=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.authorize_pipelines')
            SERVICE_ENDPOINT_NAME=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.service_endpoint_name')
            AUTO_PROVISIONING_PROJECT_POOLS=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.auto_provision_project_pools')
            AZURE_RESOURCE_GROUP_NAME=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.azure_resource_group_name')
            AZURE_VIRTUAL_MACHINE_SCALE_SET_NAME=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.azure_virtual_machine_scale_set_name')
            DESIRED_IDLE=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.desired_idle')
            MAX_CAPACITY=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.max_capacity')
            OS_TYPE=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.os_type')
            MAX_SAVED_NODE_COUNT=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.max_saved_node_count')
            RECYCLE_AFTER_EACH_USE=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.recycle_after_each_use')
            TIME_TO_LIVE_MINUTES=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.time_to_live_minutes')
            out "Check if the $NAME agent pool already exists"
            if [[ $(echo "$AGENT_POOL_LIST_RESPONSE_BODY" | jq '.value[] | select(.name == "'"$NAME"'") | length') -gt 0 ]]; then
                out warning "$NAME agent pool already exists. Skipping..."
                continue
            else
                out "$NAME agent pool does not exist."
            fi
            out "Read the list of existing service endpoints. Needed to configure the VMSS."
            RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                "https://dev.azure.com/$ORG_NAME/$PROJECT_ID/_apis/serviceendpoint/endpoints?type=azurerm&api-version=6.0-preview.4")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            echo $RESPONSE_BODY
            if [ $HTTP_STATUS != 200 ]; then
                out error "Failed to get the list of existing service endpoints. $RESPONSE"
                exit 1;
            else
                out success "The list of existing service endpoints was succesfully retrieved"
            fi
            SERVICE_ENDPOINT=$(echo "$RESPONSE_BODY" | jq -r '.value[] | select(.name == "'"$SERVICE_ENDPOINT_NAME"'")')
            SERVICE_ENDPOINT_ID=$(echo "$SERVICE_ENDPOINT" | jq -r '.id')
            SERVICE_ENDPOINT_TENANT_ID=$(echo "$SERVICE_ENDPOINT" | jq -r '.authorization.parameters.tenantid')
            SERVICE_ENDPOINT_SCOPE=$(echo "$SERVICE_ENDPOINT" | jq -r '.serviceEndpointProjectReferences[] | select(.projectReference.name == "'"$PROJECT_NAME"'") | .projectReference.id')
            SERVICE_ENDPOINT_SUBSCRIPTION_ID=$(echo "$SERVICE_ENDPOINT" | jq -r '.data.subscriptionId')
            echo "Create $NAME virtual machine scale set agent pool"
            RESPONSE=$(curl --silent \
                --request POST \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"agentInteractiveUI":false,"azureId":"/subscriptions/'$SERVICE_ENDPOINT_SUBSCRIPTION_ID'/resourceGroups/'$AZURE_RESOURCE_GROUP_NAME'/providers/Microsoft.Compute/virtualMachineScaleSets/'$AZURE_VIRTUAL_MACHINE_SCALE_SET_NAME'","desiredIdle":'$DESIRED_IDLE',"maxCapacity":'$MAX_CAPACITY',"osType":'$OS_TYPE',"maxSavedNodeCount":'$MAX_SAVED_NODE_COUNT',"recycleAfterEachUse":'$RECYCLE_AFTER_EACH_USE',"serviceEndpointId":"'$SERVICE_ENDPOINT_ID'","serviceEndpointScope":"'$SERVICE_ENDPOINT_SCOPE'","timeToLiveMinutes":'$TIME_TO_LIVE_MINUTES'}' \
                "https://dev.azure.com/$ORG_NAME/_apis/distributedtask/elasticpools?poolName=$NAME&authorizeAllPipelines=$AUTH_PIPELINES&autoProvisionProjectPools=$AUTO_PROVISIONING_PROJECT_POOLS&projectId=$PROJECT_ID&api-version=6.1-preview.1")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            if [ $HTTP_STATUS != 200 ]; then
                out error "Failed to create the $NAME agent pool. $RESPONSE"
                exit 1;
            else
                out success "The $NAME agent pool was successfully created"
            fi
        done
    done 
}


# TODO
# VERBOSE=false
# for arg in "$@"; do
#     if [[ "$arg" == "--verbose" ]]; then
#         echo "set to true"
#         VERBOSE=true
#         echo $VERBOSE
#         break
#     fi
#     echo $VERBOSE
# done

PAT=""
# export AZURE_DEVOPS_EXT_PAT=$PAT
DEFAULT_JSON=$(cat config.json)
ORG_NAME=$(echo "$DEFAULT_JSON" | jq -r '.organization.name')
# authenticate_to_azure_devops $ORG_NAME
# add_users_to_organization $ORG_NAME "$DEFAULT_JSON"
# install_extensions_in_organization $ORG_NAME "$DEFAULT_JSON"
PROJECT_NAME=$(echo "$DEFAULT_JSON" | jq -r '.organization.project.name')
# create_project $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
# create_security_groups $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON" # To fix
# create_repositories $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
# delete_repository $ORG_NAME $PROJECT_NAME $PROJECT_NAME "$DEFAULT_JSON"
# create_work_items $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON" # Add check if the workitem exists
# create_pipeline_environments $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
# create_pipeline_pipelines $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
# assing_security_groups_to_environments $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
# create_service_endpoints $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
# create_agent_pools $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"


# echo "Creating branch protection policies in the $PROJECT_NAME project"
# echo "Creating Approver count policies"
# for APPROVER_COUNT_POLICY in $(echo "$DEFAULT_JSON" | jq -r '.repository.policies.approver_count[] | @base64'); do
#     APPROVER_COUNT_POLICY_JSON=$(echo "$APPROVER_COUNT_POLICY" | base64 --decode | jq -r '.')
#     REPO_NAME=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.repository_name')
#     BRANCH_NAME=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.branch_name')
#     BRANCH_MATCH_TYPE=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.branch_match_type')
#     ALLOW_DOWNVOTES=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.allow_downvotes')
#     CREATOR_VOTE_COUNT=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.creator_vote_counts')
#     MINIMAL_APPROVER_COUNT=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.minimum_approver_count')
#     RESET_ON_SOURCE_PUSH=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.reset_on_source_push')
#     echo "Reading ID of the $REPO_NAME repository"
#     REPO_ID=$(az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME")
#      if [ $? -eq 0 ]; then
#         echo "The ID of the $REPO_NAME repository is $REPO_ID"
#     else
#         echo "Error during the reading of the property ID of the $REPO_NAME"
#         exit 1
#     fi
#     echo "Creating approver count policy for the $BRANCH_NAME in $REPO_NAME repository"
#     az repos policy approver-count create --branch-match-type $BRANCH_MATCH_TYPE --allow-downvotes $ALLOW_DOWNVOTES --blocking true --branch $BRANCH_NAME --creator-vote-counts $CREATOR_VOTE_COUNT --enabled true --minimum-approver-count $MINIMAL_APPROVER_COUNT --repository-id $REPO_ID --reset-on-source-push $RESET_ON_SOURCE_PUSH --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME" --verbose
#     if [ $? -eq 0 ]; then
#         echo "Approver count policy was added to $BRANCH_NAME in $REPO_NAME repository"
#     else
#         echo "Approver count policy was not added to $BRANCH_NAME in $REPO_NAME repository"
#         exit 1
#     fi
# done

# az repos policy case-enforcement create --blocking {false, true}
#                                         --enabled {false, true}
#                                         --repository-id
#                                         [--detect {false, true}]
#                                         [--org]
#                                         [--project]

# az repos policy comment-required create --blocking {false, true}
#                                         --branch
#                                         --enabled {false, true}
#                                         --repository-id
#                                         [--branch-match-type {exact, prefix}]
#                                         [--detect {false, true}]
#                                         [--org]
#                                         [--project]

# az repos policy merge-strategy create --blocking {false, true}
#                                       --branch
#                                       --enabled {false, true}
#                                       --repository-id
#                                       [--allow-no-fast-forward {false, true}]
#                                       [--allow-rebase {false, true}]
#                                       [--allow-rebase-merge {false, true}]
#                                       [--allow-squash {false, true}]
#                                       [--branch-match-type {exact, prefix}]
#                                       [--detect {false, true}]
#                                       [--org]
#                                       [--project]

# az repos policy required-reviewer create --blocking {false, true}
#                                          --branch
#                                          --enabled {false, true}
#                                          --message
#                                          --repository-id
#                                          --required-reviewer-ids
#                                          [--branch-match-type {exact, prefix}]
#                                          [--detect {false, true}]
#                                          [--org]
#                                          [--path-filter]
#                                          [--project]

# az repos policy work-item-linking create --blocking {false, true}
#                                          --branch
#                                          --enabled {false, true}
#                                          --repository-id
#                                          [--branch-match-type {exact, prefix}]
#                                          [--detect {false, true}]
#                                          [--org]
#                                          [--project]

# az repos policy build create --blocking {false, true}
#                              --branch
#                              --build-definition-id
#                              --display-name
#                              --enabled {false, true}
#                              --manual-queue-only {false, true}
#                              --queue-on-source-update-only {false, true}
#                              --repository-id
#                              --valid-duration
#                              [--branch-match-type {exact, prefix}]
#                              [--detect {false, true}]
#                              [--org]
#                              [--path-filter]
#                              [--project]



















# # echo "Enabling invitation of guest users in $ORG_NAME organization for $PROJECT_NAME project"
# # This operation is currently not supported and has to be done manually
# # RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://www.example.com)
# # if [ "$RESPONSE" == "200" ]; then
# #   echo "Curl was successful"
# # else
# #   echo "Curl failed with status code $RESPONSE"
# # fi





















# REPO_NAMES=("Management" "Identity" "Connectivity" "Management pipeline" "Identity pipeline" "Management pipeline")

# # set your personal access token
# TOKEN="YOUR_TOKEN_HERE"

# # create the repositories in the project 
# for REPO_NAME in "${REPO_NAMES[@]}"
# do
#  echo "Creating $REPO_NAME repository..."
#   curl --silent \
#   --location \
#   --request POST "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/git/repositories?api-version=6.0" \
#   --header "Authorization: Basic $(echo -n :$TOKEN | base64)" \
#   --header "Content-Type: application/json" \
#   --data-raw "{\"name\":\"$REPO_NAME\"}"
# done

# # create branch policies for the repositories
# # MAIN_POLICY_PAYLOAD=$(cat <<EOF
# # {
# #   "isEnabled": true,
# #   "isBlocking": true,
# #   "settings": {
# #     "minimumApproverCount": 2,
# #     "creatorVoteCounts": true,
# #     "allowDownvotes": false,
# #     "resetOnSourcePush": true,
# #     "scope": {
# #       "refName": "refs/heads/main",
# #       "matchKind": "Exact"
# #     }
# #   }
# # }
# # EOF
# # )
# # curl --silent \
# # --location \
# # --request POST "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/policy/configurations?api-version=6.0" \
# # --header "Authorization: Basic $(echo -n :$TOKEN | base64)" \
# # --header "Content-Type: application/json" \
# # --data-raw "$POLICY_PAYLOAD"

# # RELEASES_POLICY_PAYLOAD=$(cat <<EOF
# # {
# #   "isEnabled": true,
# #   "isBlocking": true,
# #   "settings": {
# #     "minimumApproverCount": 2,
# #     "creatorVoteCounts": true,
# #     "allowDownvotes": false,
# #     "resetOnSourcePush": true,
# #     "scope": {
# #       "refName": "refs/heads/main",
# #       "matchKind": "Exact"
# #     }
# #   }
# # }
# # EOF
# # )
# # curl --silent \
# # --location \
# # --request POST "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/policy/configurations?api-version=6.0" \
# # --header "Authorization: Basic $(echo -n :$TOKEN | base64)" \
# # --header "Content-Type: application/json" \
# # --data-raw "$POLICY_PAYLOAD"
