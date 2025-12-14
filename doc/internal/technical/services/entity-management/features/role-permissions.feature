Feature: Role-Based Permissions
  As a tenant administrator
  I want to define custom roles with specific permissions
  So that I can implement fine-grained access control

  Background:
    Given the Entity Management Service is running
    And I am authenticated as tenant administrator for tenant "acme-corp"
    And the X-Tenant-ID header is set to my tenant_id

  Scenario: Create custom role
    When I create a role with:
      | name        | Project Manager                    |
      | description | Manages projects and teams         |
      | permissions | [                                  |
      |             |   "entity-management:read:*",     |
      |             |   "entity-management:write:own",  |
      |             |   "entity-management:approve:projects" |
      |             | ]                                  |
    Then the role should be created successfully
    And the role should have a unique role_id
    And the role should belong to my tenant
    And a RoleCreated event should be published

  Scenario: Assign custom role to user
    Given custom role "Project Manager" exists
    And user "alice@acme.example.com" exists
    When I assign role "Project Manager" to user "alice@acme.example.com"
    Then the user should have the custom role
    And the user should inherit all permissions from "Project Manager"
    And a UserRoleAssigned event should be published

  Scenario: Permission enforcement - allowed action
    Given user "bob@acme.example.com" has permission "entity-management:write:own"
    When user "bob" attempts to update their own entity
    Then the request should succeed with status 200

  Scenario: Permission enforcement - forbidden action
    Given user "carol@acme.example.com" has permission "entity-management:read:*"
    When user "carol" attempts to delete an entity
    Then the request should fail with status 403
    And the error should indicate "insufficient_permissions"
    And the error should specify required permission: "entity-management:delete:*"

  Scenario: Hierarchical role inheritance
    Given role "Senior Developer" inherits from "Developer"
    And "Developer" has permission "entity-management:read:*"
    And "Senior Developer" adds permission "entity-management:write:*"
    When I query permissions for "Senior Developer"
    Then it should have both:
      | entity-management:read:*  |
      | entity-management:write:* |

  Scenario: Cross-tenant role isolation
    Given tenant "acme-corp" has custom role "Acme Manager"
    And tenant "competitor-corp" has custom role "Competitor Admin"
    When I query roles as "acme-corp" admin
    Then I should only see roles from "acme-corp"
    And I should not see "Competitor Admin"

  Scenario: Update role permissions
    Given custom role "Reviewer" exists with permissions ["entity-management:read:*"]
    When I update "Reviewer" to add permission "entity-management:approve:*"
    Then the role should have both permissions
    And all users with "Reviewer" role should inherit new permission
    And a RolePermissionsUpdated event should be published

  Scenario: Delete custom role
    Given custom role "Deprecated Role" exists
    And no users are assigned to "Deprecated Role"
    When I delete "Deprecated Role"
    Then the role should be deleted successfully
    And a RoleDeleted event should be published

  Scenario: Prevent deleting role with assigned users
    Given custom role "Active Role" exists
    And 5 users are assigned to "Active Role"
    When I attempt to delete "Active Role"
    Then the request should fail with status 409
    And the error should indicate "role_in_use"
    And the error should list the number of assigned users

  Scenario: Permission scope validation
    Given I create a role with permission "entity-management:delete:own"
    When user with this role attempts to delete another user's entity
    Then the request should fail with status 403
    And only entities owned by the user should be deletable
