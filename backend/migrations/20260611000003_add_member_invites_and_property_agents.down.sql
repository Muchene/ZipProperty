DROP TRIGGER IF EXISTS update_user_invites_updated_at ON user_invites;
DROP TRIGGER IF EXISTS update_property_agents_updated_at ON property_agents;

DROP TABLE IF EXISTS user_invites;
DROP TABLE IF EXISTS property_agents;

DROP TYPE IF EXISTS invite_status;
DROP TYPE IF EXISTS invite_type;
DROP TYPE IF EXISTS assignment_status;

-- PostgreSQL enums cannot safely remove specific values in-place.
-- The 'member' value in user_role is intentionally retained on rollback.
