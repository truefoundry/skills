# Secrets & Access Tokens

Manage secret groups, secret references (tfy-secret://), and personal access tokens (PATs).

## Secrets

Manage TrueFoundry secret groups and secret references.

Use this section when the user wants to:

- List secret groups.
- Inspect which keys exist in a secret group without revealing values.
- Create a new secret group.
- Add or rotate secret values.
- Find the `tfy-secret://tenant:group:key` reference for use in manifests.

Never ask the user to paste raw secret values in chat. Ask them to set values in their shell or use the dashboard.

### List Secret Groups

```bash
TFY_API_SH=~/.claude/skills/truefoundry-platform/scripts/tfy-api.sh
$TFY_API_SH GET /api/svc/v1/secret-groups
```

Present:

```text
Secret Groups
| Name | ID | Keys | Updated |
```

Show key names only. Do not display secret values.

### Create Secret Group

Before creating, collect:

- Secret group name
- Secret store integration ID
- Key names
- Confirmation that values are available as environment variables or will be entered in the dashboard

Example API pattern:

```bash
payload=$(jq -n \
  --arg name "my-secrets" \
  --arg integration "INTEGRATION_ID" \
  --arg db_password "$DB_PASSWORD" \
  '{
    name: $name,
    integrationId: $integration,
    secrets: [{key: "DB_PASSWORD", value: $db_password}]
  }')
$TFY_API_SH POST /api/svc/v1/secret-groups "$payload"
```

### Update Secret Group

Secret group updates can remove omitted keys. Treat every update as sensitive:

1. Fetch the current group and key list.
2. Preserve every existing key unless the user explicitly says to remove it.
3. Ask the user to provide new values through environment variables or the dashboard.
4. Show the resulting key list without values.
5. Ask for explicit confirmation.

### Secret References

Use this format in manifests:

```text
tfy-secret://<tenant-name>:<secret-group-name>:<secret-key>
```

### Delete

Do not delete secret groups or individual secrets from the agent. If deletion is requested, direct the user to the TrueFoundry dashboard.

## Access Tokens

Manage TrueFoundry personal access tokens (PATs). List and create tokens used for API authentication, CI/CD pipelines, and AI Gateway access.

> **Security Policy: Credential Handling**
> - The agent MUST NOT repeat, store, or log token values in its own responses.
> - After creating a token, direct the user to copy the value from the API response output above -- do not re-display it.
> - Never include token values in summaries, follow-up messages, or any other output.

### Preflight

Verify existing credentials using the Status Check section before proceeding with token operations.

If the user does not have a tenant or CLI login yet, do not continue with token APIs. Use the `truefoundry-onboard` skill first.

When using direct API, set `TFY_API_SH` to the full path of this skill's `scripts/tfy-api.sh`. See `references/tfy-api-setup.md` for paths per agent.

### List Access Tokens

#### Via Tool Call
```
tfy_access_tokens_list()
```

#### Via Direct API
```bash
TFY_API_SH=~/.claude/skills/truefoundry-platform/scripts/tfy-api.sh

# List all personal access tokens
$TFY_API_SH GET /api/svc/v1/personal-access-tokens
```

Present results:
```
Personal Access Tokens:
| Name          | ID       | Created At  | Expires At  |
|---------------|----------|-------------|-------------|
| ci-pipeline   | pat-abc  | 2025-01-15  | 2025-07-15  |
| dev-local     | pat-def  | 2025-03-01  | Never       |
```

**Security:** Never display token values. They are only shown once at creation time.

### Create Access Token

Ask the user for a token name before creating.

#### Via Tool Call
```
tfy_access_tokens_create(payload={"name": "my-token"})
```

**Note:** Requires human approval (HITL) via tool call.

#### Via Direct API
```bash
# Create a new personal access token
$TFY_API_SH POST /api/svc/v1/personal-access-tokens '{"name":"my-token"}'
```

**IMPORTANT:** The token value is returned ONLY in the creation response.

> **Security: Token Display Policy**
> - Default to showing only a masked preview (for example: first 4 + last 4 characters).
> - Show the full token only after explicit user confirmation that they are ready to copy it now.
> - If a full token is shown, show it only once, in a minimal response, and never repeat it in summaries/follow-up messages.
> - The agent must NEVER store, log, or re-display the token value after the initial one-time reveal.
> - If the user asks to see the token again later, instruct them to create a new token.

Present the result:
```
Token created successfully!
Name: my-token
Token (masked): tfy_****...****

If user explicitly confirms they are ready to copy it:
One-time token: <full value from API response>

Save this token NOW -- it will not be shown again.
Store it in a password manager, CI/CD secret store, or TrueFoundry secret group.
Never commit tokens to Git or share them in plain text.
```

### Delete Access Token

Do not delete PATs from the agent. If deletion is requested, direct the user to the TrueFoundry dashboard.
