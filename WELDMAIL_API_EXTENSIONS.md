# WeldMail API Extensions for Postal

This fork of Postal adds domain management endpoints to the Legacy API v1, enabling programmatic domain creation and management with DKIM key retrieval.

## New API Endpoints

All endpoints use the same authentication as existing Postal API endpoints:
- Header: `X-Server-API-Key: your-api-key`
- Content-Type: `application/json`

### 1. List Domains

**Endpoint:** `POST /api/v1/domains/list`

**Description:** Returns all domains for the authenticated server.

**Request:**
```json
{}
```

**Response:**
```json
{
  "status": "success",
  "time": 0.123,
  "flags": {},
  "data": {
    "domains": [
      {
        "id": 1,
        "uuid": "abc-123",
        "name": "example.com",
        "verified": true,
        "verified_at": "2025-11-06T12:00:00Z",
        "dns_records": {
          "spf": {
            "type": "TXT",
            "name": "@",
            "value": "v=spf1 a mx include:postal.example.com ~all"
          },
          "dkim": {
            "type": "TXT",
            "name": "postal-ABC123._domainkey",
            "value": "v=DKIM1; t=s; h=sha256; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."
          },
          "dkim_identifier": "postal-ABC123"
        }
      }
    ]
  }
}
```

### 2. Get Domain Info

**Endpoint:** `POST /api/v1/domains/info`

**Description:** Get detailed information about a specific domain including DKIM keys.

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
  "time": 0.123,
  "flags": {},
  "data": {
    "domain": {
      "id": 1,
      "uuid": "abc-123",
      "name": "example.com",
      "verified": true,
      "verified_at": "2025-11-06T12:00:00Z",
      "verification_method": "DNS",
      "verification_token": "abc123def456",
      "dns_checked_at": "2025-11-06T12:30:00Z",
      "spf_status": "OK",
      "dkim_status": "OK",
      "mx_status": "OK",
      "return_path_status": "OK",
      "dns_records": {
        "spf": {
          "type": "TXT",
          "name": "@",
          "value": "v=spf1 a mx include:postal.example.com ~all"
        },
        "dkim": {
          "type": "TXT",
          "name": "postal-ABC123._domainkey",
          "value": "v=DKIM1; t=s; h=sha256; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."
        },
        "dkim_identifier": "postal-ABC123",
        "return_path": {
          "type": "CNAME",
          "name": "psrp.example.com",
          "value": "rp.postal.example.com"
        },
        "verification": {
          "type": "TXT",
          "name": "@",
          "value": "postal-domain-verification=abc123def456"
        }
      },
      "created_at": "2025-11-06T11:00:00Z",
      "updated_at": "2025-11-06T12:00:00Z"
    }
  }
}
```

### 3. Create Domain

**Endpoint:** `POST /api/v1/domains/create`

**Description:** Creates a new domain and automatically generates DKIM keys.

**Request:**
```json
{
  "name": "newdomain.com",
  "verification_method": "DNS"
}
```

**Parameters:**
- `name` (required): Domain name to create
- `verification_method` (optional): Either "DNS" or "Email". Defaults to "DNS"

**Success Response:**
```json
{
  "status": "success",
  "time": 0.123,
  "flags": {},
  "data": {
    "domain": {
      "id": 2,
      "uuid": "xyz-789",
      "name": "newdomain.com",
      "verified": false,
      "verification_method": "DNS",
      "dns_records": {
        "spf": {
          "type": "TXT",
          "name": "@",
          "value": "v=spf1 a mx include:postal.example.com ~all"
        },
        "dkim": {
          "type": "TXT",
          "name": "postal-XYZ789._domainkey",
          "value": "v=DKIM1; t=s; h=sha256; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQD..."
        },
        "dkim_identifier": "postal-XYZ789"
      }
    }
  }
}
```

**Error Response (Domain Already Exists):**
```json
{
  "status": "error",
  "time": 0.123,
  "flags": {},
  "data": {
    "code": "DomainAlreadyExists",
    "message": "Domain 'newdomain.com' already exists",
    "domain": { ... }
  }
}
```

### 4. Verify Domain Ownership

**Endpoint:** `POST /api/v1/domains/verify`

**Description:** Verifies domain ownership by checking the DNS TXT record.

**Request:**
```json
{
  "name": "example.com"
}
```

**Success Response:**
```json
{
  "status": "success",
  "time": 0.123,
  "flags": {},
  "data": {
    "message": "Domain verified successfully",
    "domain": {
      "id": 1,
      "uuid": "abc-123",
      "name": "example.com",
      "verified": true,
      "verified_at": "2025-11-06T17:50:00Z",
      ...
    }
  }
}
```

**Error Response (Verification Failed):**
```json
{
  "status": "error",
  "time": 0.123,
  "flags": {},
  "data": {
    "code": "VerificationFailed",
    "message": "Domain verification failed. Please ensure the DNS TXT record is set correctly.",
    "expected_record": "postal-domain-verification=abc123def456",
    "domain": { ... }
  }
}
```

### 5. Check DNS Records

**Endpoint:** `POST /api/v1/domains/check_dns`

**Description:** Checks all DNS records (SPF, DKIM, MX, Return Path) and returns their status.

**Request:**
```json
{
  "name": "example.com"
}
```

**Success Response:**
```json
{
  "status": "success",
  "time": 0.123,
  "flags": {},
  "data": {
    "message": "DNS records checked",
    "dns_status": {
      "spf": {
        "status": "OK",
        "error": null
      },
      "dkim": {
        "status": "OK",
        "error": null
      },
      "mx": {
        "status": "OK",
        "error": null
      },
      "return_path": {
        "status": "OK",
        "error": null
      }
    },
    "domain": {
      "id": 1,
      "uuid": "abc-123",
      "name": "example.com",
      "verified": true,
      "spf_status": "OK",
      "dkim_status": "OK",
      "mx_status": "OK",
      "return_path_status": "OK",
      ...
    }
  }
}
```

**DNS Status Values:**
- `OK` - Record is configured correctly
- `Missing` - Record not found
- `Invalid` - Record exists but has incorrect value
- `null` - Not yet checked

### 6. Delete Domain

**Endpoint:** `POST /api/v1/domains/delete`

**Description:** Deletes a domain from the mail server.

**Request:**
```json
{
  "name": "example.com"
}
```

**Success Response:**
```json
{
  "status": "success",
  "time": 0.123,
  "flags": {},
  "data": {
    "message": "Domain deleted successfully"
  }
}
```

**Error Response (Not Found):**
```json
{
  "status": "error",
  "time": 0.123,
  "flags": {},
  "data": {
    "code": "DomainNotFound",
    "message": "Domain 'example.com' not found"
  }
}
```

## Integration with WeldMail

These endpoints are used by the WeldMail API to automatically:

1. Create domains when users add them via `/api/domains`
2. Retrieve DKIM public keys and selectors automatically
3. Provide complete DNS records for domain verification

## Installation

This is a fork of the official Postal repository with added domain management endpoints.

### Deploying to Hetzner Server

1. SSH into your server:
   ```bash
   ssh root@65.108.218.32
   ```

2. Navigate to your Postal installation directory

3. Pull the changes from this repository

4. Restart Postal:
   ```bash
   postal restart
   ```

## API Authentication

Get your API key from the Postal web interface:
1. Go to http://65.108.218.32:5000 (or https://postal.weldmail.com once DNS propagates)
2. Navigate to your mail server
3. Go to Credentials
4. Create a new credential with type "API"
5. Copy the key and use it as `X-Server-API-Key` header

## Changes from Original Postal

- Added `app/controllers/legacy_api/domains_controller.rb`
- Updated `config/routes.rb` with new domain management routes
- All changes are backward compatible with existing Postal functionality

## License

Same as original Postal project (MIT License)
