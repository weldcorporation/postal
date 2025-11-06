# WeldMail Postal Deployment Guide

This guide explains how to make changes to the Postal API extensions and deploy them to your Hetzner server.

## Overview

Your Postal instance runs on **Hetzner server at 65.108.218.32** using Docker containers.

**Repository:** `E:\Repos\weldmail\postal` (Fork of postalserver/postal)

**Containers on server:**
- `postal-web` - Main web interface and API (port 5000)
- `postal-worker` - Background job processor
- `postal-smtp-incoming` - Incoming email (port 25)
- `postal-smtp-submission` - Outgoing email (port 587)

## Quick Deploy

### PowerShell (Windows)

```powershell
cd E:\Repos\weldmail\postal

# Copy files to server
cat app/controllers/legacy_api/domains_controller.rb | ssh root@65.108.218.32 "cat > /tmp/domains_controller.rb"
cat config/routes.rb | ssh root@65.108.218.32 "cat > /tmp/routes.rb"

# Deploy to containers
ssh root@65.108.218.32 @"
docker cp /tmp/domains_controller.rb postal-web:/opt/postal/app/app/controllers/legacy_api/domains_controller.rb
docker cp /tmp/routes.rb postal-web:/opt/postal/app/config/routes.rb
docker cp /tmp/domains_controller.rb postal-worker:/opt/postal/app/app/controllers/legacy_api/domains_controller.rb
docker cp /tmp/routes.rb postal-worker:/opt/postal/app/config/routes.rb
cd /opt/postal && docker compose restart postal-web postal-worker
rm -f /tmp/domains_controller.rb /tmp/routes.rb
"@
```

### Git Bash (Windows/Linux/Mac)

```bash
cd /e/Repos/weldmail/postal

# Copy files to server
cat app/controllers/legacy_api/domains_controller.rb | ssh root@65.108.218.32 "cat > /tmp/domains_controller.rb"
cat config/routes.rb | ssh root@65.108.218.32 "cat > /tmp/routes.rb"

# Deploy to containers
ssh root@65.108.218.32 << 'EOF'
docker cp /tmp/domains_controller.rb postal-web:/opt/postal/app/app/controllers/legacy_api/domains_controller.rb
docker cp /tmp/routes.rb postal-web:/opt/postal/app/config/routes.rb
docker cp /tmp/domains_controller.rb postal-worker:/opt/postal/app/app/controllers/legacy_api/domains_controller.rb
docker cp /tmp/routes.rb postal-worker:/opt/postal/app/config/routes.rb
cd /opt/postal && docker compose restart postal-web postal-worker
rm -f /tmp/domains_controller.rb /tmp/routes.rb
EOF
```

## Step-by-Step Deployment

### 1. Make Changes Locally

Edit files in `E:\Repos\weldmail\postal`:

**Common files:**
- `app/controllers/legacy_api/domains_controller.rb` - API endpoints
- `config/routes.rb` - API routes
- `WELDMAIL_API_EXTENSIONS.md` - API documentation

### 2. Test Your Changes (Optional but Recommended)

If you have Ruby installed locally:

```bash
cd E:\Repos\weldmail\postal

# Check syntax
ruby -c app/controllers/legacy_api/domains_controller.rb
ruby -c config/routes.rb
```

### 3. Commit to Git

```bash
cd E:\Repos\weldmail\postal

git add app/controllers/legacy_api/domains_controller.rb
git add config/routes.rb
git add WELDMAIL_API_EXTENSIONS.md

git commit -m "Descriptive message about your changes"

git push origin main
```

### 4. Copy Files to Server

**Option A: Using cat and pipe (recommended)**

```bash
# Copy controller
cat app/controllers/legacy_api/domains_controller.rb | ssh root@65.108.218.32 "cat > /tmp/domains_controller.rb"

# Copy routes
cat config/routes.rb | ssh root@65.108.218.32 "cat > /tmp/routes.rb"
```

**Option B: Using scp**

```bash
scp app/controllers/legacy_api/domains_controller.rb root@65.108.218.32:/tmp/
scp config/routes.rb root@65.108.218.32:/tmp/
```

### 5. Deploy to Docker Containers

SSH into server:

```bash
ssh root@65.108.218.32
```

Copy files into containers:

```bash
# Copy to web container
docker cp /tmp/domains_controller.rb postal-web:/opt/postal/app/app/controllers/legacy_api/domains_controller.rb
docker cp /tmp/routes.rb postal-web:/opt/postal/app/config/routes.rb

# Copy to worker container
docker cp /tmp/domains_controller.rb postal-worker:/opt/postal/app/app/controllers/legacy_api/domains_controller.rb
docker cp /tmp/routes.rb postal-worker:/opt/postal/app/config/routes.rb
```

### 6. Restart Containers

```bash
cd /opt/postal
docker compose restart postal-web postal-worker
```

Wait about 10-15 seconds for containers to fully restart.

### 7. Clean Up

```bash
rm -f /tmp/domains_controller.rb /tmp/routes.rb
exit
```

## Verification

### Check Containers Are Running

```bash
ssh root@65.108.218.32 "docker ps | grep postal"
```

You should see all containers with status "Up".

### Check Logs

```bash
ssh root@65.108.218.32 "docker logs --tail 20 postal-web"
```

Look for errors. Successful start shows:
```
* Listening on http://0.0.0.0:5000
Use Ctrl-C to stop
```

### Test API Endpoint

```bash
curl -X POST http://65.108.218.32:5000/api/v1/domains/list \
  -H "X-Server-API-Key: rak1G5qA3lRiPnEeX4n4T0oX" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Should return JSON with status "success".

## Common Issues & Solutions

### Issue: Containers won't restart

**Solution 1: Check for syntax errors**
```bash
ssh root@65.108.218.32 "docker exec postal-web ruby -c /opt/postal/app/app/controllers/legacy_api/domains_controller.rb"
```

**Solution 2: Check logs**
```bash
ssh root@65.108.218.32 "docker logs postal-web 2>&1 | tail -50"
```

**Solution 3: Force restart**
```bash
ssh root@65.108.218.32 "cd /opt/postal && docker compose down && docker compose up -d"
```

### Issue: API returns 404

**Cause:** Routes not loaded

**Check routes:**
```bash
ssh root@65.108.218.32 "docker exec postal-web grep 'Domain Management' /opt/postal/app/config/routes.rb -A 10"
```

**Solution:** Ensure routes.rb was copied and containers restarted.

### Issue: API returns 500

**Cause:** Code error in controller

**Check logs:**
```bash
ssh root@65.108.218.32 "docker logs postal-web 2>&1 | grep -i error"
```

**Debug:** Look at the error message and fix the code, then redeploy.

### Issue: Changes not taking effect

**Cause:** Files not copied to container or container not restarted

**Verify file was copied:**
```bash
ssh root@65.108.218.32 "docker exec postal-web cat /opt/postal/app/app/controllers/legacy_api/domains_controller.rb | head -20"
```

**Force restart:**
```bash
ssh root@65.108.218.32 "cd /opt/postal && docker compose restart postal-web postal-worker"
```

## Rollback

### Method 1: Git Revert

```bash
cd E:\Repos\weldmail\postal

# View recent commits
git log --oneline -5

# Revert last commit
git revert HEAD

# Or reset to specific commit
git reset --hard COMMIT_HASH

# Push
git push origin main

# Then redeploy using steps above
```

### Method 2: Emergency Rollback

If Postal is completely broken:

```bash
ssh root@65.108.218.32

cd /opt/postal

# Stop all containers
docker compose down

# Remove customizations (WARNING: loses all custom code!)
docker compose pull

# Start with fresh images
docker compose up -d
```

**Note:** This removes ALL customizations. You'll need to redeploy from a working Git commit.

## Adding a New API Endpoint

### Example: Add a "get stats" endpoint

**1. Edit controller** (`domains_controller.rb`):

```ruby
# POST /api/v1/domains/stats
def stats
  domain_name = api_params["name"]

  if domain_name.blank?
    render_parameter_error "Domain name is required"
    return
  end

  domain = @current_credential.server.domains.find_by(name: domain_name)

  if domain.nil?
    render_error "DomainNotFound", message: "Domain '#{domain_name}' not found"
    return
  end

  # Your logic here
  stats_data = {
    total_sent: 1234,
    total_received: 567,
    bounce_rate: 0.02
  }

  render_success stats: stats_data
end
```

**2. Add route** (`routes.rb`):

```ruby
match "/api/v1/domains/stats" => "legacy_api/domains#stats", via: [:get, :post, :patch, :put]
```

**3. Update documentation** (`WELDMAIL_API_EXTENSIONS.md`):

````markdown
### Get Domain Stats

**Endpoint:** `POST /api/v1/domains/stats`

**Request:**
```json
{
  "name": "example.com"
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "stats": {
      "total_sent": 1234,
      "total_received": 567,
      "bounce_rate": 0.02
    }
  }
}
```
````

**4. Deploy:**
```bash
# Commit
git add -A
git commit -m "Add domain stats endpoint"
git push

# Deploy (use Quick Deploy commands above)
```

## File Locations

### Local (Your Computer)

```
E:\Repos\weldmail\postal\
├── app/
│   └── controllers/
│       └── legacy_api/
│           └── domains_controller.rb
├── config/
│   └── routes.rb
├── WELDMAIL_API_EXTENSIONS.md
└── DEPLOYMENT_GUIDE.md (this file)
```

### Server (Inside Docker Containers)

```
Container: postal-web, postal-worker
Location: /opt/postal/app/

/opt/postal/app/
├── app/
│   └── controllers/
│       └── legacy_api/
│           └── domains_controller.rb
└── config/
    └── routes.rb
```

### Docker Compose

```
Server: /opt/postal/docker-compose.yml
```

## Best Practices

### ✅ DO

- Commit all changes to Git before deploying
- Test syntax before deploying (`ruby -c filename.rb`)
- Check logs after deployment
- Deploy during low-traffic times
- Keep SSH session open until verified
- Update API documentation when adding endpoints

### ❌ DON'T

- Deploy without committing to Git
- Deploy untested code to production
- Forget to restart containers after copying files
- Deploy to only one container (deploy to both web and worker)
- Close SSH until you verify deployment worked

## Useful Commands

### Container Management

```bash
# List all containers
docker ps

# View logs
docker logs postal-web
docker logs postal-worker

# Restart specific container
docker compose restart postal-web

# Restart all Postal containers
docker compose restart

# Stop all containers
docker compose down

# Start all containers
docker compose up -d

# View container resource usage
docker stats --no-stream
```

### File Operations

```bash
# View file in container
docker exec postal-web cat /opt/postal/app/config/routes.rb

# Copy file from container to server
docker cp postal-web:/opt/postal/app/config/routes.rb /tmp/routes.rb

# Copy file from server to container
docker cp /tmp/routes.rb postal-web:/opt/postal/app/config/routes.rb

# Check Ruby syntax in container
docker exec postal-web ruby -c /opt/postal/app/app/controllers/legacy_api/domains_controller.rb
```

### Debugging

```bash
# Access Rails console (advanced)
docker exec -it postal-web bundle exec rails console

# View environment variables
docker exec postal-web env | grep POSTAL

# Check Postal version
docker exec postal-web cat /opt/postal/app/VERSION
```

## Deploy Checklist

Before deployment:
- [ ] Code changes committed to Git
- [ ] Code pushed to GitHub
- [ ] Syntax checked (`ruby -c`)

During deployment:
- [ ] Files copied to server /tmp
- [ ] Files copied to postal-web container
- [ ] Files copied to postal-worker container
- [ ] Containers restarted
- [ ] Temp files cleaned up

After deployment:
- [ ] Containers are running (`docker ps`)
- [ ] No errors in logs
- [ ] API endpoint tested
- [ ] Documentation updated if needed

## Need Help?

### Check Logs First

```bash
# Recent logs
ssh root@65.108.218.32 "docker logs --tail 50 postal-web"

# Follow logs in real-time
ssh root@65.108.218.32 "docker logs -f postal-web"

# Filter for errors
ssh root@65.108.218.32 "docker logs postal-web 2>&1 | grep -i error"
```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `undefined method` | Typo in method name | Check spelling, redeploy |
| `uninitialized constant` | Missing class/module | Check requires, check syntax |
| `No route matches` | Route not defined | Check routes.rb, restart container |
| `Connection refused` | Container not running | `docker ps`, restart container |

---

**Server:** 65.108.218.32
**Postal Port:** 5000
**API Key Location:** Postal web UI → Credentials → API type
**Repository:** https://github.com/weldcorporation/postal
