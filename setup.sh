#!/bin/bash

# description: This script creates a new Azure DevOps project and repository using the Azure DevOps CLI. 
#              It also adds users to the organization and project, and creates a new repository.
# author: Ivan Porta
# date: 2021-05-18

# ==================== GENERAL =========================
function out {
    case "$1" in
        success)
            echo -ne "\033[32m${@:2}\033[0m"
            ;;
        warning)
            echo -ne "\033[33m${@:2}\033[0m"
            ;;
        error)
            echo -ne "\033[31m${@:2}\033[0m"
            ;;
        *)
            echo -ne "${@:1}"
            ;;
    esac
}
function log {
    local LEVEL=$1
    local LOG_FILE="generation.log"
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    case "$LEVEL" in
        verbose)
            echo "[$TIMESTAMP] [VERBOSE] ${@:2}" >> $LOG_FILE
            ;;
        debug)
            echo "[$TIMESTAMP] [DEBUG] ${@:2}" >> $LOG_FILE
            ;;
        warning)
            echo "[$TIMESTAMP] [WARNING] ${@:2}" >> $LOG_FILE
            ;;
        error)
            echo "[$TIMESTAMP] [ERROR] ${@:2}" >> $LOG_FILE
            ;;
        *)
            echo "[$TIMESTAMP] [INFO] ${@:1}" >> $LOG_FILE
            ;;
    esac
}
# ==================== ORGANIZATION ====================
function authenticate_to_azure_devops {
    local ORG_NAME=$1
    log "Authenticating to Azure DevOps"
    log verbose "Organization: $ORG_NAME"
    log verbose "Command: az devops login --organization https://dev.azure.com/$ORG_NAME"
    az devops login --organization https://dev.azure.com/$ORG_NAME
    if [ $? -eq 0 ]; then
        log success "Authentication to Azure DevOps successfull"
    else
        log error "Authentication to Azure DevOps failed"
        exit 1
    fi
}
function add_users_to_organization {
    local ORG_NAME=$1
    local DEFAULT_JSON=$2
    log "Adding users to $ORG_NAME organization"
    for USER in $(echo "$DEFAULT_JSON" | jq -r '.organization.users[] | @base64'); do
        USER_JSON=$(echo "$USER" | base64 --decode | jq -r '.')
        log verbose "User: $USER_JSON"
        NAME=$(echo "$USER_JSON" | jq -r '.name')
        log verbose "NAME: $NAME"
        EMAIL=$(echo "$USER_JSON" | jq -r '.email')
        log verbose "EMAIL: $EMAIL"
        log "Checking if user $NAME ($EMAIL) is already a member of $ORG_NAME organization"
        log verbose "Command: az devops user show --user $EMAIL --organization https://dev.azure.com/$ORG_NAME"
        RESPONSE=$(az devops user show --user $EMAIL --organization "https://dev.azure.com/$ORG_NAME")
        if [ -z "$RESPONSE" ]; then
            log success "User $NAME ($EMAIL) is not a member of $ORG_NAME organization"
        else
            log warning  "User $NAME ($EMAIL) is already a member of $ORG_NAME organization. Skipping..."
            continue
        fi
        log "Adding user $NAME ($EMAIL) to $ORG organization"
        log verbose "Command: az devops user add --email-id $EMAIL --license-type express --send-email-invite false --organization https://dev.azure.com/$ORG_NAME"
        az devops user add --email-id "$EMAIL" --license-type "express" --send-email-invite false --organization "https://dev.azure.com/$ORG_NAME"
        if [ $? -eq 0 ]; then
            log success "User $NAME ($EMAIL) was added to $ORG_NAME organization"
        else
            log error "User $NAME ($EMAIL) was not added to $ORG_NAME organization"
            return 1
        fi
    done
}
function install_extensions_in_organization {
    local ORG_NAME=$1
    local DEFAULT_JSON=$2
    log "Installing extensions in the $ORG_NAME organization"
    for EXRENSION in $(echo "$DEFAULT_JSON" | jq -r '.organization.extensions[] | @base64'); do
        EXRENSION_JSON=$(echo "$EXRENSION" | base64 --decode | jq -r '.')
        log verbose "Extension: $EXRENSION_JSON"
        ID=$(echo "$EXRENSION_JSON" | jq -r '.id')
        log verbose "ID: $ID"
        PUBLISHER_ID=$(echo "$EXRENSION_JSON" | jq -r '.publisher_id')
        log verbose "PUBLISHER_ID: $PUBLISHER_ID"
        log "Checking if $ID extension is already installed"
        log verbose "Command: az devops extension show --extension-id $ID --publisher-id $PUBLISHER_ID --organization https://dev.azure.com/$ORG_NAME"
        RESPONSE=$(az devops extension show --extension-id "$ID" --publisher-id "$PUBLISHER_ID" --organization "https://dev.azure.com/$ORG_NAME")
        if [ -z "$RESPONSE" ]; then
            log "$ID is not installed"
        else
            log warning "$ID is already installed. Skipping..."
            continue
        fi
        log "Installing $ID extension in $ORG_NAME organization"
        log verbose "Command: az devops extension install --extension-id $ID --publisher-id $PUBLISHER_ID --organization https://dev.azure.com/$ORG_NAME"
        az devops extension install --extension-id "$ID" --publisher-id "$PUBLISHER_ID" --organization "https://dev.azure.com/$ORG_NAME"
        if [ $? -eq 0 ]; then
            log success "Extension $ID was installed to $ORG_NAME organization"
        else
            log error "Extension $ID was not installed to $ORG_NAME organization"
            return 1
        fi
    done
}
function connecting_organization_to_azure_active_directory {
    local ORG_NAME=$1
    local DEFAULT_JSON=$2
    TENANT_ID=$(echo "$DEFAULT_JSON" | jq -r '.organization.azure_active_directory.tenant_id')
    log verbose "TENANT_ID: $TENANT_ID"
    log "Connecting to $TENANT_ID tenant Azure Active Directory"
    # This call just return the list of possible tenants
    # out "Check if the $ORG_NAME organization is already connected to Azure Active Directory"
    # RESPONSE=$(curl --silent \
    #         --write-out "\n%{http_code}" \
    #         --header "Authorization: Basic $(echo -n :$PAT | base64)" \
    #         --header "Content-Type: application/json" \
    #         --data-raw '{"contributionIds":["ms.vss-admin-web.organization-admin-aad-user-tenants-data-provider"],"dataProviderContext":{"properties":{"sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/organizationAad","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"organizationAad","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
    #         "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    # HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    # RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    # if [ $HTTP_STATUS != 200 ]; then
    #     out error "Error during the retrieval of the list of existing Azure Active Directories"
    #     exit 1;
    # else
    #     out success "The list of existing Azure Active Directories was retrieved successfully"
    # fi
    # if [[ $(echo "$RESPONSE_BODY" | jq -r '.dataProviders."ms.vss-admin-web.organization-admin-aad-user-tenants-data-provider".userTenantData.userTenants | length') -ge 1 ]]; then    
    #     DISPLAY_NAME=$(echo "$RESPONSE_BODY" | jq -r '.dataProviders."ms.vss-admin-web.organization-admin-aad-user-tenants-data-provider".userTenantData.userTenants[0].displayName')
    #     ID=$(echo "$RESPONSE_BODY" | jq -r '.dataProviders."ms.vss-admin-web.organization-admin-aad-user-tenants-data-provider".userTenantData.userTenants[0].id')
    #     out warning "The $ORG_NAME organization is already connected to the $DISPLAY_NAME ($ID) Azure Active Directory. Skipping..."
    #     return 1
    # else
    #     out "The $ORG_NAME organization is not connected to Azure Active Directory. Connecting..."
    # fi
    log "Check if the $ORG_NAME organization is already connected to Azure Active Directory"
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_settings/organizationAad?__rt=fps&__ver=2"
    RESPONSE=$(curl --silent \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            "https://dev.azure.com/$ORG_NAME/_settings/organizationAad?__rt=fps&__ver=2")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the retrieval of the list of existing Azure Active Directories"
        return 1;
    else
        log success "The list of existing Azure Active Directories was retrieved successfully"
    fi
    if [[ $(echo "$RESPONSE_BODY" | jq -r '.fps.dataProviders.data."ms.vss-admin-web.organization-admin-aad-data-provider".orgnizationTenantData.domain') != "" ]]; then    
        DISPLAY_NAME=$(echo "$RESPONSE_BODY" | jq -r '.fps.dataProviders.data."ms.vss-admin-web.organization-admin-aad-data-provider".orgnizationTenantData.displayName')
        log verbose "DISPLAY_NAME: $DISPLAY_NAME"
        ID=$(echo "$RESPONSE_BODY" | jq -r '.fps.dataProviders.data."ms.vss-admin-web.organization-admin-aad-data-provider".orgnizationTenantData.id')
        log verbose "ID: $ID"
        DOMAIN=$(echo "$RESPONSE_BODY" | jq -r '.fps.dataProviders.data."ms.vss-admin-web.organization-admin-aad-data-provider".orgnizationTenantData.domain')
        log verbose "DOMAIN: $DOMAIN"
        log warning "The $ORG_NAME organization is already connected to the $DISPLAY_NAME ($ID) Azure Active Directory. Skipping..."
        return 1
    else
        log "The $ORG_NAME organization is not connected to Azure Active Directory. Connecting..."
    fi
    log verbose "Request: '[{\"from\":\"\",\"op\":2,\"path\":\"/TenantId\",\"value\":\"$TENANT_ID\"}]'"
    log verbose "Url: https://vssps.dev.azure.com/$ORG_NAME/_apis/Organization/Organizations/Me?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/TenantId","value":"'$TENANT_ID'"}]' \
            "https://vssps.dev.azure.com/$ORG_NAME/_apis/Organization/Organizations/Me?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the connection to Azure Active Directory. $RESPONSE_BODY"
        return 1;
    else
        log success "Connection to Azure Active Directory was successful"
    fi
}
function configure_organization_policies {
    local ORG_ID=$1
    local ORG_NAME=$2
    local DEFAULT_JSON=$3
    local PAT=$4
    log "Configure $ORG_NAME organization policies"
    THIRD_PARTY_ACCESS_VIA_OAUTH=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.disallow_third_party_application_access_via_oauth')
    log "Setting Third-party application access via OAuth to $THIRD_PARTY_ACCESS_VIA_OAUTH"
    log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$THIRD_PARTY_ACCESS_VIA_OAUTH'"}]' 
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.DisallowOAuthAuthentication?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$THIRD_PARTY_ACCESS_VIA_OAUTH'"}]' \
            "https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.DisallowOAuthAuthentication?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    if [ $HTTP_STATUS != 204 ]; then
        log error "Error during the configuration of the Third-party application access via OAuth policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Third-party application access via OAuth policy was successful"
    fi
    SSH_AUTHENTICATION=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.disallow_ssh_authentication')
    log "Setting SSH authentication to $SSH_AUTHENTICATION"
    log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$SSH_AUTHENTICATION'"}]'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.DisallowSecureShell?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$SSH_AUTHENTICATION'"}]' \
            "https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.DisallowSecureShell?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE") 
    log verbose "Response code: $HTTP_STATUS"
    if [ $HTTP_STATUS != 204 ]; then
        log error "Error during the configuration of the SSH authentication policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the SSH authentication policy was successful"
    fi
    LOG_AUDIT_EVENTS=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.log_audit_events')
    log "Setting Log audit events to $LOG_AUDIT_EVENTS"
    log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$LOG_AUDIT_EVENTS'"}]'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.LogAuditEvents?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$LOG_AUDIT_EVENTS'"}]' \
            "https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.LogAuditEvents?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    if [ $HTTP_STATUS != 204 ]; then
        log error "Error during the configuration of the Log audit events policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Log audit events policy was successful"
    fi
    ALLOW_PUBLIC_PROJECTS=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.allow_public_projects')
    log "Setting Allow public projects to $ALLOW_PUBLIC_PROJECTS"
    log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$ALLOW_PUBLIC_PROJECTS'"}]'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.AllowAnonymousAccess?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$ALLOW_PUBLIC_PROJECTS'"}]' \
            "https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.AllowAnonymousAccess?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    if [ $HTTP_STATUS != 204 ]; then
        log error "Error during the configuration of the Allow public projects policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Allow public projects policy was successful"
    fi
    ARTIFACTS_EXTERNAL_PACKAGE_PROTECTION_TOKEN=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.additional_protections_public_package_registries')
    log "Setting Additional protections for public package registries to $ARTIFACTS_EXTERNAL_PACKAGE_PROTECTION_TOKEN"
    log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$ARTIFACTS_EXTERNAL_PACKAGE_PROTECTION_TOKEN'"}]'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.ArtifactsExternalPackageProtectionToken?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$ARTIFACTS_EXTERNAL_PACKAGE_PROTECTION_TOKEN'"}]' \
            "https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.ArtifactsExternalPackageProtectionToken?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    if [ $HTTP_STATUS != 204 ]; then
        log error "Error during the configuration of the Additional protections for public package registries policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Additional protections for public package registries policy was successful"
    fi
    ENFORCE_AZURE_ACTIVE_DIRECTORY_CONDITIONAL_ACCESS=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.enable_azure_active_directory_conditional_access_policy_validation')
    log "Setting Additional protections for public package registries to $ENFORCE_AZURE_ACTIVE_DIRECTORY_CONDITIONAL_ACCESS"
    log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$ENFORCE_AZURE_ACTIVE_DIRECTORY_CONDITIONAL_ACCESS'"}]'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.EnforceAADConditionalAccess?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$ENFORCE_AZURE_ACTIVE_DIRECTORY_CONDITIONAL_ACCESS'"}]' \
            "https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.EnforceAADConditionalAccess?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    if [ $HTTP_STATUS != 204 ]; then
        log error "Error during the configuration of the Additional protections for public package registries policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Additional protections for public package registries policy was successful"
    fi
    ALLOW_TEAM_ADMINS_INVITATIONS_ACCESS_TOKEN=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.allow_team_and_project_administrators_to_invite_new_users')
    log "Setting Additional protections for public package registries to $ALLOW_TEAM_ADMINS_INVITATIONS_ACCESS_TOKEN"
    log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$ALLOW_TEAM_ADMINS_INVITATIONS_ACCESS_TOKEN'"}]'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.AllowTeamAdminsInvitationsAccessToken?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$ALLOW_TEAM_ADMINS_INVITATIONS_ACCESS_TOKEN'"}]' \
            "https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.AllowTeamAdminsInvitationsAccessToken?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    if [ $HTTP_STATUS != 204 ]; then
        log error "Error during the configuration of the Additional protections for public package registries policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Additional protections for public package registries policy was successful"
    fi
    ALLOW_GUEST_USERS=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.disallow_external_guest_access')
    log "Setting Allow guest users to $ALLOW_GUEST_USERS"
    log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$ALLOW_GUEST_USERS'"}]'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.DisallowAadGuestUserAccess?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$ALLOW_GUEST_USERS'"}]' \
            "https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.DisallowAadGuestUserAccess?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    if [ $HTTP_STATUS != 204 ]; then
        log error "Error during the configuration of the Allow guest users policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Allow guest users policy was successful"
    fi
    REQUEST_ACCESS=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.request_access.enable')
    REQUEST_ACCESS_URL=$(echo "$DEFAULT_JSON" | jq -r '.organization.policies.request_access.url')
    log "Skipping the configuration of the organization url"
    if  [  ! $REQUEST_ACCESS ]; then
        log "Setting $ORG_NAME organization url to $REQUEST_ACCESS_URL"
        log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$REQUEST_ACCESS_URL'"}]'
        log verbose "Url: https://vssps.dev.azure.com/$ORG_NAME/_apis/Organization/Collections/$ORG_ID/Properties?api-version=5.0-preview.1"
        RESPONSE=$(curl --silent \
                --request PATCH \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json-patch+json" \
                --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$ALLOW_GUEST_USERS'"}]' \
                "https://vssps.dev.azure.com/$ORG_NAME/_apis/Organization/Collections/$ORG_ID/Properties?api-version=5.0-preview.1")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        if [ $HTTP_STATUS != 200 ]; then
            log error "Error during the configuration of the organization url. $RESPONSE_BODY"
            return 1;
        else
            log success "Configuration of the organization url was successful"
        fi
    fi
    log "Setting Request access to $REQUEST_ACCESS"
    log verbose 'Request: [{"from":"","op":2,"path":"/Value","value":"'$REQUEST_ACCESS'"}]'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.AllowRequestAccessToken?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --request PATCH \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json-patch+json" \
            --data-raw '[{"from":"","op":2,"path":"/Value","value":"'$REQUEST_ACCESS'"}]' \
            "https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.AllowRequestAccessToken?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    if [ $HTTP_STATUS != 204 ]; then
        log error "Error during the configuration of the Request access policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Request access policy was successful"
    fi
}
function configure_organization_settings {
    local ORG_ID=$1
    local ORG_NAME=$2
    local DEFAULT_JSON=$3
    local PAT=$4
    log "Configure $ORG_NAME organization settigns"  
    DISABLE_ANONYMOUS_ACCESS_BADGES=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.disable_anonymous_access_badges')
    log "Setting Disable anonymous access badges to $DISABLE_ANONYMOUS_ACCESS_BADGES"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"badgesArePublic":"'$DISABLE_ANONYMOUS_ACCESS_BADGES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"badgesArePublic":"'$DISABLE_ANONYMOUS_ACCESS_BADGES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Disable anonymous access badges policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Disable anonymous access badges policy was successful"
    fi
    LIMIT_VARIABLES_SET_QUEUE_TIME=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.limit_variables_set_queue_time')
    log "Setting Limit variables set at queue time to $LIMIT_VARIABLES_SET_QUEUE_TIME"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"enforceSettableVar":"'$LIMIT_VARIABLES_SET_QUEUE_TIME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"enforceSettableVar":"'$LIMIT_VARIABLES_SET_QUEUE_TIME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Limit variables set at queue time policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Limit variables set at queue time policy was successful"
    fi
    LIMIT_JOB_AUTHORIZATION_CURRENT_PROJECT_NON_RELEASE_PIPELINES=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.limit_job_authorization_current_project_non_release_pipelines')
    log "Setting Limit job authorization scope to current project for non-release pipelines to $LIMIT_JOB_AUTHORIZATION_CURRENT_PROJECT_NON_RELEASE_PIPELINES"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"enforceJobAuthScope":"'$LIMIT_JOB_AUTHORIZATION_CURRENT_PROJECT_NON_RELEASE_PIPELINES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"enforceJobAuthScope":"'$LIMIT_JOB_AUTHORIZATION_CURRENT_PROJECT_NON_RELEASE_PIPELINES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Limit job authorization scope to current project for non-release pipelines policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Limit job authorization scope to current project for non-release pipelines policy was successful"
    fi
    LIMIT_JOB_AUTHORIZATION_CURRENT_PROJECT_RELEASE_PIPELINES=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.limit_job_authorization_current_project_release_pipelines')
    log "Setting Limit job authorization scope to current project for release pipelines to $LIMIT_JOB_AUTHORIZATION_CURRENT_PROJECT_NON_RELEASE_PIPELINES"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"enforceJobAuthScopeForReleases":"'$LIMIT_JOB_AUTHORIZATION_CURRENT_PROJECT_RELEASE_PIPELINES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"enforceJobAuthScopeForReleases":"'$LIMIT_JOB_AUTHORIZATION_CURRENT_PROJECT_RELEASE_PIPELINES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Limit job authorization scope to current project for release pipelines policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Limit job authorization scope to current project for release pipelines policy was successful"
    fi
    PROJECT_ACCESS_REPOSITORIES_YAML_PIPELINES=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.protect_access_repositories_yaml_pipelines')
    log "Setting Protect access to repositories for YAML pipelines to $PROJECT_ACCESS_REPOSITORIES_YAML_PIPELINES"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"enforceReferencedRepoScopedToken":"'$PROJECT_ACCESS_REPOSITORIES_YAML_PIPELINES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"enforceReferencedRepoScopedToken":"'$PROJECT_ACCESS_REPOSITORIES_YAML_PIPELINES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Protect access to repositories for YAML pipelines policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Protect access to repositories for YAML pipelines policy was successful"
    fi
    DISABLE_STAGE_CHOOSER=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.disable_stage_chooser')
    log "Setting Disable stage chooser to $DISABLE_STAGE_CHOOSER"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableStageChooser":"'$DISABLE_STAGE_CHOOSER'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableStageChooser":"'$DISABLE_STAGE_CHOOSER'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Disable stage chooser policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Disable stage chooser policy was successful"
    fi
    DISABLE_CREATION_CLASSIC_BUILD_AND_CLASSIC_RELEASE_PIPELINES=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.disable_creation_classic_build_and_classic_release_pipelines')
    log "Setting Disable creation of classic build and classic release pipelines to $DISABLE_CREATION_CLASSIC_BUILD_AND_CLASSIC_RELEASE_PIPELINES"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableClassicPipelineCreation":"'$DISABLE_CREATION_CLASSIC_BUILD_AND_CLASSIC_RELEASE_PIPELINES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableClassicPipelineCreation":"'$DISABLE_CREATION_CLASSIC_BUILD_AND_CLASSIC_RELEASE_PIPELINES'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Disable creation of classic build and classic release pipelines policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Disable creation of classic build and classic release pipelines policy was successful"
    fi
    DISABLE_BUILD_IN_TASKS=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.disable_built_in_tasks')
    log "Setting Disable built-in tasks to $DISABLE_BUILD_IN_TASKS"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableInBoxTasksVar":"'$DISABLE_BUILD_IN_TASKS'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableInBoxTasksVar":"'$DISABLE_BUILD_IN_TASKS'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Disable built-in tasks policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Disable built-in tasks policy was successful"
    fi
    DISABLE_MARKETPLACE_TASKS=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.disable_marketplace_tasks')
    log "Setting Disable marketplace tasks to $DISABLE_MARKETPLACE_TASKS"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableMarketplaceTasksVar":"'$DISABLE_MARKETPLACE_TASKS'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableMarketplaceTasksVar":"'$DISABLE_MARKETPLACE_TASKS'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Disable built-in tasks policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Disable built-in tasks policy was successful"
    fi
    DISABLE_NODE_SIX_TASKS=$(echo "$DEFAULT_JSON" | jq -r '.organization.settings.disable_node_six_tasks')
    log "Setting Disable Node 6 tasks to $DISABLE_NODE_SIX_TASKS"
    log verbose 'Request: {"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableNode6Tasksvar":"'$DISABLE_NODE_SIX_TASKS'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
        --request POST \
        --write-out "\n%{http_code}" \
        --header "Authorization: Basic $(echo -n :$PAT | base64)" \
        --header "Content-Type: application/json" \
        --data-raw '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"disableNode6Tasksvar":"'$DISABLE_NODE_SIX_TASKS'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/_settings/pipelinessettings","routeId":"ms.vss-admin-web.collection-admin-hub-route","routeValues":{"adminPivot":"pipelinessettings","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
        "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the configuration of the Disable built-in tasks policy. $RESPONSE_BODY"
        return 1;
    else
        log success "Configuration of the Disable built-in tasks policy was successful"
    fi
}
function configure_organization_repositories {
    local ORG_NAME=$1
    local DEFAULT_JSON=$2
    log "Configuring organization repositories"
    log warning "Microsoft doesn't have public APIs to configure this secion and it's using  ASP.NET __RequestVerificationToken to validate the requests. Because of that, this configuration is not supported yet."

    # response=$(curl --header "Authorization: Basic $(echo -n :$PAT | base64)" -s "https://gtrekter.visualstudio.com/_settings/repositories")
    # echo $response
    # # Extract value of __RequestVerificationToken input field using grep
    # token=$(echo "$response" | grep -oP '(?<=<input type="hidden" name="__RequestVerificationToken" value=")[^"]+')
    # # Print the token value
    # echo "$token"

    # NOT CURRENTLY AVAILABLE DUE TO MISSING REQUEST TOKEN
    # ENABLE_GRAVATAR_IMAGES=$(echo "$DEFAULT_JSON" | jq -r '.organization.repositories.enable_gravatar_images')
    # out "Setting Enable Gravatar images to $ENABLE_GRAVATAR_IMAGES"
    # RESPONSE=$(curl --silent \
    #         --request POST -vvv \
    #         --write-out "\n%{http_code}" \
    #         --header "Authorization: Basic $(echo -n :$PAT | base64)" \
    #         --header "Content-Type: application/json" \
    #         --data-raw '{repositoryId: "00000000-0000-0000-0000-000000000000", "option": {"key":"GravatarEnabled","value":'$ENABLE_GRAVATAR_IMAGES',"textValue":null}, __RequestVerificationToken: "'$token'"}' \
    #         "https://dev.azure.com/$ORG_NAME/_api/_versioncontrol/UpdateRepositoryOption?__v=5&repositoryId=00000000-0000-0000-0000-000000000000")
    
    # echo $RESPONSE
    # HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    # RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    # if [ $HTTP_STATUS != 200 ]; then
    #     out error "Error during the configuration of the Enable Gravatar images policy. $RESPONSE_BODY"
    #     exit 1;
    # else
    #     out success "Configuration of the Enable Gravatar images policy was successful"
    # fi

    # ENABLE_DEFAULT_BRANCH_NAME=$(echo "$DEFAULT_JSON" | jq -r '.organization.repositories.default_branch_name.enable')
    # DEFAULT_BRANCH_NAME=$(echo "$DEFAULT_JSON" | jq -r '.organization.repositories.default_branch_name.name')
    # out "Setting Default branch name to $DEFAULT_BRANCH_NAME"

    # echo '{"option": {"key":"DefaultBranchName","value":'$ENABLE_DEFAULT_BRANCH_NAME',"textValue":"'$DEFAULT_BRANCH_NAME'"}}'
    # RESPONSE=$(curl --silent \
    #         --request POST \
    #         --write-out "\n%{http_code}" \
    #         --header "Authorization: Basic $(echo -n :$PAT | base64)" \
    #         --header "Content-Type: application/json" \
    #         --data-raw '{"option": {"key":"DefaultBranchName","value":'$ENABLE_DEFAULT_BRANCH_NAME',"textValue":"'$DEFAULT_BRANCH_NAME'"}}' \
    #         "https://dev.azure.com/$ORG_NAME/_api/_versioncontrol/UpdateRepositoryOption?__v=5&repositoryId=00000000-0000-0000-0000-000000000000")
    # HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    # RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    # if [ $HTTP_STATUS != 200 ]; then
    #     out error "Error during the configuration of the Default branch name to $DEFAULT_BRANCH_NAME. $RESPONSE_BODY"
    #     exit 1;
    # else
    #     out success "Configuration of the Default branch name to $DEFAULT_BRANCH_NAME was successful"
    # fi
} # WIP (NOT AVAILABLE YET)
# ==================== PROJECT =========================
function create_project {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    log "Checking if $PROJECT_NAME project already exists"
    log verbose "az devops project show --project $PROJECT_NAME --org https://dev.azure.com/$ORG_NAME"
    RESPONSE=$(az devops project show --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME")
    if [ -z "$RESPONSE" ]; then
        log "$PROJECT_NAME project does not exist"
    else
        log warning "Project $PROJECT_NAME already exists. Skipping..."
        return 0
    fi
    log "Creating $PROJECT_NAME project"
    DESCRIPTION=$(echo "$DEFAULT_JSON" | jq -r '.organization.project.description')
    PROCESS=$(echo "$DEFAULT_JSON" | jq -r '.organization.project.process')
    log verbose "az devops project create --name $PROJECT_NAME --description '$DESCRIPTION' --detect false --org https://dev.azure.com/$ORG_NAME --process $PROCESS --source-control git --visibility private"
    az devops project create --name "$PROJECT_NAME" --description "$DESCRIPTION" --detect false --org "https://dev.azure.com/$ORG_NAME" --process $PROCESS --source-control git --visibility private
    if [ $? -eq 0 ]; then
        log success "$PROJECT_NAME project created successfully"
    else
        log error "Failed to create $PROJECT_NAME project"
        return 1
    fi
}
function create_security_groups {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    log "Creating security groups in the $PROJECT_NAME project"
    for SECURITY_GROUP in $(echo "$DEFAULT_JSON" | jq -r '.organization.project.security_groups[] | @base64'); do
        SECURITY_GROUP_JSON=$(echo "$SECURITY_GROUP" | base64 --decode | jq -r '.')
        log verbose "Security group: $SECURITY_GROUP_JSON"
        NAME=$(echo "$SECURITY_GROUP_JSON" | jq -r '.name')
        log verbose "Security group name: $NAME" 
        DESCRIPTION=$(echo "$SECURITY_GROUP_JSON" | jq -r '.description')
        log verbose "Security group description: $DESCRIPTION"
        log "Checking if $NAME security group already exists"

        log verbose "az devops security group list --project $PROJECT_NAME --organization https://dev.azure.com/$ORG_NAME"
        RESPONSE=$(az devops security group list --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME" | jq '.graphGroups[] | select(.displayName == "AAA") | length > 0')
        if [ "$RESPONSE" ]; then
            log "$NAME security group does not exist"
        else
            log warning "$NAME security group already exists. Skipping..."
            continue
        fi
        log "Creating $NAME security group in $PROJECT_NAME project"
        log verbose "az devops security group create --name $NAME --description '$DESCRIPTION' --project $PROJECT_NAME --organization https://dev.azure.com/$ORG_NAME --scope project"
        az devops security group create --name "$NAME" --description "$DESCRIPTION" --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME" --scope project
        if [ $? -eq 0 ]; then
            log success "User $NAME ($EMAIL) was added to $ORG_NAME organization"
        else
            log error "User $NAME ($EMAIL) was not added to $ORG_NAME organization"
            return 1
        fi
    done
}
function create_repositories {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    log "Creating repositories in $PROJECT_NAME project"
    for REPO in $(echo "$DEFAULT_JSON" | jq -r '.repository.repositories[] | @base64'); do
        REPO_JSON=$(echo "$REPO" | base64 --decode | jq -r '.')
        log verbose "Repository: $REPO_JSON"
        REPO_NAME=$(echo "$REPO_JSON" | jq -r '.name')
        log verbose "Repository name: $REPO_NAME"
        log "Checking if $REPO_NAME repository already exists"
        log verbose "az repos show --repository $REPO_NAME --project $PROJECT_NAME --org https://dev.azure.com/$ORG_NAME"
        RESPONSE=$(az repos show --repository "$REPO_NAME" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME")
        if [ -z "$RESPONSE" ]; then
            log "$REPO_NAME repository does not exist"
        else
            log warning "$REPO_NAME repository already exists. Skipping..."
            continue
        fi
        log "Creating $REPO_NAME repository..."
        log verbose "az repos create --name $REPO_NAME --project $PROJECT_NAME --org https://dev.azure.com/$ORG_NAME"
        az repos create --name "$REPO_NAME" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME"
        if [ $? -eq 0 ]; then
            log success "$REPO_NAME repository created successfully"
        else
            log error "Failed to create $REPO_NAME repository"
            return 1
        fi
        log "Cloning $REPO_NAME repository..."
        log verbose "git clone https://xxxxxxxx@dev.azure.com/$ORG_NAME/$PROJECT_NAME/_git/$REPO_NAME"
        git clone https://$PAT@dev.azure.com/$ORG_NAME/$PROJECT_NAME/_git/$REPO_NAME
        cd $REPO_NAME
        log "Configuring local git user"
        log verbose "git config user.email $EMAIL"
        git config user.email "you@example.com"
        log verbose "git config user.name $NAME"
        git config user.name "Your Name"
        log "Creating initial commit"
        log verbose "echo "# $REPO_NAME" > README.md"
        echo "# $REPO_NAME" > README.md
        log add README.md
        log verbose "commit -m 'Initial commit'"
        git commit -m "Initial commit"
        log "Pushing initial commit to $REPO_NAME repository"
        log verbose "git push origin master"
        git push origin master
        for BRANCH in $(echo "$DEFAULT_JSON" | jq -r '.repository.branches[] | @base64'); do
            BRANCH_JSON=$(echo "$BRANCH" | base64 --decode | jq -r '.')
            log verbose "Branch: $BRANCH_JSON"
            BRANCH_NAME=$(echo "$BRANCH_JSON" | jq -r '.name')
            log verbose "Branch name: $BRANCH_NAME"
            log "Checking if $BRANCH_NAME branch already exists"
            RESPONSE=$(git branch -a | grep $BRANCH_NAME)
            if [ -z "$RESPONSE" ]; then
                log "Creating $BRANCH_NAME branch"
                log verbose "git checkout -b $BRANCH_NAME"
                git checkout -b $BRANCH_NAME
                log "Pushing $BRANCH_NAME branch to $REPO_NAME repository"
                log verbose "git push origin $BRANCH_NAME"
                git push origin $BRANCH_NAME
            else
                log warning "$BRANCH_NAME branch already exists. Skipping..."
                continue
            fi
        done
        cd ..
        log "Deleting local repository"
        log verbose "rm -R $REPO_NAME"
        rm -R $REPO_NAME
    done
}
function delete_repository {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local REPO_NAME=$3
    local DEFAULT_JSON=$4
    log "Checking if $REPO_NAME repository already exists"
    log verbose "az repos list --project $PROJECT_NAME --query "[?name=='$REPO_NAME'].id" --organization https://dev.azure.com/$ORG_NAME --output tsv"
    REPO_ID=$(az repos list --project "$PROJECT_NAME" --query "[?name=='$REPO_NAME'].id" --organization "https://dev.azure.com/$ORG_NAME" --output tsv)
    if [ ! -z "$REPO_ID" ]; then
        log "Repository $REPO_NAME found"
    else
        log warning "Repository $REPO_NAME not found. Skipping..."
        return 1
    fi  
    log "Deleting $REPO_NAME repository"
    log verbose "az repos delete --id $REPO_ID --project $REPO_NAME --organization https://dev.azure.com/$ORG_NAME --yes"
    az repos delete --id "$REPO_ID" --project "$REPO_NAME" --organization "https://dev.azure.com/$ORG_NAME" --yes
    if [ $? -eq 0 ]; then
        log success "$REPO_NAME repository created successfully"
    else
        log error "Failed to create $REPO_NAME repository"
        return 1
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
    local PAT=$4
    log "Creating environments in $PROJECT_NAME project"
    for ENVIRONMENT in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.environments[] | @base64'); do
        ENVIRONMENT_JSON=$(echo "$ENVIRONMENT" | base64 --decode | jq -r '.')
        log verbose "ENVIRONMENT_JSON: $ENVIRONMENT_JSON"
        NAME=$(echo "$ENVIRONMENT_JSON" | jq -r '.name')
        log verbose "NAME: $NAME"
        DESCRIPTION=$(echo "$ENVIRONMENT_JSON" | jq -r '.description')
        log verbose "DESCRIPTION: $DESCRIPTION"
        log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1"
        RESPONSE=$(curl --silent \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
        log verbose "Response body: $RESPONSE_BODY"
        if [ $HTTP_STATUS != 200 -a $(echo "$RESPONSE_BODY" | jq '.value[] | select(.name == "'"$NAME"'") | length') -gt 0 ]; then
            log warning "$NAME environment already exists. Skipping..."
            continue
        else
            log "$NAME environment does not exist"
        fi
        log "Creating $NAME environment..."
        log verbose "Request: {\"name\": \"$NAME\",\"description\": \"$DESCRIPTION\"}"
        log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1"
        RESPONSE=$(curl --silent \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            --data-raw '{"name": "'"$NAME"'","description": "'"$DESCRIPTION"'"}' \
            "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
        log verbose "Response body: $RESPONSE_BODY"
        if [ $HTTP_STATUS != 200 ]; then
            log success "Environment $NAME succesfully created"
        else
            log error "Failed to create $NAME environment. $RESPONSE"
        fi
    done
}
function create_pipeline_variable_groups {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    log "Creating variable group in $PROJECT_NAME project"
    for VARIABLE_GROUPS in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.variable_groups[] | @base64'); do
        VARIABLE_GROUPS_JSON=$(echo "$VARIABLE_GROUPS" | base64 --decode | jq -r '.')
        log verbose "VARIABLE_GROUPS_JSON: $VARIABLE_GROUPS_JSON"
        NAME=$(echo "$VARIABLE_GROUPS_JSON" | jq -r '.name')
        log verbose "NAME: $NAME"
        DESCRIPTION=$(echo "$VARIABLE_GROUPS_JSON" | jq -r '.description')
        log verbose "DESCRIPTION: $DESCRIPTION"
        VARIABLE_PARAMETER=""
        for VARIABLE in $(echo "$VARIABLE_GROUPS_JSON" | jq -r '.variables[] | @base64'); do
            KEY=$(echo "$VARIABLE" | base64 --decode | jq -r '.key')
            VALUE=$(echo "$VARIABLE" | base64 --decode | jq -r '.value')
            VARIABLE_PARAMETER="$VARIABLE_PARAMETER ${KEY}=${VALUE}"
        done
        log verbose "VARIABLE_PARAMETER: $VARIABLE_PARAMETER"
        log "Checking if $NAME variable group already exists"
        log verbose "Command: az pipelines variable-group list --organization https://dev.azure.com/$ORG_NAME --project $PROJECT_NAME --output json | jq -r '.[] | select(.name == "'"$NAME"'") | .id'"
        GROUP_ID=$(az pipelines variable-group list --organization "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME" --output json | jq -r '.[] | select(.name == "'"$NAME"'") | .id')
        log verbose "GROUP_ID: $GROUP_ID"
        if [ -n "$GROUP_ID" ]; then
            log warning "Variable group $NAME already exists with ID $GROUP_ID. Skipping..."
            continue
        else
            log "Variable group $NAME does not exist"
        fi
        log "Creating $NAME variable group..."
        log verbose "Command: az pipelines variable-group create --name $NAME --description $DESCRIPTION --variables $VARIABLE_PARAMETER --organization https://dev.azure.com/$ORG_NAME --project $PROJECT_NAME"
        az pipelines variable-group create --name "$NAME" --description "$DESCRIPTION" --variables $VARIABLE_PARAMETER --organization "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME"
        if [ $? -eq 0 ]; then
            log success "$NAME variable group created successfully"
        else
            log error "Failed to create $NAME variable group"
            return 1
        fi
    done
}
function create_pipeline_pipelines {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    local PAT=$4
    log "Creating pipelines in $PROJECT_NAME project"
    for PIPELINE in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.pipelines[] | @base64'); do
        PIPELINE_JSON=$(echo "$PIPELINE" | base64 --decode | jq -r '.')
        log verbose "PIPELINE_JSON: $PIPELINE_JSON"
        NAME=$(echo "$PIPELINE_JSON" | jq -r '.name')
        log verbose "NAME: $NAME"
        REPO_NAME=$(echo "$PIPELINE_JSON" | jq -r '.repository_name')
        log verbose "REPO_NAME: $REPO_NAME"
        FOLDER_NAME=$(echo "$PIPELINE_JSON" | jq -r '.folder_name')
        log verbose "FOLDER_NAME: $FOLDER_NAME"
        PIPELINE_PATH=$(echo "$PIPELINE_JSON" | jq -r '.pipeline_path')
        log verbose "PIPELINE_PATH: $PIPELINE_PATH"
        log "Checking if $NAME pipeline already exists"
        log verbose "az pipelines show --name $NAME --project $PROJECT_NAME --org https://dev.azure.com/$ORG_NAME"
        RESPONSE=$(az pipelines show --name "$NAME" --project "$PROJECT_NAME" --org "https://dev.azure.com/$ORG_NAME")
        if [ -z "$RESPONSE" ]; then
            log "$NAME piepline does not exist"
        else
            log warning "$NAME piepline already exists. Skipping..."
            continue
        fi
        log "Reading ID of the $REPO_NAME repository"
        log verbose "az repos show --repository $REPO_NAME --query id --output tsv --org https://dev.azure.com/$ORG_NAME --project $PROJECT_NAME"
        REPO_ID=$(az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME")
        if [ $? -eq 0 ]; then
            log success "The ID of the $REPO_NAME repository is $REPO_ID"
        else
            log error  "Error during the reading of the property ID of the $REPO_NAME"
            return 1
        fi
        log "Creating $NAME pipeline..."
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
        log verbose 'Request: {"folder": "'$FOLDER_NAME'","name": "'$NAME'","configuration": {"type": "yaml","path": "'$PIPELINE_PATH'","repository": {"id": "'$REPO_ID'","name": "'$REPO_NAME'","type": "azureReposGit"}}}'
        log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/pipelines?api-version=7.0"
        RESPONSE=$(curl --silent \
            --write-out "\n%{http_code}" \
            --request POST \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            --data-raw '{"folder": "'$FOLDER_NAME'","name": "'$NAME'","configuration": {"type": "yaml","path": "'$PIPELINE_PATH'","repository": {"id": "'$REPO_ID'","name": "'$REPO_NAME'","type": "azureReposGit"}}}' \
            "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/pipelines?api-version=7.0")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
        log verbose "Response body: $RESPONSE_BODY"
        if [ $HTTP_STATUS != 200 ]; then
            log error "Failed to create $NAME pipeline. $RESPONSE_BODY"
            return 1;
        else
            log success "$NAME pipeline created successfully"
        fi
    done
}
function assing_security_groups_to_environments {
    local ORG_NAME=$1
    local PROJECT_ID=$2
    local PROJECT_NAME=$3
    local DEFAULT_JSON=$4
    log "Assign security groups to environments in $PROJECT_NAME project"
    for ENVIRONMENT in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.environments[] | @base64'); do
        ENVIRONMENT_JSON=$(echo "$ENVIRONMENT" | base64 --decode | jq -r '.')
        log verbose "ENVIRONMENT_JSON: $ENVIRONMENT_JSON"
        ENVIRONMENT_NAME=$(echo "$ENVIRONMENT_JSON" | jq -r '.name')
        log verbose "ENVIRONMENT_NAME: $ENVIRONMENT_NAME"
        for SECURITY_GROUP in $(echo "${ENVIRONMENT_JSON}" | jq -r '.security_groups_name[] | @base64'); do
            SECURITY_GROUP_JSON=$(echo "${SECURITY_GROUP}" | base64 --decode)
            log verbose "SECURITY_GROUP_JSON: $SECURITY_GROUP_JSON"
            NAME=$(echo "${SECURITY_GROUP_JSON}" | jq -r '.name')
            log verbose "NAME: $NAME"
            ROLE=$(echo "${SECURITY_GROUP_JSON}" | jq -r '.role_name')
            log verbose "ROLE: $ROLE"
            log "Get security group ID for $NAME"
            SECURITY_GROUP_ID=$(az devops security group list --project $PROJECT_NAME --org https://dev.azure.com/$ORG_NAME --output json | jq -r '.graphGroups[] | select(.displayName == "'"$NAME"'") | .originId')
            if [ $? -eq 0 ]; then
                log success "The ID of the $NAME security group is $SECURITY_GROUP_ID"
            else
                log error "Error during the reading of the property ID of the $NAME security group"
                return 1
            fi
            log "Get evnironment ID by $ENVIRONMENT_NAME"
            log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1"
            RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            log verbose "Response code: $HTTP_STATUS"
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            log verbose "Response body: $RESPONSE_BODY"
            if [ $HTTP_STATUS != 200 ]; then
                log error "Failed to get the $NAME environment ID. $RESPONSE"
                return 1;
            else
                log success "The ID of the $ENVIRONMENT_NAME environment was succesfully retrieved"
            fi
            ENVIRONMENT_ID=$(echo "$RESPONSE_BODY" | jq '.value[] | select(.name == "'"$ENVIRONMENT_NAME"'") | .id' | tr -d '"')  
            log verbose "ENVIRONMENT_ID: $ENVIRONMENT_ID"
            log "Associate the $NAME security group to the $ENVIRONMENT_NAME environment"
            log verbose "Request: '[{"roleName": "'"$ROLE"'","userId": "'"$SECURITY_GROUP_ID"'"}]'"
            log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/securityroles/scopes/distributedtask.environmentreferencerole/roleassignments/resources/$PROJECT_ID"_"$ENVIRONMENT_ID?api-version=5.0-preview.1"
            RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --request PUT \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '[{"roleName": "'"$ROLE"'","userId": "'"$SECURITY_GROUP_ID"'"}]' \
                "https://dev.azure.com/$ORG_NAME/_apis/securityroles/scopes/distributedtask.environmentreferencerole/roleassignments/resources/$PROJECT_ID"_"$ENVIRONMENT_ID?api-version=5.0-preview.1")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            log verbose "Response code: $HTTP_STATUS"
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            log verbose "Response body: $RESPONSE_BODY"
            if [ $HTTP_STATUS != 200 ]; then
                log error "Failed to associate the $NAME security group to the $ENVIRONMENT_NAME environment. $RESPONSE"
                return 1;
            else
                log success "The $NAME security group was successfully associated to the $ENVIRONMENT_NAME environment"
            fi
        done
    done
}
function create_service_endpoints {
    local ORG_ID=$1
    local ORG_NAME=$2
    local PROJECT_NAME=$3
    local DEFAULT_JSON=$4
    log "Create service endpoints in $PROJECT_NAME project"
    log "Read the list of existing service endpoints"
    log verbose 'Request: {"contributionIds":["ms.vss-distributed-task.resources-hub-query-data-provider"],"dataProviderContext":{"properties":{"resourceFilters":{"createdBy":[],"resourceType":[],"searchText":""},"sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/adminservices","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"Sample","adminPivot":"adminservices","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/serviceendpoints?api-version=5.1-preview.1"
    RESPONSE=$(curl --silent \
            --request POST \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            --data-raw '{"contributionIds":["ms.vss-distributed-task.resources-hub-query-data-provider"],"dataProviderContext":{"properties":{"resourceFilters":{"createdBy":[],"resourceType":[],"searchText":""},"sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/adminservices","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"Sample","adminPivot":"adminservices","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
            "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    SERVICE_ENDPOINT_LIST_RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $SERVICE_ENDPOINT_LIST_RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Failed to get the list of existing service endpoints. $RESPONSE"
        return 1;
    else
        log success "The list of existing service endpoints was succesfully retrieved"
    fi
    for SERVICE_ENDPOINT in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.service_endpoints[] | @base64'); do
        SERVICE_ENDPOINT_JSON=$(echo "$SERVICE_ENDPOINT" | base64 --decode | jq -r '.')
        log verbose "SERVICE_ENDPOINT_JSON: $SERVICE_ENDPOINT_JSON"
        log "Creating Azure service endpoint"
        for AZURE_SERVICE_ENDPOINT in $(echo "$SERVICE_ENDPOINT_JSON" | jq -r '.azurerm[] | @base64'); do
            AZURE_SERVICE_ENDPOINT_JSON=$(echo "$AZURE_SERVICE_ENDPOINT" | base64 --decode | jq -r '.')
            log verbose "AZURE_SERVICE_ENDPOINT_JSON: $AZURE_SERVICE_ENDPOINT_JSON"
            NAME=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.name')
            log verbose "NAME: $NAME"
            TENANT_ID=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.tenant_id')
            log verbose "TENANT_ID: $TENANT_ID"
            SUBSCRIPTION_ID=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.subscription_id')
            log verbose "SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
            SUBSCRIPTION_NAME=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.subscription_name')
            log verbose "SUBSCRIPTION_NAME: $SUBSCRIPTION_NAME"
            SERVICE_PRINCIPAL_ID=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.service_principal_id')
            log verbose "SERVICE_PRINCIPAL_ID: $SERVICE_PRINCIPAL_ID"
            # AZURE_SERVICE_CONNECTION_SERVICE_PRINCIPAL_KEY=$(echo "$AZURE_SERVICE_ENDPOINT_JSON" | jq -r '.service_principal_key')
            log "Checking if $NAME service endpoint already exists"      
            if [ $(echo "$SERVICE_ENDPOINT_LIST_RESPONSE_BODY" | jq '.dataProviders."ms.vss-distributed-task.resources-hub-query-data-provider".resourceItems[] | select(.name == "'"$NAME"'") | length') -gt 0 ]; then
                log "$NAME service endpoint already exists. Skipping..."
                continue
            else
                log "$NAME service endpoint does not exist."
            fi
            log "Creating $NAME service endpoint"
            log verbose "Command: az devops service-endpoint azurerm create --azure-rm-service-principal-id $SERVICE_PRINCIPAL_ID --azure-rm-subscription-id $SUBSCRIPTION_ID --azure-rm-subscription-name $SUBSCRIPTION_NAME --azure-rm-tenant-id $TENANT_ID --name $NAME --organization https://dev.azure.com/$ORG_NAME --project $PROJECT_NAME --output json"
            RESPONSE=$(az devops service-endpoint azurerm create --azure-rm-service-principal-id "$SERVICE_PRINCIPAL_ID" --azure-rm-subscription-id "$SUBSCRIPTION_ID" --azure-rm-subscription-name "$SUBSCRIPTION_NAME" --azure-rm-tenant-id "$TENANT_ID" --name "$NAME" --organization "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME" --output json)
            if [ $? -eq 0 ]; then
                log success "The $NAME service endpoint was successfully created"
            else
                log error "Error during the creation of the $NAME service endpoint"
                return 1
            fi
        done
        for GITHUB_SERVICE_ENDPOINT in $(echo "$SERVICE_ENDPOINT_JSON" | jq -r '.github[] | @base64'); do
            GITHUB_SERVICE_ENDPOINT_JSON=$(echo "$GITHUB_SERVICE_ENDPOINT" | base64 --decode | jq -r '.')
            log verbose "GITHUB_SERVICE_ENDPOINT_JSON: $GITHUB_SERVICE_ENDPOINT_JSON"
            NAME=$(echo "$GITHUB_SERVICE_ENDPOINT_JSON" | jq -r '.name')
            log verbose "NAME: $NAME"
            URL=$(echo "$GITHUB_SERVICE_ENDPOINT_JSON" | jq -r '.url')
            log verbose "URL: $URL"
            # AZURE_DEVOPS_EXT_GITHUB_PAT=$(echo "$GITHUB_SERVICE_ENDPOINT_JSON" | jq -r '.token')
            log "Checking if $NAME service endpoint already exists"  
            if [[ $(echo "$SERVICE_ENDPOINT_LIST_RESPONSE_BODY" | jq '.dataProviders."ms.vss-distributed-task.resources-hub-query-data-provider".resourceItems[] | select(.name == "'"$NAME"'") | length') -gt 0 ]]; then
                log "$NAME service endpoint already exists. Skipping..."
                continue
            else
                log "$NAME service endpoint does not exist."
            fi
            log "Creating $NAME service endpoint"
            log verbose "Command: az devops service-endpoint github create --github-url $URL --name $NAME --organization https://dev.azure.com/$ORG_NAME --project $PROJECT_NAME --output json"
            RESPONSE=$(az devops service-endpoint github create --github-url "$URL" --name "$NAME" --organization "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME" --output json)
            if [ $? -eq 0 ]; then
                log success "The $NAME service endpoint was successfully created"
            else
                log error "Error during the creation of the $NAME service endpoint"
                return 1
            fi
        done
    done
}
function create_agent_pools {
    local ORG_ID=$1
    local ORG_NAME=$2
    local PROJECT_NAME=$3
    local PROJECT_ID=$4
    local DEFAULT_JSON=$5
    log "Creating agent pools in $PROJECT_NAME project"
    log "Get the list of agent pools"
    log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/queues?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/queues?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response code: $HTTP_STATUS"
    AGENT_POOL_LIST_RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $AGENT_POOL_LIST_RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Failed to get the list of existing pools. $RESPONSE"
        return 1;
    else
        log success "The list of existing pools was succesfully retrieved"
    fi
    for AGENT_POOL in $(echo "$DEFAULT_JSON" | jq -r '.pipeline.agent_pools[] | @base64'); do
        AGENT_POOL_JSON=$(echo "$AGENT_POOL" | base64 --decode | jq -r '.')
        log verbose "AGENT_POOL_JSON: $AGENT_POOL_JSON"
        log "Creating self-hosted agents"
        for SELF_HOSTED_AGENT_POOL in $(echo "$AGENT_POOL_JSON" | jq -r '.self_hosted[] | @base64'); do
            SELF_HOSTED_AGENT_POOL_JSON=$(echo "$SELF_HOSTED_AGENT_POOL" | base64 --decode | jq -r '.')
            log verbose "SELF_HOSTED_AGENT_POOL_JSON: $SELF_HOSTED_AGENT_POOL_JSON"
            NAME=$(echo "$SELF_HOSTED_AGENT_POOL_JSON" | jq -r '.name')
            log verbose "NAME: $NAME"
            AUTH_PIPELINES=$(echo "$AGENT_POOL_JSON" | jq -r '.authorize_pipelines')
            log verbose "AUTH_PIPELINES: $AUTH_PIPELINES"
            log "Check if the $NAME agent pool already exists"
            if [[ $(echo "$AGENT_POOL_LIST_RESPONSE_BODY" | jq '.value[] | select(.name == "'"$NAME"'") | length') -gt 0 ]]; then
                log warning "$NAME agent pool already exists. Skipping..."
                continue
            else
                log "$NAME agent pool does not exist."
            fi
            log "Create $NAME self-hosted agent pool"
            log verbose 'Request: {"name": "'"$NAME"'"}'  
            log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/queues?authorizePipelines=$AUTH_PIPELINES&api-version=5.0-preview.1"
            RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"name": "'"$NAME"'"}' \
                "https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/queues?authorizePipelines=$AUTH_PIPELINES&api-version=5.0-preview.1")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            log verbose "Response code: $HTTP_STATUS"
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            log verbose "Response body: $RESPONSE_BODY"
            if [ $HTTP_STATUS != 200 ]; then
                log error "Failed to create the $NAME agent pool. $RESPONSE"
                return 1;
            else
                log success "The $NAME agent pool was successfully created"
            fi
        done
        log "Creating azure virtual machine scale set agents"
        for AZURE_HOSTED_AGENT_POOL in $(echo "$AGENT_POOL_JSON" | jq -r '.azure_virtual_machine_scale_sets[] | @base64'); do
            AZURE_HOSTED_AGENT_POOL_JSON=$(echo "$AZURE_HOSTED_AGENT_POOL" | base64 --decode | jq -r '.')
            log verbose "AZURE_HOSTED_AGENT_POOL_JSON: $AZURE_HOSTED_AGENT_POOL_JSON"
            NAME=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.name')
            log verbose "NAME: $NAME"
            AUTH_PIPELINES=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.authorize_pipelines')
            log verbose "AUTH_PIPELINES: $AUTH_PIPELINES"
            SERVICE_ENDPOINT_NAME=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.service_endpoint_name')
            log verbose "SERVICE_ENDPOINT_NAME: $SERVICE_ENDPOINT_NAME"
            AUTO_PROVISIONING_PROJECT_POOLS=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.auto_provision_project_pools')
            log verbose "AUTO_PROVISIONING_PROJECT_POOLS: $AUTO_PROVISIONING_PROJECT_POOLS"
            AZURE_RESOURCE_GROUP_NAME=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.azure_resource_group_name')
            log verbose "AZURE_RESOURCE_GROUP_NAME: $AZURE_RESOURCE_GROUP_NAME"
            AZURE_VIRTUAL_MACHINE_SCALE_SET_NAME=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.azure_virtual_machine_scale_set_name')
            log verbose "AZURE_VIRTUAL_MACHINE_SCALE_SET_NAME: $AZURE_VIRTUAL_MACHINE_SCALE_SET_NAME"
            DESIRED_IDLE=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.desired_idle')
            log verbose "DESIRED_IDLE: $DESIRED_IDLE"
            MAX_CAPACITY=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.max_capacity')
            log verbose "MAX_CAPACITY: $MAX_CAPACITY"
            OS_TYPE=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.os_type')
            log verbose "OS_TYPE: $OS_TYPE"
            MAX_SAVED_NODE_COUNT=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.max_saved_node_count')
            log verbose "MAX_SAVED_NODE_COUNT: $MAX_SAVED_NODE_COUNT"
            RECYCLE_AFTER_EACH_USE=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.recycle_after_each_use')
            log verbose "RECYCLE_AFTER_EACH_USE: $RECYCLE_AFTER_EACH_USE"
            TIME_TO_LIVE_MINUTES=$(echo "$AZURE_HOSTED_AGENT_POOL_JSON" | jq -r '.time_to_live_minutes')
            log verbose "TIME_TO_LIVE_MINUTES: $TIME_TO_LIVE_MINUTES"
            log "Check if the $NAME agent pool already exists"
            if [[ $(echo "$AGENT_POOL_LIST_RESPONSE_BODY" | jq '.value[] | select(.name == "'"$NAME"'") | length') -gt 0 ]]; then
                log warning "$NAME agent pool already exists. Skipping..."
                continue
            else
                log "$NAME agent pool does not exist."
            fi
            log "Read the list of existing service endpoints. Needed to configure the VMSS."
            log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_ID/_apis/serviceendpoint/endpoints?type=azurerm&api-version=6.0-preview.4"
            RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                "https://dev.azure.com/$ORG_NAME/$PROJECT_ID/_apis/serviceendpoint/endpoints?type=azurerm&api-version=6.0-preview.4")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            log verbose "Response code: $HTTP_STATUS"
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            log verbose "Response body: $RESPONSE_BODY"
            if [ $HTTP_STATUS != 200 ]; then
                log error "Failed to get the list of existing service endpoints. $RESPONSE"
                return 1;
            else
                log success "The list of existing service endpoints was succesfully retrieved"
            fi
            SERVICE_ENDPOINT=$(echo "$RESPONSE_BODY" | jq -r '.value[] | select(.name == "'"$SERVICE_ENDPOINT_NAME"'")')
            log verbose "SERVICE_ENDPOINT: $SERVICE_ENDPOINT"
            SERVICE_ENDPOINT_ID=$(echo "$SERVICE_ENDPOINT" | jq -r '.id')
            log verbose "SERVICE_ENDPOINT_ID: $SERVICE_ENDPOINT_ID"
            SERVICE_ENDPOINT_TENANT_ID=$(echo "$SERVICE_ENDPOINT" | jq -r '.authorization.parameters.tenantid')
            log verbose "SERVICE_ENDPOINT_TENANT_ID: $SERVICE_ENDPOINT_TENANT_ID"
            SERVICE_ENDPOINT_SCOPE=$(echo "$SERVICE_ENDPOINT" | jq -r '.serviceEndpointProjectReferences[] | select(.projectReference.name == "'"$PROJECT_NAME"'") | .projectReference.id')
            log verbose "SERVICE_ENDPOINT_SCOPE: $SERVICE_ENDPOINT_SCOPE"
            SERVICE_ENDPOINT_SUBSCRIPTION_ID=$(echo "$SERVICE_ENDPOINT" | jq -r '.data.subscriptionId')
            log verbose "SERVICE_ENDPOINT_SUBSCRIPTION_ID: $SERVICE_ENDPOINT_SUBSCRIPTION_ID"
            log "Create $NAME virtual machine scale set agent pool"
            log verbose 'Request {"agentInteractiveUI":false,"azureId":"/subscriptions/'$SERVICE_ENDPOINT_SUBSCRIPTION_ID'/resourceGroups/'$AZURE_RESOURCE_GROUP_NAME'/providers/Microsoft.Compute/virtualMachineScaleSets/'$AZURE_VIRTUAL_MACHINE_SCALE_SET_NAME'","desiredIdle":'$DESIRED_IDLE',"maxCapacity":'$MAX_CAPACITY',"osType":'$OS_TYPE',"maxSavedNodeCount":'$MAX_SAVED_NODE_COUNT',"recycleAfterEachUse":'$RECYCLE_AFTER_EACH_USE',"serviceEndpointId":"'$SERVICE_ENDPOINT_ID'","serviceEndpointScope":"'$SERVICE_ENDPOINT_SCOPE'","timeToLiveMinutes":'$TIME_TO_LIVE_MINUTES'}'
            log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_ID/_apis/distributedtask/pools?api-version=6.0-preview.1"
            RESPONSE=$(curl --silent \
                --request POST \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"agentInteractiveUI":false,"azureId":"/subscriptions/'$SERVICE_ENDPOINT_SUBSCRIPTION_ID'/resourceGroups/'$AZURE_RESOURCE_GROUP_NAME'/providers/Microsoft.Compute/virtualMachineScaleSets/'$AZURE_VIRTUAL_MACHINE_SCALE_SET_NAME'","desiredIdle":'$DESIRED_IDLE',"maxCapacity":'$MAX_CAPACITY',"osType":'$OS_TYPE',"maxSavedNodeCount":'$MAX_SAVED_NODE_COUNT',"recycleAfterEachUse":'$RECYCLE_AFTER_EACH_USE',"serviceEndpointId":"'$SERVICE_ENDPOINT_ID'","serviceEndpointScope":"'$SERVICE_ENDPOINT_SCOPE'","timeToLiveMinutes":'$TIME_TO_LIVE_MINUTES'}' \
                "https://dev.azure.com/$ORG_NAME/_apis/distributedtask/elasticpools?poolName=$NAME&authorizeAllPipelines=$AUTH_PIPELINES&autoProvisionProjectPools=$AUTO_PROVISIONING_PROJECT_POOLS&projectId=$PROJECT_ID&api-version=6.1-preview.1")
            HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
            log verbose "Response code: $HTTP_STATUS"
            RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
            log verbose "Response body: $RESPONSE_BODY"
            if [ $HTTP_STATUS != 200 ]; then
                log error "Failed to create the $NAME agent pool. $RESPONSE"
                return 1;
            else
                log success "The $NAME agent pool was successfully created"
            fi
        done
    done 
}
function create_repositories_branch_protection_policies {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    local DEFAULT_JSON=$3
    log "Creating branch protection policies in the $PROJECT_NAME project"

    log "Creating Approver count policies"
    for APPROVER_COUNT_POLICY in $(echo "$DEFAULT_JSON" | jq -r '.repository.policies.approver_count[] | @base64'); do
        APPROVER_COUNT_POLICY_JSON=$(echo "$APPROVER_COUNT_POLICY" | base64 --decode | jq -r '.')
        log verbose "APPROVER_COUNT_POLICY_JSON: $APPROVER_COUNT_POLICY_JSON"
        REPO_NAME=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.repository_name')
        log verbose "REPO_NAME: $REPO_NAME"
        BRANCH_NAME=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.branch_name')
        log verbose "BRANCH_NAME: $BRANCH_NAME"
        BRANCH_MATCH_TYPE=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.branch_match_type')
        log verbose "BRANCH_MATCH_TYPE: $BRANCH_MATCH_TYPE"
        ALLOW_DOWNVOTES=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.allow_downvotes')
        log verbose "ALLOW_DOWNVOTES: $ALLOW_DOWNVOTES"
        CREATOR_VOTE_COUNT=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.creator_vote_counts')
        log verbose "CREATOR_VOTE_COUNT: $CREATOR_VOTE_COUNT"
        MINIMAL_APPROVER_COUNT=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.minimum_approver_count')
        log verbose "MINIMAL_APPROVER_COUNT: $MINIMAL_APPROVER_COUNT"
        RESET_ON_SOURCE_PUSH=$(echo "$APPROVER_COUNT_POLICY_JSON" | jq -r '.reset_on_source_push')
        log verbose "RESET_ON_SOURCE_PUSH: $RESET_ON_SOURCE_PUSH"
        log "Reading ID of the $REPO_NAME repository"
        log verbose "Command: az repos show --repository $REPO_NAME --query id --output tsv --org https://dev.azure.com/$ORG_NAME --project $PROJECT_NAME"
        REPO_ID=$(az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME")
        if [ $? -eq 0 ]; then
            log success "The ID of the $REPO_NAME repository is $REPO_ID"
        else
            log error  "Error during the reading of the property ID of the $REPO_NAME"
            return 1
        fi     
        REFNAME="refs/heads/$( if [ $BRANCH_MATCH_TYPE == "exact" ]; then echo "$BRANCH_NAME"; else echo "$BRANCH_NAME/*"; fi )"
        log verbose "REFNAME: $REFNAME"
        log verbose 'Request: {"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
        log verbose "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
        RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
                "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
        log verbose "Response body: $RESPONSE_BODY"
        if [ $HTTP_STATUS != 200 ]; then
            log error "Failed to retrieve the list of existing approver count policies. $RESPONSE"
            return 1;
        else
            log success "The list of existing approver count policies was successfully retrieved"
        fi
        if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies | length > 0') == true ]; then
            log warning "The approver count policy already exists. Skipping..."
            # MINIMUM_APPROVER_COUNT=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.minimumApproverCount')
            # CREATOR_VOTE_COUNTS=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.creatorVoteCounts')
            # ALLOW_DOWNVOTES=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.allowDownvotes')
            # RESET_ON_SOURCE_PUSH=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.resetOnSourcePush')
            # REQUIRE_VOTE_ON_LAST_ITERATION=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.requireVoteOnLastIteration')
            # RESET_REJECTIONS_ON_SOURCE_PUSH=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.resetRejectionsOnSourcePush')
            # BLOCK_LAST_PUSHER_VORE=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.blockLastPusherVote')
            # # REF_NAME=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.scope.refName')
            # MATCH_KIND=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.scope.matchKind')
            # REPOSITORY_ID=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].settings.scope.repositoryId')
            # IS_ENABLED=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].isEnabled')
            # IS_BLOCKING=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4906e5d171dd".currentScopePolicies[0].isBlocking')
            continue
        else 
            log "Creating approver count policy for the $BRANCH_NAME in $REPO_NAME repository"
        fi
        log "Creating approver count policy for the $BRANCH_NAME in $REPO_NAME repository"
        log verbose "Command: az repos policy approver-count create --branch-match-type $BRANCH_MATCH_TYPE --allow-downvotes $ALLOW_DOWNVOTES --blocking true --branch $BRANCH_NAME --creator-vote-counts $CREATOR_VOTE_COUNT --enabled true --minimum-approver-count $MINIMAL_APPROVER_COUNT --repository-id $REPO_ID --reset-on-source-push $RESET_ON_SOURCE_PUSH --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME""
        az repos policy approver-count create --branch-match-type $BRANCH_MATCH_TYPE --allow-downvotes $ALLOW_DOWNVOTES --blocking true --branch $BRANCH_NAME --creator-vote-counts $CREATOR_VOTE_COUNT --enabled true --minimum-approver-count $MINIMAL_APPROVER_COUNT --repository-id $REPO_ID --reset-on-source-push $RESET_ON_SOURCE_PUSH --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME"
        if [ $? -eq 0 ]; then
            log success "Approver count policy was added to $BRANCH_NAME in $REPO_NAME repository"
        else
            log error "Approver count policy was not added to $BRANCH_NAME in $REPO_NAME repository"
            return 1
        fi
    done
    
    # out "Creating case enforcement policies"
    # not working
    # for CASE_ENFORCEMENT_POLICY in $(echo "$DEFAULT_JSON" | jq -r '.repository.policies.case_enforcement[] | @base64'); do
    #     CASE_ENFORCEMENT_POLICY_JSON=$(echo "$CASE_ENFORCEMENT_POLICY" | base64 --decode | jq -r '.')
    #     REPO_NAME=$(echo "$CASE_ENFORCEMENT_POLICY_JSON" | jq -r '.repository_name')
    #     out "Reading ID of the $REPO_NAME repository"
    #     REPO_ID=$(az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME")
    #     if [ $? -eq 0 ]; then
    #         out success "The ID of the $REPO_NAME repository is $REPO_ID"
    #     else
    #         out error  "Error during the reading of the property ID of the $REPO_NAME"
    #         exit 1
    #     fi
    #     out "Creating case enforcement policy for the $REPO_NAME repository"
    #     az repos policy case-enforcement  create --blocking true --enabled true --repository-id $REPO_ID --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME"
    #     if [ $? -eq 0 ]; then
    #         out success "Case enforcement policy was added to the $REPO_NAME repository"
    #     else
    #         out error "Case enforcement policy was not added to the $REPO_NAME repository"
    #         exit 1
    #     fi
    # done

    log "Creating comment required policies"
    for COMMENT_REQUIRED_POLICY in $(echo "$DEFAULT_JSON" | jq -r '.repository.policies.comment_required[] | @base64'); do
        COMMENT_REQUIRED_POLICY_JSON=$(echo "$COMMENT_REQUIRED_POLICY" | base64 --decode | jq -r '.')
        log verbose "COMMENT_REQUIRED_POLICY_JSON: $COMMENT_REQUIRED_POLICY_JSON"
        REPO_NAME=$(echo "$COMMENT_REQUIRED_POLICY_JSON" | jq -r '.repository_name')
        log verbose "REPO_NAME: $REPO_NAME"
        BRANCH_NAME=$(echo "$COMMENT_REQUIRED_POLICY_JSON" | jq -r '.branch_name')
        log verbose "BRANCH_NAME: $BRANCH_NAME"
        BRANCH_MATCH_TYPE=$(echo "$COMMENT_REQUIRED_POLICY_JSON" | jq -r '.branch_match_type')
        log verbose "BRANCH_MATCH_TYPE: $BRANCH_MATCH_TYPE"
        log "Reading ID of the $REPO_NAME repository"
        log verbose "Command: az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME""
        REPO_ID=$(az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME")
        log verbose "REPO_ID: $REPO_ID"
        if [ $? -eq 0 ]; then
            log success "The ID of the $REPO_NAME repository is $REPO_ID"
        else
            log error  "Error during the reading of the property ID of the $REPO_NAME"
            return 1
        fi
        # Comment requirements
        REFNAME="refs/heads/$( if [ $BRANCH_MATCH_TYPE == "exact" ]; then echo "$BRANCH_NAME"; else echo "$BRANCH_NAME/*"; fi )"
        log verbose "REFNAME: $REFNAME"
        log verbose 'Request: {"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
        log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0"
        RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
                "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
        log verbose "Response body: $RESPONSE_BODY"
        if [ $HTTP_STATUS != 200 ]; then
            log error "Failed to retrieve the list of existing approver count policies. $RESPONSE"
            exit 1;
        else
            log success "The list of existing approver count policies was successfully retrieved"
        fi
        if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."c6a1889d-b943-4856-b76f-9e46bb6b0df2".currentScopePolicies | length > 0') == true ]; then
            log "The approver count policy already exists. Skipping..."
            # REF_NAME=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."c6a1889d-b943-4856-b76f-9e46bb6b0df2".currentScopePolicies[0].settings.scope.refName')
            # MATCH_KIND=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."c6a1889d-b943-4856-b76f-9e46bb6b0df2".currentScopePolicies[0].settings.scope.matchKind')
            # REPOSITORY_ID=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."c6a1889d-b943-4856-b76f-9e46bb6b0df2".currentScopePolicies[0].settings.scope.repositoryId')
            # IS_ENABLED=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."c6a1889d-b943-4856-b76f-9e46bb6b0df2".currentScopePolicies[0].isEnabled')
            # IS_BLOCKING=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."c6a1889d-b943-4856-b76f-9e46bb6b0df2".currentScopePolicies[0].isBlocking')
            continue
        fi
        log "Creating comment required policy for the $BRANCH_NAME in $REPO_NAME repository"
        log verbose "Command: az repos policy comment-required create --branch-match-type $BRANCH_MATCH_TYPE --branch $BRANCH_NAME --blocking true --enabled true --repository-id $REPO_ID --project \"$PROJECT_NAME\" --organization \"https://dev.azure.com/$ORG_NAME\""
        az repos policy comment-required create --branch-match-type $BRANCH_MATCH_TYPE --branch $BRANCH_NAME --blocking true --enabled true --repository-id $REPO_ID --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME"
        if [ $? -eq 0 ]; then
            log success "Comment required policy was added to $BRANCH_NAME in $REPO_NAME repository"
        else
            log error "Comment required policy was not added to $BRANCH_NAME in $REPO_NAME repository"
            return 1
        fi
    done

    log "Creating merge strategy policies"
    for MERGE_STRATEGY_POLICY in $(echo "$DEFAULT_JSON" | jq -r '.repository.policies.merge_strategy[] | @base64'); do
        MERGE_STRATEGY_POLICY_JSON=$(echo "$MERGE_STRATEGY_POLICY" | base64 --decode | jq -r '.')
        log verbose "MERGE_STRATEGY_POLICY_JSON: $MERGE_STRATEGY_POLICY_JSON"
        REPO_NAME=$(echo "$MERGE_STRATEGY_POLICY_JSON" | jq -r '.repository_name')
        log verbose "REPO_NAME: $REPO_NAME"
        BRANCH_NAME=$(echo "$MERGE_STRATEGY_POLICY_JSON" | jq -r '.branch_name')
        log verbose "BRANCH_NAME: $BRANCH_NAME"
        BRANCH_MATCH_TYPE=$(echo "$MERGE_STRATEGY_POLICY_JSON" | jq -r '.branch_match_type')
        log verbose "BRANCH_MATCH_TYPE: $BRANCH_MATCH_TYPE"
        ALLOW_NO_FAST_FORWARD=$(echo "$MERGE_STRATEGY_POLICY_JSON" | jq -r '.allow_no_fast_forward')
        log verbose "ALLOW_NO_FAST_FORWARD: $ALLOW_NO_FAST_FORWARD"
        ALLOW_REBASE=$(echo "$MERGE_STRATEGY_POLICY_JSON" | jq -r '.allow_rebase')
        log verbose "ALLOW_REBASE: $ALLOW_REBASE"
        ALLOW_REBASE_MERGE=$(echo "$MERGE_STRATEGY_POLICY_JSON" | jq -r '.allow_rebase_merge')
        log verbose "ALLOW_REBASE_MERGE: $ALLOW_REBASE_MERGE"
        ALLOW_SQUASH=$(echo "$MERGE_STRATEGY_POLICY_JSON" | jq -r '.allow_squash')
        log verbose "ALLOW_SQUASH: $ALLOW_SQUASH"
        log "Reading ID of the $REPO_NAME repository"
        log verbose "Command: az repos show --repository \"$REPO_NAME\" --query id --output tsv --org \"https://dev.azure.com/$ORG_NAME\" --project \"$PROJECT_NAME\""
        REPO_ID=$(az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME")
        log verbose "REPO_ID: $REPO_ID"
        if [ $? -eq 0 ]; then
            log success "The ID of the $REPO_NAME repository is $REPO_ID"
        else
            log error  "Error during the reading of the property ID of the $REPO_NAME"
            return 1
        fi
        # "Check if the pull request has any active comments" = "fa4e907d-c16b-4a4c-9dfa-4916e5d171ab"
        REFNAME="refs/heads/$( if [ $BRANCH_MATCH_TYPE == "exact" ]; then echo "$BRANCH_NAME"; else echo "$BRANCH_NAME/*"; fi )"
        log verbose "REFNAME: $REFNAME"
        log 'Request: {"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
        log "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
        RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
                "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
        log verbose "Response body: $RESPONSE_BODY"
        if [ $HTTP_STATUS != 200 ]; then
            log error "Failed to retrieve the list of existing comment required policies. $RESPONSE"
            return 1;
        else
            log success "The list of existing comment required policies was successfully retrieved"
        fi
        if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies | length > 0') == true ]; then
            log warning "The comment required policy already exists. Skipping..."
            # if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings | has("allowNoFastForward")') == "true" ]; then
            #     ALLOW_NO_FAST_FORWARD=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings.allowNoFastForward')
            # else
            #     ALLOW_NO_FAST_FORWARD="null"
            # fi
            # if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings | has("allowRebase")') == "true" ]; then
            #     ALLOW_REBASE=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings.allowRebase')
            # else
            #     ALLOW_REBASE="null"
            # fi
            # if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings | has("allowRebaseMerge")') == "true" ]; then
            #     ALLOW_REBASE_MERGE=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings.allowRebaseMerge')
            # else
            #     ALLOW_REBASE_MERGE="null"
            # fi
            # if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings | has("allowSquash")') == "true" ]; then
            #     ALLOW_SQUASH=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings.allowSquash')
            # else
            #     ALLOW_SQUASH="null"
            # fi
            # REF_NAME=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings.scope.refName')
            # MATCH_KIND=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings.scope.matchKind')
            # REPOSITORY_ID=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].settings.scope.repositoryId')
            # IS_ENABLED=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].isEnabled')
            # IS_BLOCKING=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fa4e907d-c16b-4a4c-9dfa-4916e5d171ab".currentScopePolicies[0].isBlocking')
            continue
        fi
        log "Creating merge strategy policy for the $BRANCH_NAME in $REPO_NAME repository"
        log verbose "az repos policy merge-strategy create --allow-no-fast-forward $ALLOW_NO_FAST_FORWARD --allow-rebase $ALLOW_REBASE --allow-rebase-merge $ALLOW_REBASE_MERGE --allow-squash $ALLOW_SQUASH --branch-match-type $BRANCH_MATCH_TYPE --branch $BRANCH_NAME --blocking true --enabled true --repository-id $REPO_ID --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME""
        az repos policy merge-strategy create \
            --allow-no-fast-forward $ALLOW_NO_FAST_FORWARD \
            --allow-rebase $ALLOW_REBASE \
            --allow-rebase-merge $ALLOW_REBASE_MERGE \
            --allow-squash $ALLOW_SQUASH \
            --branch-match-type $BRANCH_MATCH_TYPE \
            --branch $BRANCH_NAME \
            --blocking true \
            --enabled true \
            --repository-id $REPO_ID \
            --project "$PROJECT_NAME" \
            --organization "https://dev.azure.com/$ORG_NAME"
        if [ $? -eq 0 ]; then
            log success "Comment required policy was added to $BRANCH_NAME in $REPO_NAME repository"
        else
            log error "Comment required policy was not added to $BRANCH_NAME in $REPO_NAME repository"
            return 1
        fi
    done

    log "Creating work-item linking policies"
    for WORK_ITEM_LINKING_POLICY in $(echo "$DEFAULT_JSON" | jq -r '.repository.policies.work_item_linking[] | @base64'); do
        WORK_ITEM_LINKING_POLICY_JSON=$(echo "$WORK_ITEM_LINKING_POLICY" | base64 --decode | jq -r '.')
        log verbose "WORK_ITEM_LINKING_POLICY_JSON: $WORK_ITEM_LINKING_POLICY_JSON"
        REPO_NAME=$(echo "$WORK_ITEM_LINKING_POLICY_JSON" | jq -r '.repository_name')
        log verbose "REPO_NAME: $REPO_NAME"
        BRANCH_NAME=$(echo "$WORK_ITEM_LINKING_POLICY_JSON" | jq -r '.branch_name')
        log verbose "BRANCH_NAME: $BRANCH_NAME"
        BRANCH_MATCH_TYPE=$(echo "$WORK_ITEM_LINKING_POLICY_JSON" | jq -r '.branch_match_type')
        log verbose "BRANCH_MATCH_TYPE: $BRANCH_MATCH_TYPE"
        log "Reading ID of the $REPO_NAME repository"
        log verbose "Command: az repos show --repository \"$REPO_NAME\" --query id --output tsv --org \"https://dev.azure.com/$ORG_NAME\" --project \"$PROJECT_NAME\""
        REPO_ID=$(az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME")
        log verbose "REPO_ID: $REPO_ID"
        if [ $? -eq 0 ]; then
            log success "The ID of the $REPO_NAME repository is $REPO_ID"
        else
            log error  "Error during the reading of the property ID of the $REPO_NAME"
            return 1
        fi
        REFNAME="refs/heads/$( if [ $BRANCH_MATCH_TYPE == "exact" ]; then echo "$BRANCH_NAME"; else echo "$BRANCH_NAME/*"; fi )"
        log verbose "REFNAME: $REFNAME"
        log verbose 'Request: {"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
        log verbose "Url: https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/contribution/hierarchyquery"
        RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
                "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
        log verbose "Response body: $RESPONSE_BODY"
        if [ $HTTP_STATUS != 200 ]; then
            log error "Failed to retrieve the list of existing approver count policies. $RESPONSE"
            return 1;
        else
            log success "The list of existing approver count policies was successfully retrieved"
        fi
        if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e".currentScopePolicies | length > 0') == true ]; then
            log "The approver count policy already exists. Skipping..."
            # REF_NAME=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e".currentScopePolicies[0].settings.scope.refName')
            # MATCH_KIND=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e".currentScopePolicies[0].settings.scope.matchKind')
            # REPOSITORY_ID=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e".currentScopePolicies[0].settings.scope.repositoryId')
            # IS_ENABLED=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e".currentScopePolicies[0].isEnabled')
            # IS_BLOCKING=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e".currentScopePolicies[0].isBlocking')
            continue
        fi
        log "Creating work-item linking policy for the $BRANCH_NAME in $REPO_NAME repository"
        log verbose "Command: az repos policy work-item-linking create --branch-match-type $BRANCH_MATCH_TYPE --branch $BRANCH_NAME --blocking true --enabled true --repository-id $REPO_ID --project \"$PROJECT_NAME\" --organization \"https://dev.azure.com/$ORG_NAME\""
        az repos policy work-item-linking create --branch-match-type $BRANCH_MATCH_TYPE --branch $BRANCH_NAME --blocking true --enabled true --repository-id $REPO_ID --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME"
        if [ $? -eq 0 ]; then
            log success "Work-item linking policy was added to $BRANCH_NAME in $REPO_NAME repository"
        else
            log error "Work-item linking policy was not added to $BRANCH_NAME in $REPO_NAME repository"
            return 1
        fi
    done

    log "Creating required reviewers policies"
    for REQUIRED_REVIEWERS_POLICY in $(echo "$DEFAULT_JSON" | jq -r '.repository.policies.required_reviewer[] | @base64'); do
        REQUIRED_REVIEWERS_POLICY_JSON=$(echo "$REQUIRED_REVIEWERS_POLICY" | base64 --decode | jq -r '.')
        log verbose "REQUIRED_REVIEWERS_POLICY_JSON: $REQUIRED_REVIEWERS_POLICY_JSON"
        REPO_NAME=$(echo "$REQUIRED_REVIEWERS_POLICY_JSON" | jq -r '.repository_name')
        log verbose "REPO_NAME: $REPO_NAME"
        BRANCH_NAME=$(echo "$REQUIRED_REVIEWERS_POLICY_JSON" | jq -r '.branch_name')
        log verbose "BRANCH_NAME: $BRANCH_NAME"
        BRANCH_MATCH_TYPE=$(echo "$REQUIRED_REVIEWERS_POLICY_JSON" | jq -r '.branch_match_type')
        log verbose "BRANCH_MATCH_TYPE: $BRANCH_MATCH_TYPE"
        REQUIRED_REVIEWER_EMAILS=$(echo "$REQUIRED_REVIEWERS_POLICY_JSON" | jq -r '.required_reviewer_emails') 
        log verbose "REQUIRED_REVIEWER_EMAILS: $REQUIRED_REVIEWER_EMAILS"
        MESSAGE=$(echo "$REQUIRED_REVIEWERS_POLICY_JSON" | jq -r '.message')
        log verbose "MESSAGE: $MESSAGE"
        PATH_FILTER=$(echo "$REQUIRED_REVIEWERS_POLICY_JSON" | jq -r '.path_filter')
        log verbose "PATH_FILTER: $PATH_FILTER"
        log "Reading ID of the $REPO_NAME repository"
        log verbose "Command: az repos show --repository \"$REPO_NAME\" --query id --output tsv --org \"https://dev.azure.com/$ORG_NAME\" --project \"$PROJECT_NAME\""
        REPO_ID=$(az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME")
        log verbose "REPO_ID: $REPO_ID"
        if [ $? -eq 0 ]; then
            log success "The ID of the $REPO_NAME repository is $REPO_ID"
        else
            log error  "Error during the reading of the property ID of the $REPO_NAME"
            return 1
        fi
        REFNAME="refs/heads/$( if [ $BRANCH_MATCH_TYPE == "exact" ]; then echo "$BRANCH_NAME"; else echo "$BRANCH_NAME/*"; fi )"
        log verbose "REFNAME: $REFNAME"
        log verbose 'Request: {"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
        log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
        RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
                "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
        log verbose "Response body: $RESPONSE_BODY"
        if [ $HTTP_STATUS != 200 ]; then
            log error "Failed to retrieve the list of existing approver count policies. $RESPONSE"
            return 1;
        else
            log success "The list of existing approver count policies was successfully retrieved"
        fi
        if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fd2167ab-b0be-447a-8ec8-39368250530e".currentScopePolicies | length > 0') == true ]; then
            log "The approver count policy already exists. Skipping..."
            # REQUIRED_REVIEWERS_IDS=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fd2167ab-b0be-447a-8ec8-39368250530e".currentScopePolicies[0].settings.requiredReviewerIds')
            # MINIMUM_APPROVER_COUNT=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fd2167ab-b0be-447a-8ec8-39368250530e".currentScopePolicies[0].settings.minimumApproverCount')
            # MESSAGE=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fd2167ab-b0be-447a-8ec8-39368250530e".currentScopePolicies[0].settings.message')
            # REF_NAME=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fd2167ab-b0be-447a-8ec8-39368250530e".currentScopePolicies[0].settings.scope.refName')
            # MATCH_KIND=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fd2167ab-b0be-447a-8ec8-39368250530e".currentScopePolicies[0].settings.scope.matchKind')
            # REPOSITORY_ID=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fd2167ab-b0be-447a-8ec8-39368250530e".currentScopePolicies[0].settings.scope.repositoryId')
            # IS_ENABLED=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fd2167ab-b0be-447a-8ec8-39368250530e".currentScopePolicies[0].isEnabled')
            # IS_BLOCKING=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."fd2167ab-b0be-447a-8ec8-39368250530e".currentScopePolicies[0].isBlocking')
            continue
        fi
        log "Creating required reviewers policy for the $BRANCH_NAME in $REPO_NAME repository"
        log verbose "Command: az repos policy required-reviewer create --branch-match-type $BRANCH_MATCH_TYPE --branch $BRANCH_NAME --blocking true --message "$MESSAGE" --path-filter "$PATH_FILTER" --enabled true --required-reviewer-ids "$REQUIRED_REVIEWER_EMAILS" --repository-id $REPO_ID --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME""
        az repos policy required-reviewer create \
            --branch-match-type $BRANCH_MATCH_TYPE \
            --branch $BRANCH_NAME \
            --blocking true \
            --message "$MESSAGE" \
            --path-filter "$PATH_FILTER" \
            --enabled true \
            --required-reviewer-ids "$REQUIRED_REVIEWER_EMAILS" \
            --repository-id $REPO_ID \
            --project "$PROJECT_NAME" \
            --organization "https://dev.azure.com/$ORG_NAME"
        if [ $? -eq 0 ]; then
            log success "Required reviewers policy was added to $BRANCH_NAME in $REPO_NAME repository"
        else
            log error "Required reviewers policy was not added to $BRANCH_NAME in $REPO_NAME repository"
            return 1
        fi
    done

    log "Creating build policies"
    for BUILD_POLICY in $(echo "$DEFAULT_JSON" | jq -r '.repository.policies.build[] | @base64'); do
        BUILD_POLICY_JSON=$(echo "$BUILD_POLICY" | base64 --decode | jq -r '.')
        log verbose "BUILD_POLICY_JSON: $BUILD_POLICY_JSON"
        REPO_NAME=$(echo "$BUILD_POLICY_JSON" | jq -r '.repository_name')
        log verbose "REPO_NAME: $REPO_NAME"
        BRANCH_NAME=$(echo "$BUILD_POLICY_JSON" | jq -r '.branch_name')
        log verbose "BRANCH_NAME: $BRANCH_NAME"
        BRANCH_MATCH_TYPE=$(echo "$BUILD_POLICY_JSON" | jq -r '.branch_match_type')
        log verbose "BRANCH_MATCH_TYPE: $BRANCH_MATCH_TYPE"
        VALID_DURATION=$(echo "$BUILD_POLICY_JSON" | jq -r '.valid_duration') 
        log verbose "VALID_DURATION: $VALID_DURATION"
        QUEUE_ON_SOURCE_UPDATE_ONLY=$(echo "$BUILD_POLICY_JSON" | jq -r '.queue_on_source_update_only')
        log verbose "QUEUE_ON_SOURCE_UPDATE_ONLY: $QUEUE_ON_SOURCE_UPDATE_ONLY"
        MANUAL_QUEUE_ONLY=$(echo "$BUILD_POLICY_JSON" | jq -r '.manual_queue_only')
        log verbose "MANUAL_QUEUE_ONLY: $MANUAL_QUEUE_ONLY"
        DISPLAY_NAME=$(echo "$BUILD_POLICY_JSON" | jq -r '.display_name')
        log verbose "DISPLAY_NAME: $DISPLAY_NAME"
        BUILD_DEFINITION_NAME=$(echo "$BUILD_POLICY_JSON" | jq -r '.build_definition_name')
        log verbose "BUILD_DEFINITION_NAME: $BUILD_DEFINITION_NAME"
        log "Reading ID of the $REPO_NAME repository"
        log verbose "Command: az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME""
        REPO_ID=$(az repos show --repository "$REPO_NAME" --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME")
        log verbose "REPO_ID: $REPO_ID"
        if [ $? -eq 0 ]; then
            log success "The ID of the $REPO_NAME repository is $REPO_ID"
        else
            log error  "Error during the reading of the property ID of the $REPO_NAME"
            return 1
        fi
        log "Reading ID of the $BUILD_DEFINITION_NAME build definition"
        log verbose "Command: az pipelines build definition show --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME" --name $BUILD_DEFINITION_NAME"
        BUILD_DEFINITION_ID=$(az pipelines build definition show --query id --output tsv --org "https://dev.azure.com/$ORG_NAME" --project "$PROJECT_NAME" --name $BUILD_DEFINITION_NAME)
        log verbose "BUILD_DEFINITION_ID: $BUILD_DEFINITION_ID"
        if [ $? -eq 0 ]; then
            log success "The ID of the $BUILD_DEFINITION_NAME build definition is $BUILD_DEFINITION_ID"
        else
            log error  "Error during the reading of the property ID of the $BUILD_DEFINITION_NAME"
            return 1
        fi
        # "Build" = "0609b952-1397-4640-95ec-e00a01b2c241"
        REFNAME="refs/heads/$( if [ $BRANCH_MATCH_TYPE == "exact" ]; then echo "$BRANCH_NAME"; else echo "$BRANCH_NAME/*"; fi )"
        log verbose "REFNAME: $REFNAME"
        log verbose '{"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}'
        log verbose "Uri: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
        RESPONSE=$(curl --silent \
                --write-out "\n%{http_code}" \
                --header "Authorization: Basic $(echo -n :$PAT | base64)" \
                --header "Content-Type: application/json" \
                --data-raw '{"contributionIds":["ms.vss-code-web.branch-policies-data-provider"],"dataProviderContext":{"properties":{"projectId":"'$PROJECT_ID'","repositoryId":"'$REPO_ID'","refName":"'$REFNAME'","sourcePage":{"url":"https://dev.azure.com/'$ORG_NAME'/'$PROJECT_NAME'/_settings/repositories?_a=policiesMid&repo='$REPO_ID'&refs='$REFNAME'","routeId":"ms.vss-admin-web.project-admin-hub-route","routeValues":{"project":"'$PROJECT_NAME'","adminPivot":"repositories","controller":"ContributedPage","action":"Execute","serviceHost":"'$ORG_ID' ('$ORG_NAME')"}}}}}' \
                "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
        HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
        log verbose "Response code: $HTTP_STATUS"
        RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
        log verbose "Response body: $RESPONSE_BODY"
        if [ $HTTP_STATUS != 200 ]; then
            log error "Failed to retrieve the list of existing approver count policies. $RESPONSE"
            return 1;
        else
            log success "The list of existing approver count policies was successfully retrieved"
        fi
        if [ $(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies | length > 0') == true ]; then
            log "The approver count policy already exists. Skipping..."
            # BUILD_DEFINITION_ID=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].settings.buildDefinitionId')
            # QUEUE_ON_SOURCE_UPDATE_ONLY=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].settings.queueOnSourceUpdateOnly')
            # MANUAL_QUEUE_ONLY=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].settings.manualQueueOnly')
            # DISPLAY_NAME=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].settings.displayName')
            # VALID_DURATION=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].settings.validDuration')
            # REF_NAME=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].settings.scope.refName')
            # MATCH_KIND=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].settings.scope.matchKind')
            # REPOSITORY_ID=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].settings.scope.repositoryId')
            # IS_ENABLED=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].isEnabled')
            # IS_BLOCKING=$(echo $RESPONSE_BODY | jq '.dataProviders."ms.vss-code-web.branch-policies-data-provider".policyGroups."0609b952-1397-4640-95ec-e00a01b2c241".currentScopePolicies[0].isBlocking')
            continue
        fi
        log "Creating required reviewers policy for the $BRANCH_NAME in $REPO_NAME repository"
        log verbose "az repos policy build create --branch-match-type $BRANCH_MATCH_TYPE --branch $BRANCH_NAME --blocking true --build-definition-id "$BUILD_DEFINITION_ID" --display-name "$DISPLAY_NAME" --manual-queue-only $MANUAL_QUEUE_ONLY --queue-on-source-update-only $QUEUE_ON_SOURCE_UPDATE_ONLY --valid-duration $VALID_DURATION --enabled true --repository-id $REPO_ID --project "$PROJECT_NAME" --organization "https://dev.azure.com/$ORG_NAME""
        az repos policy build create \
            --branch-match-type $BRANCH_MATCH_TYPE \
            --branch $BRANCH_NAME \
            --blocking true \
            --build-definition-id "$BUILD_DEFINITION_ID" \
            --display-name "$DISPLAY_NAME" \
            --manual-queue-only $MANUAL_QUEUE_ONLY \
            --queue-on-source-update-only $QUEUE_ON_SOURCE_UPDATE_ONLY \
            --valid-duration $VALID_DURATION \
            --enabled true \
            --repository-id $REPO_ID \
            --project "$PROJECT_NAME" \
            --organization "https://dev.azure.com/$ORG_NAME"
        if [ $? -eq 0 ]; then
            log success "Required reviewers policy was added to $BRANCH_NAME in $REPO_NAME repository"
        else
            log error "Required reviewers policy was not added to $BRANCH_NAME in $REPO_NAME repository"
            return 1
        fi
    done
}

# ==================== UTILITIES =======================
function get_organization_id {
    local ORG_NAME=$1
    local PAT=$2
    log "Read organization ID by $ORG_NAME"
    log verbose 'Request: {"contributionIds": ["ms.vss-features.my-organizations-data-provider"],"dataProviderContext":{"properties":{}}}'
    log verbose "Url: https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1"
    RESPONSE=$(curl --silent \
            --write-out "\n%{http_code}" \
            --header "Authorization: Basic $(echo -n :$PAT | base64)" \
            --header "Content-Type: application/json" \
            --data-raw '{"contributionIds": ["ms.vss-features.my-organizations-data-provider"],"dataProviderContext":{"properties":{}}}' \
            "https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1")
    HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")
    log verbose "Response HTTP status: $HTTP_STATUS"
    RESPONSE_BODY=$(sed '$ d' <<< "$RESPONSE") 
    log verbose "Response body: $RESPONSE_BODY"
    if [ $HTTP_STATUS != 200 ]; then
        log error "Error during the reading of the organization ID"
        exit 1;
    else
        log success "Organization ID was read successfully"
    fi
    ORG_ID=$(echo "$RESPONSE_BODY" | jq '.dataProviders."ms.vss-features.my-organizations-data-provider".organizations[] | select(.name == "'"$ORG_NAME"'") | .id' | tr -d '"')
    log debug "Organization ID: $ORG_ID"
    echo $ORG_ID
}
function get_project_id {
    local ORG_NAME=$1
    local PROJECT_NAME=$2
    log "Get project ID by $PROJECT_NAME"
    log verbose "Command: az devops project show --project $PROJECT_NAME"
    PROJECT_ID=$(az devops project show --project $PROJECT_NAME | jq -r '.id')
    if [ $? -eq 0 ]; then
        log success "Project ID was read successfully"
    else
        log error "Error during the reading of the project ID"
        exit 1
    fi
    log debug "Project ID: $PROJECT_ID"
    echo $PROJECT_ID
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
DEFAULT_JSON=$(cat config.json)
ORG_NAME=$(echo "$DEFAULT_JSON" | jq -r '.organization.name')

# ==================== GENERAL =========================
authenticate_to_azure_devops $ORG_NAME
# ==================== ORGANIZATION ====================
ORG_ID=$(get_organization_id $ORG_NAME $PAT)
out "[] Add users to the $ORG_NAME organization"
add_users_to_organization $ORG_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Add users to the $ORG_NAME organization\n"
else
    out error "\r[] Add users to the $ORG_NAME organization\n"
    exit 1
fi
out "[] Configure organization policies"
configure_organization_policies $ORG_ID $ORG_NAME "$DEFAULT_JSON" $PAT
if [ $? -eq 0 ]; then
    out success "\r[x] Configure organization policies\n"
else
    out error "\r[] Configure organization policies\n"
    exit 1
fi
out "[] Configure organization settings"
configure_organization_settings $ORG_ID $ORG_NAME "$DEFAULT_JSON" $PAT
if [ $? -eq 0 ]; then
    out success "\r[x] Configure organization settings\n"
else
    out error "\r[] Configure organization settings\n"
    exit 1
fi
out "[] Connect to Azure Active Directory"
connecting_organization_to_azure_active_directory $ORG_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Connect to Azure Active Directory\n"
else
    out error "\r[] Connect to Azure Active Directory\n"
    exit 1
fi
out "[] Configure organization extensions"
install_extensions_in_organization $ORG_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Configure organization extensions\n"
else
    out error "\r[] Configure organization extensions\n"
    exit 1
fi
out "[] Configure organization repositories"
configure_organization_repositories $ORG_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Configure organization repositories\n"
else
    out error "\r[] Configure organization repositories\n"
    exit 1
fi
# ==================== PROJECT =========================
PROJECT_NAME=$(echo "$DEFAULT_JSON" | jq -r '.organization.project.name')
out "[] Create project $PROJECT_NAME"
create_project $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Create project $PROJECT_NAME\n"
else
    out error "\r[] Create project $PROJECT_NAME\n"
    exit 1
fi
PROJECT_ID=$(get_project_id $ORG_NAME $PROJECT_NAME)
out "[] Create security groups"
create_security_groups $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Create security groups\n"
else
    out error "\r[] Create security groups\n"
    exit 1
fi
out "[] Create project repositories"  
create_repositories $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Create project repositories\n"
else
    out error "\r[] Create project repositories\n"
    exit 1
fi
out "[] Create repositories branch protection policies"
create_repositories_branch_protection_policies $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Create repositories branch protection policies\n"
else
    out error "\r[] Create repositories branch protection policies\n"
    exit 1
fi
out "[] Create pipeline variable groups"
create_pipeline_variable_groups $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Create pipeline variable groups\n"
else
    out error "\r[] Create pipeline variable groups\n"
    exit 1
fi
out "[] Delete default repository"
delete_repository $ORG_NAME $PROJECT_NAME $PROJECT_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Delete default repository\n"
else
    out error "\r[] Delete default repository\n"
    exit 1
fi
create_work_items $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON" # Add check if the workitem exists
out "[] Create pipelines environments"
create_pipeline_environments $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON" $PAT
if [ $? -eq 0 ]; then
    out success "\r[x] Create pipelines environments\n"
else
    out error "\r[] Create pipelines environments\n"
    exit 1
fi
out "[] Create pipelines"
create_pipeline_pipelines $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON" $PAT
if [ $? -eq 0 ]; then
    out success "\r[x] Create pipelines\n"
else
    out error "\r[] Create pipelines\n"
    exit 1
fi
out "[] Assign security groups to environments"
assing_security_groups_to_environments $ORG_NAME $PROJECT_ID $PROJECT_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Assign security groups to environments\n"
else
    out error "\r[] Assign security groups to environments\n"
    exit 1
fi
out "[] Create service endpoints. To check logs"
create_service_endpoints $ORG_ID $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Create service endpoints\n"
else
    out error "\r[] Create service endpoints\n"
    exit 1
fi
out "[] Create agent pools"
create_agent_pools $ORG_ID $ORG_NAME $PROJECT_NAME "$DEFAULT_JSON"
if [ $? -eq 0 ]; then
    out success "\r[x] Create agent pools\n"
else
    out error "\r[] Create agent pools\n"
    exit 1
fi
