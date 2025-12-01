Feature: User Management
  As a tenant administrator
  I want to manage users within my tenant
  So that I can control who has access to the system

  Background:
    Given the Entity Management Service is running
    And I am authenticated as tenant administrator for tenant "acme-corp"
    And the X-Tenant-ID header is set to my tenant_id

  Scenario: Create new user in tenant
    When I create a user with:
      | email            | john.doe@acme.example.com     |
      | name             | John Doe                       |
      | role             | tenant-user                    |
      | organization_id  | {engineering_org_id}          |
    Then the user should be created successfully
    And the user should have a unique user_id
    And the user should belong to my tenant
    And the user should have role "tenant-user"
    And a UserCreated event should be published

  Scenario: Assign user to organization
    Given user "Jane Smith" exists in my tenant
    And organization "Sales Department" exists in my tenant
    When I assign user "Jane Smith" to organization "Sales Department"
    Then the user's organization_id should be updated
    And a UserAssignedToOrganization event should be published

  Scenario: Update user role
    Given user "Bob Jones" has role "tenant-user"
    When I update Bob's role to "tenant-admin"
    Then the role should be updated successfully
    And a UserRoleChanged event should be published
    And the event should include old_role and new_role

  Scenario: Cross-tenant user isolation
    Given tenant "acme-corp" has user "alice@acme.example.com"
    And tenant "competitor-corp" has user "bob@competitor.example.com"
    When I query users as "acme-corp" admin
    Then I should only see users from "acme-corp"
    And I should not see "bob@competitor.example.com"

  Scenario: Prevent cross-tenant user access
    Given tenant "acme-corp" has user with user_id "123e4567..."
    When I attempt to access user "123e4567..." with tenant "competitor-corp" credentials
    Then the request should fail with status 404
    And no user data should be leaked

  Scenario: Deactivate user
    Given active user "charlie@acme.example.com" exists
    When I deactivate user "charlie@acme.example.com"
    Then the user status should be "inactive"
    And the user should no longer be able to authenticate
    And a UserDeactivated event should be published

  Scenario: List users filtered by organization
    Given the following users exist in my tenant:
      | Email                      | Organization   |
      | eng1@acme.example.com     | Engineering    |
      | eng2@acme.example.com     | Engineering    |
      | sales1@acme.example.com   | Sales          |
    When I query users filtered by organization "Engineering"
    Then I should receive 2 users
    And both should belong to "Engineering"

  Scenario: Prevent duplicate email within tenant
    Given user "existing@acme.example.com" exists in my tenant
    When I attempt to create another user with email "existing@acme.example.com"
    Then the request should fail with status 409
    And the error should indicate "duplicate_email"

  Scenario: User role permissions enforced
    Given I am authenticated as "tenant-user" (not admin)
    When I attempt to create a new user
    Then the request should fail with status 403
    And the error should indicate "insufficient_permissions"
