Feature: Organization Hierarchy Management
  As a tenant administrator
  I want to manage organization hierarchies within my tenant
  So that I can model my company structure and delegate permissions

  Background:
    Given the Entity Management Service is running
    And I am authenticated as tenant administrator for tenant "acme-corp"
    And the X-Tenant-ID header is set to my tenant_id

  Scenario: Create root organization
    When I create an organization with:
      | name        | Acme Corporation           |
      | description | Parent company             |
      | parent_id   | null                       |
    Then the organization should be created successfully
    And the organization should have a unique organization_id
    And the organization should belong to my tenant
    And the parent_id should be null (root organization)
    And an OrganizationCreated event should be published

  Scenario: Create child organization
    Given a root organization "Acme Corporation" exists in my tenant
    When I create an organization with:
      | name        | Engineering Department     |
      | description | Technical team             |
      | parent_id   | {root_org_id}             |
    Then the organization should be created successfully
    And the parent_id should reference the root organization
    And the hierarchy depth should be 1
    And an OrganizationCreated event should be published

  Scenario: Prevent circular hierarchy
    Given organization A is parent of organization B
    And organization B is parent of organization C
    When I attempt to set organization A as child of organization C
    Then the request should fail with status 422
    And the error should indicate "circular_hierarchy_detected"

  Scenario: List organization hierarchy
    Given the following organization structure exists in my tenant:
      | Acme Corporation (root)              |
      |   └─ Engineering                     |
      |       ├─ Backend Team                |
      |       └─ Frontend Team               |
      |   └─ Sales                           |
    When I query the organization hierarchy from root
    Then I should receive the complete tree structure
    And all organizations should belong to my tenant

  Scenario: Cross-tenant isolation in organization queries
    Given tenant "acme-corp" has organization "Acme Engineering"
    And tenant "competitor-corp" has organization "Competitor Engineering"
    When I query organizations as "acme-corp" user
    Then I should only see organizations from "acme-corp"
    And I should not see "Competitor Engineering"
    And attempting to access "Competitor Engineering" by ID should return 404

  Scenario: Delete organization cascades to children
    Given the following structure exists:
      | Engineering                          |
      |   └─ Backend Team                    |
    When I delete organization "Engineering"
    Then "Engineering" should be deleted
    And "Backend Team" should also be deleted (cascade)
    And OrganizationDeleted events should be published for both

  Scenario: Move organization to new parent
    Given organization "Backend Team" has parent "Engineering"
    When I update "Backend Team" to have parent "Operations"
    Then the parent_id should be updated to "Operations"
    And an OrganizationMoved event should be published
    And the hierarchy should remain acyclic
