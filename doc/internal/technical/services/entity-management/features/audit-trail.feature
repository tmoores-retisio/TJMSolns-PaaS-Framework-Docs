Feature: Audit Trail
  As a compliance officer
  I want complete audit logs of all entity changes
  So that I can meet regulatory requirements and investigate issues

  Background:
    Given the Entity Management Service is running
    And audit logging is enabled

  Scenario: Record tenant creation in audit log
    Given I am authenticated as platform administrator
    When I create a tenant "Acme Corp"
    Then an audit event should be recorded with:
      | event_type    | audit.tenant.created              |
      | tenant_id     | {new_tenant_id}                   |
      | user_id       | {admin_user_id}                   |
      | action        | CREATE                            |
      | resource_type | tenant                            |
      | resource_id   | {new_tenant_id}                   |
      | result        | success                           |
      | ip_address    | {requester_ip}                    |
    And the audit event should be immutable
    And the audit event should be stored for 7 years

  Scenario: Record failed authentication attempt
    When an invalid JWT token is used to access tenant data
    Then an audit event should be recorded with:
      | event_type    | audit.auth.failed                 |
      | tenant_id     | {attempted_tenant_id}             |
      | user_id       | null                              |
      | action        | AUTHENTICATE                      |
      | result        | failure                           |
      | reason        | invalid_token                     |

  Scenario: Record cross-tenant access attempt
    Given tenant "acme-corp" has entity "entity-123"
    When user from tenant "competitor-corp" attempts to access "entity-123"
    Then an audit event should be recorded with:
      | event_type    | audit.security.cross_tenant_access |
      | tenant_id     | competitor-corp                   |
      | user_id       | {attacker_user_id}                |
      | action        | READ                              |
      | resource_type | entity                            |
      | resource_id   | entity-123                        |
      | result        | denied                            |
      | severity      | high                              |
    And a security alert should be triggered

  Scenario: Record data modification with before/after state
    Given entity "org-456" exists with name "Engineering"
    When I update entity "org-456" to have name "Engineering Department"
    Then an audit event should be recorded with:
      | event_type    | audit.entity.updated              |
      | resource_id   | org-456                           |
      | details       | {                                 |
      |               |   "field_changed": "name",       |
      |               |   "old_value": "Engineering",    |
      |               |   "new_value": "Engineering Department" |
      |               | }                                 |

  Scenario: Query audit trail by tenant
    Given tenant "acme-corp" has multiple audit events
    When I query audit logs filtered by tenant_id "acme-corp"
    Then I should receive all events for "acme-corp"
    And events should be ordered by timestamp descending
    And each event should include complete context

  Scenario: Query audit trail by user
    Given user "admin@acme.example.com" performed multiple actions
    When I query audit logs filtered by user_id
    Then I should receive all events for that user
    And events should show user's activity timeline

  Scenario: Query audit trail by date range
    When I query audit logs for date range 2025-01-01 to 2025-01-31
    Then I should receive all events within that range
    And events outside the range should not be included

  Scenario: Audit log retention policy
    Given audit events older than 7 years exist
    When the retention policy runs
    Then events older than 7 years should remain (not deleted)
    And events should be archived to cold storage
    But events should still be queryable for compliance

  Scenario: Tamper-proof audit logs
    Given audit events are stored in append-only event store
    When I attempt to modify an existing audit event
    Then the modification should be rejected
    And the original event should remain unchanged
    And an alert should be triggered for tampering attempt

  Scenario: Audit sensitive data access
    Given user "analyst@acme.example.com" has access to PII
    When user "analyst" views user record containing PII
    Then an audit event should be recorded with:
      | event_type    | audit.data.pii_accessed           |
      | data_classification | pii                         |
      | fields_accessed | [email, phone, address]         |
    And the event should be flagged for compliance review
