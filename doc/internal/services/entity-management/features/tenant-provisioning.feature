Feature: Tenant Provisioning
  As a platform administrator
  I want to provision new tenants with their initial configuration
  So that customers can start using the platform immediately

  Background:
    Given the Entity Management Service is running
    And I am authenticated as a platform administrator

  Scenario: Provision new tenant with Bronze plan
    Given a new organization "Acme Corp" wants to join
    When I create a tenant with:
      | name              | Acme Corp                          |
      | subscription_plan | bronze                             |
      | admin_email       | admin@acme.example.com            |
      | admin_name        | Jane Admin                         |
    Then the tenant should be created successfully
    And the tenant should have a unique tenant_id
    And the subscription plan should be "bronze"
    And an admin user should be created with email "admin@acme.example.com"
    And the admin user should have role "tenant-owner"
    And a TenantProvisioned event should be published to Kafka
    And the event should include tenant_id in metadata

  Scenario: Provision tenant with invalid subscription plan
    When I attempt to create a tenant with:
      | name              | Invalid Corp                       |
      | subscription_plan | platinum                           |
      | admin_email       | admin@invalid.example.com         |
    Then the request should fail with status 422
    And the error should indicate "invalid_subscription_plan"
    And the error details should list valid plans: [bronze, silver, gold]

  Scenario: Prevent duplicate tenant names
    Given a tenant exists with name "Existing Corp"
    When I attempt to create another tenant with:
      | name              | Existing Corp                      |
      | subscription_plan | silver                             |
      | admin_email       | admin@new.example.com             |
    Then the request should fail with status 409
    And the error should indicate "tenant_name_conflict"

  Scenario: Tenant inherits entitlements from subscription plan
    When I create a tenant with subscription_plan "gold"
    Then the tenant should have entitlement "entity-management-service" enabled
    And the tenant should have entitlement "advanced-search" enabled
    And the tenant should have rate_limit 10000 requests per minute

  Scenario: Cross-tenant isolation during provisioning
    Given tenant "tenant-a" exists
    When I provision tenant "tenant-b"
    Then tenant-b should not have access to tenant-a data
    And querying tenant-a entities with tenant-b credentials should return 404
