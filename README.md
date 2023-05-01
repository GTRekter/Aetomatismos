# Aetomatismos
This repository contains a bash script that will create and configure Azure DevOps according to a configuration JSON. It use both Azure APIs and Azure DevOps CLI module.

| Category | Feature | Command / URL | Documentation | Supported by Az CLI | Configured |
|---|---|---|---|---|---|
| Organization | Add project to organization | az devops project create | https://learn.microsoft.com/en-us/cli/azure/devops/project?view=azure-cli-latest#az-devops-project-create | ✔ | ✔ |
| Organization | Get projects from organization | az devops project list | https://learn.microsoft.com/en-us/cli/azure/devops/project?view=azure-cli-latest#az-devops-project-list | ✔ | ✔ |
| Organization | Get project details | az devops project show | https://learn.microsoft.com/en-us/cli/azure/devops/project?view=azure-cli-latest#az-devops-project-show | ✔ | ✔ |
| Organization | Edit project details |  |  | ✔ | ❌ |
| Organization | Remove project from organization | az devops project delete | https://learn.microsoft.com/en-us/cli/azure/devops/project?view=azure-cli-latest#az-devops-project-delete | ✔ | ❌ |
| Organization | Add user to organization | az devops user add | https://learn.microsoft.com/en-us/cli/azure/devops/user?view=azure-cli-latest#az-devops-user-add | ✔ | ✔ |
| Organization | Get users from organization |  az devops user list | https://learn.microsoft.com/en-us/cli/azure/devops/user?view=azure-cli-latest#az-devops-user-list | ✔ | ✔ |
| Organization | Get user details | az devops user show  | https://learn.microsoft.com/en-us/cli/azure/devops/user?view=azure-cli-latest#az-devops-user-show | ✔ | ✔ |
| Organization | Edit user details | az devops user update  | https://learn.microsoft.com/en-us/cli/azure/devops/user?view=azure-cli-latest#az-devops-user-update | ✔ | ❌ |
| Organization | Remove user from organization | az devops user remove  | https://learn.microsoft.com/en-us/cli/azure/devops/user?view=azure-cli-latest#az-devops-user-remove | ✔ | ❌ |
| Organization | Install extension in the organization | az devops extension install | https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-install | ✔ | ✔ |
| Organization | Get extensions from organization | az devops extension list | https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-list | ✔ | ✔ |
| Organization | Get extension details | az devops extension show | https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-show | ✔ | ✔ |
| Organization | Disable extension details | az devops extension disable | https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-disable | ✔ | ❌ |
| Organization | Enable extension details | az devops extension enable | https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-enable | ✔ | ❌ |
| Organization | Remove extension from the organization | az devops extension uninstall | https://learn.microsoft.com/en-us/cli/azure/devops/extension?view=azure-cli-latest#az-devops-extension-uninstall | ✔ | ❌ |
| Organization | Connect organization to Azure Active Directory | https://dev.azure.com/$ORG_NAME/_settings/organizationAad |  | ❌ | ✔ |
| Organization | Disconnect organization to Azure Active Directory | TBD |  |  | ❌ |
| Organization | Configure organization security policies (Third-party application access via OAuth) | https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.DisallowOAuthAuthentication?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization security policies (SSH authentication) | https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.DisallowSecureShell?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization security policies (Log Audit Events) | https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.LogAuditEvents?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization security policies (Allow public projects) | https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.AllowAnonymousAccess?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization security policies (Additional protections when using public package registries) | https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.ArtifactsExternalPackageProtectionToken?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization security policies (Enable Azure Active Directory Conditional Access Policy Validation) | https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.EnforceAADConditionalAccess?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization security policies (External guest access) | https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.DisallowAadGuestUserAccess?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization security policies (Allow team and project administrators to invite new users) | https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.AllowTeamAdminsInvitationsAccessToken?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization security policies (Request access - URL) | https://vssps.dev.azure.com/$ORG_NAME/_apis/Organization/Collections/$ORG_ID/Properties?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization security policies (Request access) | https://dev.azure.com/$ORG_NAME/_apis/OrganizationPolicy/Policies/Policy.AllowRequestAccessToken?api-version=5.0-preview.1" |  | ❌ | ✔ |
| Organization | Permissions | TBD |  |  |  |
| Organization | Processes | TBD |  |  |  |
| Organization | Agent pools | TBD |  |  |  |
| Organization | Configure organization settings (Disable anonymous access to badges) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization settings (Limit variables that can be set at queue time) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization settings (Limit job authorization scope to current project for non-release pipelines) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization settings (Limit job authorization scope to current project for release pipelines) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization settings (Protect access to repositories in YAML pipelines) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization settings (Disable stage chooser) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization settings (Disable creation of classic build and classic release pipelines) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization settings (Disable built-in tasks) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization settings (Disable Marketplace tasks) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  | ❌ | ✔ |
| Organization | Configure organization settings (Disable Node 6 tasks) | https://dev.azure.com/$ORG_NAME/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1 |  |❌  | ✔ |
| Organization | Deployment pools | TBD |  |  |  |
| Organization | Parallel jobs | TBD |  |  |  |
| Organization | OAuth configurations | TBD |  |  |  |
| Organization | Repositories settings |  |  |  |  |
| Organization | Storage | TBD |  |  |  |

## Project 

| Project | Add administrator to project | TBD |  |  |  |
| Project | Get administrators from project | TBD |  |  |  |
| Project | Get administrator details | TBD |  |  |  |
| Project | Edit administrator details | TBD |  |  |  |
| Project | Remove administrator from project | TBD |  |  |  |
| Project | Enable Boards | TBD |  |  |  |
| Project | Disable Boards | TBD |  |  |  |
| Project | Enable Repos | TBD |  |  |  |
| Project | Disable Repos | TBD |  |  |  |
| Project | Enable Pipelines | TBD |  |  |  |
| Project | Disable Pipelines | TBD |  |  |  |
| Project | Enable Test Plans | TBD |  |  |  |
| Project | Disable Test Plans | TBD |  |  |  |
| Project | Enable Artifact | TBD |  |  |  |
| Project | Disable Artifact | TBD |  |  |  |
| Project | Add Team to project | TBD |  |  |  |
| Project | Get Team from project | TBD |  |  |  |
| Project | Get Team details | TBD |  |  |  |
| Project | Edit Team details | TBD |  |  |  |
| Project | Remove Team from project | TBD |  |  |  |
| Project | Add security group to project | az devops security group create | https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-create | ✔ | ✔ |
| Project | Get security groups from project | az devops security group list | https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-list | ✔ | ✔ |
| Project | Get security group details | az devops security group show | https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-show | ✔ | ✔ |
| Project | Edit security group details | az devops security group update | https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-update | ✔ |  |
| Project | Remove security group from project | az devops security group delete | https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-delete | ✔ |  |
| Project | Add Service Hook to project | TBD |  |  |  |
| Project | Get Service Hook from project | TBD |  |  |  |
| Project | Get Service Hook details | TBD |  |  |  |
| Project | Edit Service Hook details | TBD |  |  |  |
| Project | Remove Service Hook from project | TBD |  |  |  |
| Project | Dashboard settings (Create dashboards) | TBD |  |  |  |
| Project | Dashboard settings (Edit dashboards) | TBD |  |  |  |
| Project | Dashboard settings (Delete dashboards) | TBD |  |  |  |
| Project | Add Iteration to project | TBD |  |  |  |
| Project | Get Iteration from project | TBD |  |  |  |
| Project | Get Iteration details | TBD |  |  |  |
| Project | Edit Iteration details | TBD |  |  |  |
| Project | Remove Iteration from project | TBD |  |  |  |
| Project | Add Area to project | TBD |  |  |  |
| Project | Get Area from project | TBD |  |  |  |
| Project | Get Area details | TBD |  |  |  |
| Project | Edit Area details | TBD |  |  |  |
| Project | Remove Area from project | TBD |  |  |  |
| Project | Edit team configuration (Backlog navigation levels Epics) | TBD |  |  |  |
| Project | Edit team configuration (Backlog navigation levels Features) | TBD |  |  |  |
| Project | Edit team configuration (Backlog navigation levels Stories) | TBD |  |  |  |
| Project | Edit team configuration (Working days) | TBD |  |  |  |
| Project | Edit team configuration (Working with bugs) | TBD |  |  |  |
| Project | Connect to GitHub |  |  |  |  |
| Project | Disconnect from GitHub |  |  |  |  |
| Project | Add Agent pool (Self-hosted) to project | TBD |  |  |  |
| Project | Get Agent pool (Self-hosted) from project | TBD |  |  |  |
| Project | Get Agent pool (Self-hosted) details | TBD |  |  |  |
| Project | Edit Agent pool (Self-hosted) details | TBD |  |  |  |
| Project | Remove Agent pool (Self-hosted) from project | TBD |  |  |  |
| Project | Add Agent pool (VMSS) to project | TBD |  |  |  |
| Project | Get Agent pool (VMSS) from project | TBD |  |  |  |
| Project | Get Agent pool (VMSS) details | TBD |  |  |  |
| Project | Edit Agent pool (VMSS) details | TBD |  |  |  |
| Project | Remove Agent pool (VMSS) from project | TBD |  |  |  |
| Project | Purchase parallel jobs |  |  |  |  |
| Project | Configure Retention policy |  |  |  |  |
| Project | Configure organization settings (Disable anonymous access to badges) |  |  |  |  |
| Project | Configure organization settings (Limit variables that can be set at queue time) |  |  |  |  |
| Project | Configure organization settings (Limit job authorization scope to current project for non-release pipelines) |  |  |  |  |
| Project | Configure organization settings (Limit job authorization scope to current project for release pipelines) |  |  |  |  |
| Project | Configure organization settings (Protect access to repositories in YAML pipelines) |  |  |  |  |
| Project | Configure organization settings (Disable stage chooser) |  |  |  |  |
| Project | Configure organization settings (Disable creation of classic build and classic release pipelines) |  |  |  |  |
| Project | Configure organization settings (Disable built-in tasks) |  |  |  |  |
| Project | Configure organization settings (Disable Marketplace tasks) |  |  |  |  |
| Project | Configure organization settings (Disable Node 6 tasks) |  |  |  |  |
| Project | Configure Test management (Flaky test detection) |  |  |  |  |
| Project | Configure Test management (Select pipelines to enable flaky test detection) |  |  |  |  |
| Project | Configure Test management (Flaky test options) |  |  |  |  |
| Project | Configure Rerention policy settings (Enable/Disable Retain build) |  |  |  |  |
| Project | Add Service connection to project | az devops service-endpoint azurerm create | https://learn.microsoft.com/en-us/cli/azure/devops/service-endpoint/azurerm?view=azure-cli-latest#az-devops-service-endpoint-azurerm-create |  |  |
| Project | Get Service connection from project |  |  |  |  |
| Project | Get Service connection details |  |  |  |  |
| Project | Edit Service connection details |  |  |  |  |
| Project | Remove Service connection from project | az devops service-endpoint azurerm delete | https://learn.microsoft.com/en-us/cli/azure/devops/service-endpoint?view=azure-cli-latest#az-devops-service-endpoint-delete |  |  |
| Project | Add XAML build service to project |  |  |  |  |
| Project | Get XAML build service from project |  |  |  |  |
| Project | Get XAML build service details |  |  |  |  |
| Project | Edit XAML build service details |  |  |  |  |
| Project | Remove XAML build service from project |  |  |  |  |
| Project | Configure Cross-repository settings (Enable Default branch name for new repositories) |  |  |  |  |
| Project | Configure Cross-repository settings (Enable Allow users to manage permissions for their created branches) |  |  |  |  |
| Project | Configure Cross-repository settings (Enable Create PRs as draft by default) |  |  |  |  |
| Project | Configure Cross-repository policies (Enable Commit author email validation) |  |  |  |  |
| Project | Configure Cross-repository policies (Enable File path validation) |  |  |  |  |
| Project | Configure Cross-repository policies (Enable Case enforcement) |  |  |  |  |
| Project | Configure Cross-repository policies (Enable Reserved names) |  |  |  |  |
| Project | Configure Cross-repository policies (Enable Maximum path length) |  |  |  |  |
| Project | Configure Cross-repository policies (Enable Maximum file size) |  |  |  |  |
| Project | Configure Cross-repository policies (Add Require a minimum number of reviewers) |  |  |  |  |
| Project | Configure Cross-repository policies (Get Require a minimum number of reviewers) |  |  |  |  |
| Project | Configure Cross-repository policies (Edit Require a minimum number of reviewers) |  |  |  |  |
| Project | Configure Cross-repository policies (Add Check for linked work items) |  |  |  |  |
| Project | Configure Cross-repository policies (Get Check for linked work items) |  |  |  |  |
| Project | Configure Cross-repository policies (Edit Check for linked work items) |  |  |  |  |
| Project | Configure Cross-repository policies (Add Check for comment resolution) |  |  |  |  |
| Project | Configure Cross-repository policies (Get Check for comment resolution) |  |  |  |  |
| Project | Configure Cross-repository policies (Edit Check for comment resolution) |  |  |  |  |
| Project | Configure Cross-repository policies (Add Limit merge types) |  |  |  |  |
| Project | Configure Cross-repository policies (Get Limit merge types) |  |  |  |  |
| Project | Configure Cross-repository policies (Edit Limit merge types) |  |  |  |  |
| Project | Configure Cross-repository policies (Add Build Validation) |  |  |  |  |
| Project | Configure Cross-repository policies (Get Build Validation) |  |  |  |  |
| Project | Configure Cross-repository policies (Get Build Validations) |  |  |  |  |
| Project | Configure Cross-repository policies (Edit Build Validation) |  |  |  |  |
| Project | Configure Cross-repository policies (Remove Build Validation) |  |  |  |  |
| Project | Configure Cross-repository policies (Add Status Check) |  |  |  |  |
| Project | Configure Cross-repository policies (Get Status Check) |  |  |  |  |
| Project | Configure Cross-repository policies (Get Status Checks) |  |  |  |  |
| Project | Configure Cross-repository policies (Edit Status Check) |  |  |  |  |
| Project | Configure Cross-repository policies (Remove Status Check) |  |  |  |  |
| Project | Configure Cross-repository policies (Add Automatically included reviewers) |  |  |  |  |
| Project | Configure Cross-repository policies (Get Automatically included reviewers) |  |  |  |  |
| Project | Configure Cross-repository policies (Edit Automatically included reviewers) |  |  |  |  |
| Project | Configure Cross-repository policies (Remove Automatically included reviewers) |  |  |  |  |
| Project | Configure Cross-repository security  |  |  |  |  |
| Project | Configure Retention policy |  |  |  |  |
| Project | Add Dashboard to project |  |  |  |  |
| Project | Get Dashboard from project |  |  |  |  |
| Project | Get Dashboard details |  |  |  |  |
| Project | Edit Dashboard details |  |  |  |  |
| Project | Remove Dashboard from project |  |  |  |  |
| Project | Add Wiki to project | az devops wiki create |  |  |  |
| Project | Get Wiki from project |  |  |  |  |
| Project | Get Wiki details |  |  |  |  |
| Project | Edit Wiki details |  |  |  |  |
| Project | Remove Wiki from project | az devops wiki delete |  |  |  |
| Project | Add Wiki page to project | az devops wiki page create |  |  |  |
| Project | Get Wiki page from project |  |  |  |  |
| Project | Get Wiki page details |  |  |  |  |
| Project | Edit Wiki page details |  |  |  |  |
| Project | Remove Wiki page from project | az devops wiki page delete |  |  |  |

## Boards

| Board | Add Work-item to project | az devops wiki page create |  |  |  |
| Board | Get Work-item from project |  |  |  |  |
| Board | Get Work-item details |  |  |  |  |
| Board | Edit Work-item details |  |  |  |  |
| Board | Remove Work-item from project | az devops wiki page delete |  |  |  |
| Board | Configure Board Card Fields |  |  |  |  |
| Board | Configure Board Card Styles |  |  |  |  |
| Board | Configure Board Card Tag colors |  |  |  |  |
| Board | Configure Board Card Annotations |  |  |  |  |
| Board | Configure Board Card Tests |  |  |  |  |
| Board | Configure Board Columns |  |  |  |  |
| Board | Configure Board Swimlanes |  |  |  |  |
| Board | Configure Board Card reordering |  |  |  |  |
| Board | Configure Board Status badge |  |  |  |  |
| Board | Configure Backlog Column options |  |  |  |  |
| Board | Configure Team member capacity |  |  |  |  |
| Board | Add Query to project |  |  |  |  |
| Board | Get Query from project |  |  |  |  |
| Board | Get Query details |  |  |  |  |
| Board | Edit Query details |  |  |  |  |
| Board | Remove Query from project |  |  |  |  |

## Repos

| Repos | Add Repository to project |  |  |  |  |
| Repos | Get Repository from project |  |  |  |  |
| Repos | Get Repository details |  |  |  |  |
| Repos | Edit Repository details |  |  |  |  |
| Repos | Remove Repository from project |  |  |  |  |
| Repos | Configure Repository Settings (Enable Forks) |  |  |  |  |
| Repos | Configure Repository Settings (Enable Commit mention linking) |  |  |  |  |
| Repos | Configure Repository Settings (Enable Commit mention work item resolution) |  |  |  |  |
| Repos | Configure Repository Settings (Enable Work item transition preferences) |  |  |  |  |
| Repos | Configure Repository Settings (Enable Permissions management) |  |  |  |  |
| Repos | Configure Repository Settings (Enable Strict Vote Mode) |  |  |  |  |
| Repos | Configure Repository Settings (Enable Inherit PR creation mode) |  |  |  |  |
| Repos | Configure Repository Settings (Enable Create PRs as draft by default) |  |  |  |  |
| Repos | Configure Repository Settings (Enable Disable Repository) |  |  |  |  |
| Repos | Configure Repository settings (Enable Default branch name for new repositories) |  |  |  |  |
| Repos | Configure Repository settings (Enable Allow users to manage permissions for their created branches) |  |  |  |  |
| Repos | Configure Repository settings (Enable Create PRs as draft by default) |  |  |  |  |
| Repos | Configure Repository policies (Enable Commit author email validation) |  |  |  |  |
| Repos | Configure Repository policies (Enable File path validation) |  |  |  |  |
| Repos | Configure Repository policies (Enable Case enforcement) |  |  |  |  |
| Repos | Configure Repository policies (Enable Reserved names) |  |  |  |  |
| Repos | Configure Repository policies (Enable Maximum path length) |  |  |  |  |
| Repos | Configure Repository policies (Enable Maximum file size) |  |  |  |  |
| Repos | Configure Repository policies (Add Require a minimum number of reviewers) |  |  |  |  |
| Repos | Configure Repository policies (Get Require a minimum number of reviewers) |  |  |  |  |
| Repos | Configure Repository policies (Edit Require a minimum number of reviewers) |  |  |  |  |
| Repos | Configure Repository policies (Add Check for linked work items) |  |  |  |  |
| Repos | Configure Repository policies (Get Check for linked work items) |  | https://learn.microsoft.com/en-us/cli/azure/devops/service-endpoint/azurerm?view=azure-cli-latest#az-devops-service-endpoint-azurerm-create |  |  |
| Repos | Configure Repository policies (Edit Check for linked work items) |  | https://learn.microsoft.com/en-us/cli/azure/devops/service-endpoint?view=azure-cli-latest#az-devops-service-endpoint-delete |  |  |
| Repos | Configure Repository policies (Add Check for comment resolution) |  | https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-create |  |  |
| Repos | Configure Repository policies (Get Check for comment resolution) |  | https://learn.microsoft.com/en-us/cli/azure/devops/security/group?view=azure-cli-latest#az-devops-security-group-delete |  |  |
| Repos | Configure Repository policies (Edit Check for comment resolution) |  | https://learn.microsoft.com/en-us/cli/azure/devops/team?view=azure-cli-latest#az-devops-team-create |  |  |
| Repos | Configure Repository policies (Add Limit merge types) |  | https://learn.microsoft.com/en-us/cli/azure/devops/team?view=azure-cli-latest#az-devops-team-delete |  |  |
| Repos | Configure Repository policies (Get Limit merge types) |  | https://learn.microsoft.com/en-us/cli/azure/devops/wiki?view=azure-cli-latest#az-devops-wiki-create |  |  |
| Repos | Configure Repository policies (Edit Limit merge types) |  | https://learn.microsoft.com/en-us/cli/azure/devops/wiki?view=azure-cli-latest#az-devops-wiki-delete |  |  |
| Repos | Configure Repository policies (Add Build Validation) |  | https://learn.microsoft.com/en-us/cli/azure/devops/wiki/page?view=azure-cli-latest#az-devops-wiki-page-create |  |  |
| Repos | Configure Repository policies (Get Build Validation) |  | https://learn.microsoft.com/en-us/cli/azure/devops/wiki/page?view=azure-cli-latest#az-devops-wiki-page-delete |  |  |
| Repos | Configure Repository policies (Get Build Validations) |  |  |  |  |
| Repos | Configure Repository policies (Edit Build Validation) |  |  |  |  |
| Repos | Configure Repository policies (Remove Build Validation) |  | https://learn.microsoft.com/en-us/cli/azure/boards/area/project?view=azure-cli-latest#az-boards-area-project-create |  |  |
| Repos | Configure Repository policies (Add Status Check) |  | https://learn.microsoft.com/en-us/cli/azure/boards/area/project?view=azure-cli-latest#az-boards-area-project-delete |  |  |
| Repos | Configure Repository policies (Get Status Check) |  | https://learn.microsoft.com/en-us/cli/azure/boards/area/team?view=azure-cli-latest#az-boards-area-team-add |  |  |
| Repos | Configure Repository policies (Get Status Checks) |  | https://learn.microsoft.com/en-us/cli/azure/boards/area/team?view=azure-cli-latest#az-boards-area-team-remove |  |  |
| Repos | Configure Repository policies (Edit Status Check) |  | https://learn.microsoft.com/en-us/cli/azure/boards/iteration/project?view=azure-cli-latest#az-boards-iteration-project-create |  |  |
| Repos | Configure Repository policies (Remove Status Check) |  | https://learn.microsoft.com/en-us/cli/azure/boards/iteration/project?view=azure-cli-latest#az-boards-iteration-project-delete |  |  |
| Repos | Configure Repository policies (Add Automatically included reviewers) |  | https://learn.microsoft.com/en-us/cli/azure/boards/iteration/team?view=azure-cli-latest#az-boards-iteration-team-add |  |  |
| Repos | Configure Repository policies (Get Automatically included reviewers) |  | https://learn.microsoft.com/en-us/cli/azure/boards/iteration/team?view=azure-cli-latest#az-boards-iteration-team-remove |  |  |
| Repos | Configure Repository policies (Edit Automatically included reviewers) |  | https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest#az-boards-work-item-create |  |  |
| Repos | Configure Repository policies (Remove Automatically included reviewers) |  | https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest#az-boards-work-item-delete |  |  |
| Repos | Configure Repository security  |  | https://learn.microsoft.com/en-us/cli/azure/boards/work-item/relation?view=azure-cli-latest#az-boards-work-item-relation-add |  |  |
| Repos | Add Tag to project |  |  |  |  |
| Repos | Get Tag from project |  |  |  |  |
| Repos | Get Tag details |  |  |  |  |
| Repos | Edit Tag details |  |  |  |  |
| Repos | Remove Tag from project |  |  |  |  |

## Pipelines

| Pipelines | Add Pipeline to project |  |  |  |  |
| Pipelines | Get Pipeline from project |  |  |  |  |
| Pipelines | Get Pipeline details |  |  |  |  |
| Pipelines | Edit Pipeline details |  |  |  |  |
| Pipelines | Remove Pipeline from project |  |  |  |  |
| Pipelines | Configure Pipeline security  |  |  |  |  |
| Pipelines | Add Environment to project |  |  |  |  |
| Pipelines | Get Environment from project |  |  |  |  |
| Pipelines | Get Environment details |  |  |  |  |
| Pipelines | Edit Environment details |  |  |  |  |
| Pipelines | Remove Environment from project |  |  |  |  |
| Pipelines | Add resource to environment (Kubernetes) |  |  |  |  |
| Pipelines | Get resources from environment (Kubernetes) |  |  |  |  |
| Pipelines | Get resource details from environment (Kubernetes) |  |  |  |  |
| Pipelines | Edit resource details (Kubernetes) |  |  |  |  |
| Pipelines | Remove resource from environment (Kubernetes) |  |  |  |  |
| Pipelines | Add resource to environment (VMSS) |  |  |  |  |
| Pipelines | Get resources from environment (VMSS) |  |  |  |  |
| Pipelines | Get resource details from environment (VMSS) |  |  |  |  |
| Pipelines | Edit resource details (VMSS) |  |  |  |  |
| Pipelines | Remove resource from environment (VMSS) |  |  |  |  |
| Pipelines | Add Approvals to environment |  |  |  |  |
| Pipelines | Get Approvals from environment |  |  |  |  |
| Pipelines | Get Approvals details from environment |  |  |  |  |
| Pipelines | Edit Approvals details |  |  |  |  |
| Pipelines | Remove Approvals from environment |  |  |  |  |
| Pipelines | Add Branch Control to environment |  |  |  |  |
| Pipelines | Get Branch Control from environment |  |  |  |  |
| Pipelines | Get Branch Control details from environment |  |  |  |  |
| Pipelines | Edit Branch Control details |  |  |  |  |
| Pipelines | Remove Branch Control from environment |  |  |  |  |
| Pipelines | Add Business Hours to environment |  |  |  |  |
| Pipelines | Get Business Hours from environment |  |  |  |  |
| Pipelines | Get Business Hours details from environment |  |  |  |  |
| Pipelines | Edit Business Hours details |  |  |  |  |
| Pipelines | Remove Business Hours from environment |  |  |  |  |
| Pipelines | Add Evaluate artifact (preview) to environment |  |  |  |  |
| Pipelines | Get Evaluate artifact (preview) from environment |  |  |  |  |
| Pipelines | Get Evaluate artifact (preview) details from environment |  |  |  |  |
| Pipelines | Edit Evaluate artifact (preview) details |  |  |  |  |
| Pipelines | Remove Evaluate artifact (preview) from environment |  |  |  |  |
| Pipelines | Add Exclusive Lock to environment |  |  |  |  |
| Pipelines | Get Exclusive Lock from environment |  |  |  |  |
| Pipelines | Get Exclusive Lock details from environment |  |  |  |  |
| Pipelines | Edit Exclusive Lock details |  |  |  |  |
| Pipelines | Remove Exclusive Lock from environment |  |  |  |  |
| Pipelines | Add Invoke Azure Function to environment |  |  |  |  |
| Pipelines | Get Invoke Azure Function from environment |  |  |  |  |
| Pipelines | Get Invoke Azure Function details from environment |  |  |  |  |
| Pipelines | Edit Invoke Azure Function details |  |  |  |  |
| Pipelines | Remove Invoke Azure Function from environment |  |  |  |  |
| Pipelines | Add Invoke REST API to environment |  |  |  |  |
| Pipelines | Get Invoke REST API from environment |  |  |  |  |
| Pipelines | Get Invoke REST API details from environment |  |  |  |  |
| Pipelines | Edit Invoke REST API details |  |  |  |  |
| Pipelines | Remove Invoke REST API from environment |  |  |  |  |
| Pipelines | Add Query Azure Monitor alerts to environment |  |  |  |  |
| Pipelines | Get Query Azure Monitor alerts from environment |  |  |  |  |
| Pipelines | Get Query Azure Monitor alerts details from environment |  |  |  |  |
| Pipelines | Edit Query Azure Monitor alerts details |  |  |  |  |
| Pipelines | Remove Query Azure Monitor alerts from environment |  |  |  |  |
| Pipelines | Add Required template to environment |  |  |  |  |
| Pipelines | Get Required template from environment |  |  |  |  |
| Pipelines | Get Required template details from environment |  |  |  |  |
| Pipelines | Edit Required template details |  |  |  |  |
| Pipelines | Remove Required template from environment |  |  |  |  |
| Pipelines | Configure Environment security  |  |  |  |  |
| Pipelines | Add Release pipeline to project |  |  |  |  |
| Pipelines | Get Release pipeline from project |  |  |  |  |
| Pipelines | Get Release pipeline details |  |  |  |  |
| Pipelines | Edit Release pipeline details |  |  |  |  |
| Pipelines | Remove Release pipeline from project |  |  |  |  |
| Pipelines | Add variable group to project |  |  |  |  |
| Pipelines | Get variable group from project |  |  |  |  |
| Pipelines | Get variable group details |  |  |  |  |
| Pipelines | Edit variable group details |  |  |  |  |
| Pipelines | Remove variable group from project |  |  |  |  |
| Pipelines | Add variable group variable to project |  |  |  |  |
| Pipelines | Get variable group variable from project |  |  |  |  |
| Pipelines | Get variable group variable details |  |  |  |  |
| Pipelines | Edit variable group variable details |  |  |  |  |
| Pipelines | Remove variable group variable from project |  |  |  |  |
| Pipelines | Add secure file to project |  |  |  |  |
| Pipelines | Get secure file from project |  |  |  |  |
| Pipelines | Get secure file details |  |  |  |  |
| Pipelines | Edit secure file details |  |  |  |  |
| Pipelines | Remove secure file from project |  |  |  |  |
| Pipelines | Configure Library security  |  |  |  |  |
| Pipelines | Import task group to project |  |  |  |  |
| Pipelines | Get task group from project |  |  |  |  |
| Pipelines | Get task group details |  |  |  |  |
| Pipelines | Edit task group details |  |  |  |  |
| Pipelines | Remove task group from project |  |  |  |  |
| Pipelines | Add Deployment groups to project |  |  |  |  |
| Pipelines | Get Deployment groups from project |  |  |  |  |
| Pipelines | Get Deployment groups details |  |  |  |  |
| Pipelines | Edit Deployment groups details |  |  |  |  |
| Pipelines | Remove Deployment groups from project |  |  |  |  |
| Pipelines | Configure Deployment groups security |

❌ = Not yet implemented
✔  = Already implemented
⚠  = Work in progress
