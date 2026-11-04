# Security and secrets

## Files

- Do not read `.env`. It holds secrets.
- `.env.example` lists variable names such as `AWS_DEFAULT_REGION` and the Snowflake settings. It must not list access keys or other secret values.

## Runtime secrets

- `MASSIVE_API_KEY`, the Snowflake key-pair path (`SNOWFLAKE_PRIVATE_KEY_PATH`), and the optional `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE` come from the environment.
- AWS credentials come from the normal boto3 chain. This machine has no shared AWS credentials file, so local runs load access keys from the gitignored `.env`. Deployed runs use IAM roles (and GitHub OIDC in CI), never stored access keys.
- Region is `AWS_DEFAULT_REGION` only. Do not add `AWS_REGION`.

## Snowflake

- Auth is key-pair (`SNOWFLAKE_JWT`).
- The storage integration IAM policy is read-only. The extract writer is a different identity.
- `transform/profiles.yml` reads the same Snowflake names through `env_var` only, with no secrets in the file.
- dbt loads `.env` from its working directory (`transform/`), not the repo-root `.env` that Python reads through `load_local_env()`. Keep a gitignored `transform/.env` link to the root `.env`.
