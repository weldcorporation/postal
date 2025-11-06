# WeldMail Postal Fork

This is a fork of [Postal](https://github.com/postalserver/postal) with custom API extensions for domain management, specifically designed for the WeldMail platform.

## What's Different?

This fork adds **Domain Management API endpoints** to Postal's Legacy API v1, enabling programmatic domain creation, verification, and DNS checking.

### New API Endpoints

All endpoints use `X-Server-API-Key` authentication and `application/json` content type.

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/domains/list` | POST | List all domains for the authenticated server |
| `/api/v1/domains/info` | POST | Get detailed domain information including DKIM keys |
| `/api/v1/domains/create` | POST | Create new domain with automatic DKIM generation |
| `/api/v1/domains/verify` | POST | Verify domain ownership via DNS TXT record |
| `/api/v1/domains/check_dns` | POST | Check all DNS records (SPF, DKIM, MX, Return Path) |
| `/api/v1/domains/delete` | POST | Delete a domain |

## Quick Links

- **[API Documentation](WELDMAIL_API_EXTENSIONS.md)** - Complete API reference with examples
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - How to deploy changes to Hetzner server
- **[Deployment Instructions](DEPLOYMENT.md)** - Initial deployment setup

## Current Deployment

**Server:** Hetzner Cloud @ 65.108.218.32
**Port:** 5000 (HTTP)
**Method:** Docker Compose

**API Base URL:** `http://65.108.218.32:5000/api/v1`

## Files Changed from Upstream

```
app/controllers/legacy_api/domains_controller.rb  (NEW)
config/routes.rb                                   (MODIFIED)
WELDMAIL_API_EXTENSIONS.md                         (NEW)
DEPLOYMENT_GUIDE.md                                (NEW)
DEPLOYMENT.md                                      (NEW)
README.weldmail.md                                 (NEW - this file)
```

## Integration with WeldMail

The WeldMail API (`E:\Repos\weldmail\backend`) uses these endpoints to:

1. **Automatically create domains** when users add them
2. **Retrieve DKIM public keys** for DNS configuration
3. **Verify domain ownership** via DNS
4. **Check DNS record status** for SPF, DKIM, DMARC

See `WeldMail.Infrastructure.Services.PostalDomainService` for integration code.

## Making Changes

See **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** for detailed instructions.

### Quick Deploy

```powershell
# From E:\Repos\weldmail\postal

# 1. Make your changes
# 2. Test and commit
git add -A
git commit -m "Your changes"
git push

# 3. Deploy to server
cat app/controllers/legacy_api/domains_controller.rb | ssh root@65.108.218.32 "cat > /tmp/domains_controller.rb"
cat config/routes.rb | ssh root@65.108.218.32 "cat > /tmp/routes.rb"

ssh root@65.108.218.32 @"
docker cp /tmp/domains_controller.rb postal-web:/opt/postal/app/app/controllers/legacy_api/domains_controller.rb
docker cp /tmp/routes.rb postal-web:/opt/postal/app/config/routes.rb
docker cp /tmp/domains_controller.rb postal-worker:/opt/postal/app/app/controllers/legacy_api/domains_controller.rb
docker cp /tmp/routes.rb postal-worker:/opt/postal/app/config/routes.rb
cd /opt/postal && docker compose restart postal-web postal-worker
rm -f /tmp/*.rb
"@
```

## Original Postal Documentation

For general Postal documentation, see the [official Postal docs](https://docs.postalserver.io/).

The original Postal README is preserved in the repository.

## Upstream Synchronization

⚠️ **Note:** This fork is not automatically synced with upstream. Manual merging is required to incorporate upstream changes.

To sync with upstream:

```bash
# Add upstream remote (one time only)
git remote add upstream https://github.com/postalserver/postal.git

# Fetch upstream changes
git fetch upstream

# Merge upstream main into your main
git checkout main
git merge upstream/main

# Resolve conflicts (especially in routes.rb)
# Commit and push
git push origin main

# Redeploy to server
```

## Version

Based on: **Postal v3.x** (check `VERSION` file in repo)

WeldMail Extensions Version: **1.0.0**

## License

Same as original Postal: [MIT License](MIT-LICENCE)

## Support

For WeldMail-specific issues:
- Repository: https://github.com/weldcorporation/postal
- WeldMail Main Repo: https://github.com/weldcorporation/weldmail

For general Postal questions:
- Upstream: https://github.com/postalserver/postal
- Docs: https://docs.postalserver.io/

## Changelog

### v1.0.0 (2025-11-06)

**Initial WeldMail extensions:**

- ✨ Added domain management API endpoints
- ✨ Domain creation with automatic DKIM key generation
- ✨ Domain ownership verification via DNS
- ✨ DNS record checking (SPF, DKIM, MX, Return Path)
- 📝 Complete API documentation
- 📝 Deployment guides
- 🚀 Deployed to production Hetzner server

**Files Added:**
- `app/controllers/legacy_api/domains_controller.rb`
- `WELDMAIL_API_EXTENSIONS.md`
- `DEPLOYMENT_GUIDE.md`
- `DEPLOYMENT.md`
- `README.weldmail.md`

**Files Modified:**
- `config/routes.rb` - Added 6 new domain management routes

---

**Repository:** https://github.com/weldcorporation/postal
**Maintained by:** WeldMail Team
