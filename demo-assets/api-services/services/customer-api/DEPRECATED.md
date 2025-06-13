# ⚠️ DEPRECATED - Customer API v1

**This API version is deprecated as of January 1, 2024**

## Migration Timeline

- **Deprecated**: January 1, 2024
- **End of Support**: June 30, 2024
- **Shutdown**: December 31, 2024

## Why is this deprecated?

- Security: v1 uses API keys instead of OAuth2
- Performance: v2 is 3x faster with better caching
- Features: v2 supports webhooks and real-time updates

## Migration Guide

1. Update your base URL from `/v1/customer-api` to `/v2/customer-api`
2. Switch from API key authentication to OAuth2
3. Update response parsing (v2 uses different field names)

## Still using v1?

Please contact the API team immediately at api-team@example.com

Current v1 usage: ~30% of traffic (should be 0%)
