-- Add neutral user role for roleless signup
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'member';

-- Invitation and assignment status enums
CREATE TYPE assignment_status AS ENUM ('pending', 'active', 'inactive');
CREATE TYPE invite_type AS ENUM ('agent', 'tenant');
CREATE TYPE invite_status AS ENUM ('pending', 'accepted', 'expired', 'revoked');

-- Support multiple agents per property
CREATE TABLE property_agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status assignment_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(property_id, user_id)
);

CREATE INDEX idx_property_agents_property_id ON property_agents(property_id);
CREATE INDEX idx_property_agents_user_id ON property_agents(user_id);
CREATE INDEX idx_property_agents_status ON property_agents(status);

-- Track invitation lifecycle for user onboarding
CREATE TABLE user_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR NOT NULL,
    name VARCHAR,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    invite_type invite_type NOT NULL,
    invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invited_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    token VARCHAR NOT NULL UNIQUE,
    status invite_status NOT NULL DEFAULT 'pending',
    expires_at TIMESTAMPTZ NOT NULL,
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_invites_email ON user_invites(email);
CREATE INDEX idx_user_invites_token ON user_invites(token);
CREATE INDEX idx_user_invites_property_id ON user_invites(property_id);
CREATE INDEX idx_user_invites_status ON user_invites(status);

CREATE TRIGGER update_property_agents_updated_at BEFORE UPDATE ON property_agents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_invites_updated_at BEFORE UPDATE ON user_invites
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
