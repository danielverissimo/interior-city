-- vRP creates a user with only whitelisted and banned under strict SQL mode.
ALTER TABLE vrp_users
  ALTER COLUMN last_login SET DEFAULT '',
  ALTER COLUMN ip SET DEFAULT '';
