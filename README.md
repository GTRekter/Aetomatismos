# Aetomatismos
This repository contains a bash script that will create and configure Azure DevOps according to a configuration JSON. It use both Azure APIs and Azure DevOps CLI module.

|Category|Feature|Command|Documentation|Supported|Configured|
|---|---|---|---|---|---|
|Organization|Install extension in the organization|az devops extension install|[https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-install](https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-install)|✔|✔|
|Organization|Unnstall extension from the organization|az devops extension uninstall|[https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-uninstall](https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-uninstall)|✔|❌|
|Organization|Add user to organization|az devops user add|[https://learn.microsoft.com/en-us/cli/azure/devops/user?view=azure-cli-latest#az-devops-user-add](https://learn.microsoft.com/en-us/cli/azure/devops/user?view=azure-cli-latest#az-devops-user-add)|✔|✔|
|Organization|Remove user from organization|az devops user remove|[https://learn.microsoft.com/en-us/cli/azure/devops/user?view=azure-cli-latest#az-devops-user-remove](https://learn.microsoft.com/en-us/cli/azure/devops/user?view=azure-cli-latest#az-devops-user-remove)|✔|❌|
|Organization|Create project in organization|az devops project create|[https://learn.microsoft.com/en-us/cli/azure/devops/project?view=azure-cli-latest#az-devops-project-create](https://learn.microsoft.com/en-us/cli/azure/devops/project?view=azure-cli-latest#az-devops-project-create)|✔|✔|
|Organization|Delete project from organization|az devops project delete|[https://learn.microsoft.com/en-us/cli/azure/devops/project?view=azure-cli-latest#az-devops-project-delete](https://learn.microsoft.com/en-us/cli/azure/devops/project?view=azure-cli-latest#az-devops-project-delete)|✔|❌|
|Organization|Connect your organization to Azure Active Directory|https://dev.azure.com/<org-name>/_settings/organizationAad||❌|✔|
|Organization|Application connection policies|||❌|❌|
|Organization|Security policies|||❌|❌|
|Organization|User policies|||❌|❌|
|Organization|Project collection permissions|||❌|❌|
|Organization|Invite guests users|https://dev.azure.com/<org-name>/_apis/OrganizationPolicy/Policies/Policy.DisallowAadGuestUserAccess?api-version=5.0-preview.1||❌|✔|
|Project|Service connection creation|az devops service-endpoint azurerm create|[https://learn.microsoft.com/en-us/cli/azure/devops/service-endpoint/azurerm?view=azure-cli-latest#az-devops-service-endpoint-azurerm-create](https://learn.microsoft.com/en-us/cli/azure/devops/service-endpoint/azurerm?view=azure-cli-latest#az-devops-service-endpoint-azurerm-create)|✔|❌|
|Project|Service connection deletion|az devops service-endpoint azurerm delete|[https://learn.microsoft.com/en-us/cli/azure/devops/service-endpoint?view=azure-cli-latest#az-devops-service-endpoint-delete](https://learn.microsoft.com/en-us/cli/azure/devops/service-endpoint?view=azure-cli-latest#az-devops-service-endpoint-delete)|✔|❌|
|Project|Create security group creation|az devops security group create|[https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-create](https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-create)|✔|✔|
|Project|Create security group deletion|az devops security group delete|[https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-delete](https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-delete)|✔|❌|
|Project|Create team in project|az devops team create|[https://learn.microsoft.com/en-us/cli/azure/devops/team?view=azure-cli-latest#az-devops-team-create](https://learn.microsoft.com/en-us/cli/azure/devops/team?view=azure-cli-latest#az-devops-team-create)|✔|❌|
|Project|Delete team from project|az devops team delete|[https://learn.microsoft.com/en-us/cli/azure/devops/team?view=azure-cli-latest#az-devops-team-delete](https://learn.microsoft.com/en-us/cli/azure/devops/team?view=azure-cli-latest#az-devops-team-delete)|✔|❌|
|Project|Create a wiki|az devops wiki create|[https://learn.microsoft.com/en-us/cli/azure/devops/wiki?view=azure-cli-latest#az-devops-wiki-create](https://learn.microsoft.com/en-us/cli/azure/devops/wiki?view=azure-cli-latest#az-devops-wiki-create)|✔|❌|
|Project|Delete a wiki|az devops wiki delete|[https://learn.microsoft.com/en-us/cli/azure/devops/wiki?view=azure-cli-latest#az-devops-wiki-delete](https://learn.microsoft.com/en-us/cli/azure/devops/wiki?view=azure-cli-latest#az-devops-wiki-delete)|✔|❌|
|Project|Create page in the wiki|az devops wiki page create|[https://learn.microsoft.com/en-us/cli/azure/devops/wiki/page?view=azure-cli-latest#az-devops-wiki-page-create](https://learn.microsoft.com/en-us/cli/azure/devops/wiki/page?view=azure-cli-latest#az-devops-wiki-page-create)|✔|❌|
|Project|Delete page from the wiki|az devops wiki page delete|[https://learn.microsoft.com/en-us/cli/azure/devops/wiki/page?view=azure-cli-latest#az-devops-wiki-page-delete](https://learn.microsoft.com/en-us/cli/azure/devops/wiki/page?view=azure-cli-latest#az-devops-wiki-page-delete)|✔|❌|
|Project|Dashboard creation|||❌|❌|
|Project|Dashboard settings|||❌|❌|
|Boards|Create area|az boards area project create|[https://learn.microsoft.com/en-us/cli/azure/boards/area/project?view=azure-cli-latest#az-boards-area-project-create](https://learn.microsoft.com/en-us/cli/azure/boards/area/project?view=azure-cli-latest#az-boards-area-project-create)|✔|❌|
|Boards|Delete area|az boards area project delete|[https://learn.microsoft.com/en-us/cli/azure/boards/area/project?view=azure-cli-latest#az-boards-area-project-delete](https://learn.microsoft.com/en-us/cli/azure/boards/area/project?view=azure-cli-latest#az-boards-area-project-delete)|✔|❌|
|Boards|Add area team|az boards area team add|[https://learn.microsoft.com/en-us/cli/azure/boards/area/team?view=azure-cli-latest#az-boards-area-team-add](https://learn.microsoft.com/en-us/cli/azure/boards/area/team?view=azure-cli-latest#az-boards-area-team-add)|✔|❌|
|Boards|Remove area team|az boards area team remove|[https://learn.microsoft.com/en-us/cli/azure/boards/area/team?view=azure-cli-latest#az-boards-area-team-remove](https://learn.microsoft.com/en-us/cli/azure/boards/area/team?view=azure-cli-latest#az-boards-area-team-remove)|✔|❌|
|Boards|Create iteration|az boards iteration project create|[https://learn.microsoft.com/en-us/cli/azure/boards/iteration/project?view=azure-cli-latest#az-boards-iteration-project-create](https://learn.microsoft.com/en-us/cli/azure/boards/iteration/project?view=azure-cli-latest#az-boards-iteration-project-create)|✔|❌|
|Boards|Delete iteration|az boards iteration project delete|[https://learn.microsoft.com/en-us/cli/azure/boards/iteration/project?view=azure-cli-latest#az-boards-iteration-project-delete](https://learn.microsoft.com/en-us/cli/azure/boards/iteration/project?view=azure-cli-latest#az-boards-iteration-project-delete)|✔|❌|
|Boards|Branch lock|az boards iteration team add|[https://learn.microsoft.com/en-us/cli/azure/boards/iteration/team?view=azure-cli-latest#az-boards-iteration-team-add](https://learn.microsoft.com/en-us/cli/azure/boards/iteration/team?view=azure-cli-latest#az-boards-iteration-team-add)|✔|❌|
|Boards|Branch lock|az boards iteration team remove|[https://learn.microsoft.com/en-us/cli/azure/boards/iteration/team?view=azure-cli-latest#az-boards-iteration-team-remove](https://learn.microsoft.com/en-us/cli/azure/boards/iteration/team?view=azure-cli-latest#az-boards-iteration-team-remove)|✔|❌|
|Boards|Add work item|az boards work-item create|[https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest#az-boards-work-item-create](https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest#az-boards-work-item-create)|✔|✔|
|Boards|Delete work item|az boards work-item delete|[https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest#az-boards-work-item-delete](https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest#az-boards-work-item-delete)|✔|❌|
|Boards|Add relations between work items|az boards work-item relation add|[https://learn.microsoft.com/en-us/cli/azure/boards/work-item/relation?view=azure-cli-latest#az-boards-work-item-relation-add](https://learn.microsoft.com/en-us/cli/azure/boards/work-item/relation?view=azure-cli-latest#az-boards-work-item-relation-add)|✔|✔|
|Boards|Remove relations between work items|az boards work-item relation remove|[https://learn.microsoft.com/en-us/cli/azure/boards/work-item/relation?view=azure-cli-latest#az-boards-work-item-relation-remove](https://learn.microsoft.com/en-us/cli/azure/boards/work-item/relation?view=azure-cli-latest#az-boards-work-item-relation-remove)|✔|❌|
|Boards|Create custom queries|||||
|Boards|Create custom columns|||||
|Boards|Update board settings|||||
|Repos|Repository creation|az repos create|[https://learn.microsoft.com/en-us/cli/azure/repos?view=azure-cli-latest](https://learn.microsoft.com/en-us/cli/azure/repos?view=azure-cli-latest#az-repos-create)|✔|✔|
|Repos|Repository deletion|az repos delete|[https://learn.microsoft.com/en-us/cli/azure/repos?view=azure-cli-latest](https://learn.microsoft.com/en-us/cli/azure/repos?view=azure-cli-latest#az-repos-delete)|✔|✔|
|Repos|Repository import|az repos iport|[https://learn.microsoft.com/en-us/cli/azure/repos/import?view=azure-cli-latest](https://learn.microsoft.com/en-us/cli/azure/repos/import?view=azure-cli-latest)|✔|❌|
|Repos|Repository policies - Approvers count|az repos policy approver-count create|[https://learn.microsoft.com/en-us/cli/azure/repos/policy/approver-count?view=azure-cli-latest](https://learn.microsoft.com/en-us/cli/azure/repos/policy/approver-count?view=azure-cli-latest)|✔|⚠|
|Repos|Repository policies - Build validation|az repos policy build create|[https://learn.microsoft.com/en-us/cli/azure/repos/policy/build?view=azure-cli-latest#az-repos-policy-build-create](https://learn.microsoft.com/en-us/cli/azure/repos/policy/build?view=azure-cli-latest#az-repos-policy-build-create)|✔|⚠|
|Repos|Repository policies - Case enforcement|az repos policy case-enforcement create|[https://learn.microsoft.com/en-us/cli/azure/repos/policy/case-enforcement?view=azure-cli-latest#az-repos-policy-case-enforcement-create](https://learn.microsoft.com/en-us/cli/azure/repos/policy/case-enforcement?view=azure-cli-latest#az-repos-policy-case-enforcement-create)|✔|⚠|
|Repos|Repository policies - Comment resolution|az repos policy comment-required create|[https://learn.microsoft.com/en-us/cli/azure/repos/policy/comment-required?view=azure-cli-latest#az-repos-policy-comment-required-create](https://learn.microsoft.com/en-us/cli/azure/repos/policy/comment-required?view=azure-cli-latest#az-repos-policy-comment-required-create)|✔|⚠|
|Repos|Repository policies - Merge strategy|az repos policy merge-strategy create|[https://learn.microsoft.com/en-us/cli/azure/repos/policy/merge-strategy?view=azure-cli-latest#az-repos-policy-merge-strategy-create](https://learn.microsoft.com/en-us/cli/azure/repos/policy/merge-strategy?view=azure-cli-latest#az-repos-policy-merge-strategy-create)|✔|⚠|
|Repos|Repository policies - Required reviewers|az repos policy required-reviewer create|[https://learn.microsoft.com/en-us/cli/azure/repos/policy/required-reviewer?view=azure-cli-latest#az-repos-policy-required-reviewer-create](https://learn.microsoft.com/en-us/cli/azure/repos/policy/required-reviewer?view=azure-cli-latest#az-repos-policy-required-reviewer-create)|✔|⚠|
|Repos|Repository policies - Work-Item linking|az repos policy work-item-linking create|[https://learn.microsoft.com/en-us/cli/azure/repos/policy/required-reviewer?view=azure-cli-latest#az-repos-policy-required-reviewer-create](https://learn.microsoft.com/en-us/cli/azure/repos/policy/work-item-linking?view=azure-cli-latest#az-repos-policy-work-item-linking-create)|✔|⚠|
|Repos|Branch creation|git checkout||✔|✔|
|Repos|Branch security|||||
|Repos|Branch lock|||||
|Repos|Tags creation|git tag||✔|⚠|
|Repos|Cross-repository settings|||❌|❌|
|Repos|Cross-repository policies|||❌|❌|
|Pipelines|Build pipeline creation|az pipelines create|[https://learn.microsoft.com/en-us/cli/azure/pipelines?view=azure-cli-latest#az-pipelines-create](https://learn.microsoft.com/en-us/cli/azure/pipelines?view=azure-cli-latest#az-pipelines-create)|✔|⚠|
|Pipelines|Build pipeline deletion|az pipelines delete|[https://learn.microsoft.com/en-us/cli/azure/pipelines?view=azure-cli-latest#az-pipelines-delete](https://learn.microsoft.com/en-us/cli/azure/pipelines?view=azure-cli-latest#az-pipelines-delete)|✔|⚠|
|Pipelines|Release pipeline creation|||❌|❌|
|Pipelines|Build agent pool creation|||❌|❌|
|Pipelines|Build agent creation|||❌|❌|
|Pipelines|Variable creation (Secrets)|az pipelines variable create|[https://learn.microsoft.com/en-us/cli/azure/pipelines/variable-group?view=azure-cli-latest#az-pipelines-variable-group-create](https://learn.microsoft.com/en-us/cli/azure/pipelines/variable-group?view=azure-cli-latest#az-pipelines-variable-group-create)|✔|❌|
|Pipelines|Variable deletion (Secrets)|az pipelines variable delete|[https://learn.microsoft.com/en-us/cli/azure/pipelines/variable?view=azure-cli-latest#az-pipelines-variable-delete](https://learn.microsoft.com/en-us/cli/azure/pipelines/variable?view=azure-cli-latest#az-pipelines-variable-delete)|✔|❌|
|Pipelines|Variable group creation|az pipelines variable-group create|[https://learn.microsoft.com/en-us/cli/azure/pipelines/variable-group?view=azure-cli-latest#az-pipelines-variable-group-create](https://learn.microsoft.com/en-us/cli/azure/pipelines/variable-group?view=azure-cli-latest#az-pipelines-variable-group-create)|✔|✔|
|Pipelines|Variable group deletion|az pipelines variable-group delete|[https://learn.microsoft.com/en-us/cli/azure/pipelines/variable-group?view=azure-cli-latest#az-pipelines-variable-group-delete](https://learn.microsoft.com/en-us/cli/azure/pipelines/variable-group?view=azure-cli-latest#az-pipelines-variable-group-delete)|✔|❌|
|Pipelines|Environment creation|_apis/distributedtask/environments?api-version=5.0-preview.1|[https://joefecht.com/posts/creating-an-azdo-environment-via-api/](https://joefecht.com/posts/creating-an-azdo-environment-via-api/)|❌|✔|
|Pipelines|Environment list|https://dev.azure.com/$ORG_NAME/$PROJECT_NAME/_apis/distributedtask/environments?api-version=5.0-preview.1||❌|✔|
|Pipelines|Environment role assignment|https://dev.azure.com/$ORG_NAME/_apis/securityroles/scopes/distributedtask.environmentreferencerole/roleassignments/resources/$PROJECT_ID"_"$ENVIRONMENT_ID?api-version=5.0-preview.1||❌|⚠|
|Pipelines|Task group creation|||||
|Pipelines|Deployment group creation|||||
|Pipelines|Retention policy update|||||
|Pipelines|Organization settings|||||


❌ = Not yet implemented
✔  = Already implemented
⚠  = Work in progress
