# Apple-App-Site-Association Configuration

## File Location

This file MUST be placed at:
```
https://yourdomain.com/.well-known/apple-app-site-association
```

**Important**: 
- Replace `yourdomain.com` with your actual domain
- File name has NO extension
- Must be served over HTTPS
- Must be accessible without authentication

---

## Configuration File

### Template (Update TEAMID and domains):

```json
{
  "appclips": {
    "apps": ["TEAMID.com.headydiscy.reczipes.Clip"]
  },
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.headydiscy.reczipes",
        "paths": ["*"]
      },
      {
        "appID": "TEAMID.com.headydiscy.reczipes.Clip",
        "paths": ["/clip/*", "/extract/*"]
      }
    ]
  },
  "webcredentials": {
    "apps": ["TEAMID.com.headydiscy.reczipes"]
  }
}
```

### Find Your Team ID:

1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in
3. Go to **Membership**
4. Your Team ID is displayed (10 alphanumeric characters)
5. Example: `ABC123XYZ9`

### Example with Team ID ABC123XYZ9:

```json
{
  "appclips": {
    "apps": ["ABC123XYZ9.com.headydiscy.reczipes.Clip"]
  },
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ABC123XYZ9.com.headydiscy.reczipes",
        "paths": ["*"]
      },
      {
        "appID": "ABC123XYZ9.com.headydiscy.reczipes.Clip",
        "paths": ["/clip/*", "/extract/*"]
      }
    ]
  },
  "webcredentials": {
    "apps": ["ABC123XYZ9.com.headydiscy.reczipes"]
  }
}
```

---

## Server Configuration

### Apache (.htaccess):

Add this to your `.htaccess` file:

```apache
# Enable App Clips and Universal Links
<Files "apple-app-site-association">
    Header set Content-Type "application/json"
    Header set Access-Control-Allow-Origin "*"
</Files>
```

### Nginx:

Add this to your `nginx.conf`:

```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
}
```

### Node.js/Express:

```javascript
app.get('/.well-known/apple-app-site-association', (req, res) => {
    res.type('application/json');
    res.sendFile(__dirname + '/apple-app-site-association');
});
```

---

## Validation

### Test Your Configuration:

1. **Browser Test**:
   ```
   https://yourdomain.com/.well-known/apple-app-site-association
   ```
   Should return JSON content

2. **Apple's Validator**:
   - Go to: https://search.developer.apple.com/appsearch-validation-tool/
   - Enter your domain
   - Check for errors

3. **Command Line**:
   ```bash
   curl -I https://yourdomain.com/.well-known/apple-app-site-association
   ```
   
   Should return:
   ```
   HTTP/2 200
   content-type: application/json
   ```

### Common Issues:

❌ **404 Not Found**
- File not at correct location
- Check file name (no extension)
- Verify web server configuration

❌ **Redirect Loop**
- Remove redirects to this file
- AASA file must be served directly

❌ **Wrong Content-Type**
- Should be `application/json` or `application/pkcs7-mime`
- Check server configuration

❌ **SSL Certificate Invalid**
- Must use valid HTTPS
- No self-signed certificates in production

---

## URL Patterns Explained

### App Clip Paths:

```json
"paths": ["/clip/*", "/extract/*"]
```

This means App Clip activates for:
- ✅ `https://yourdomain.com/clip/extract`
- ✅ `https://yourdomain.com/clip/extract?url=...`
- ✅ `https://yourdomain.com/extract/recipe`
- ❌ `https://yourdomain.com/other-page`

### Main App Paths:

```json
"paths": ["*"]
```

This means main app handles ALL URLs from your domain.

### More Specific Examples:

```json
{
  "paths": [
    "/clip/*",              // All clip URLs
    "/extract/*",           // All extract URLs
    "/recipe/*/view",       // Specific recipe views
    "NOT /admin/*"          // Exclude admin pages
  ]
}
```

---

## Multiple Domains

If you have multiple domains (e.g., `reczipes.app` and `www.reczipes.app`):

1. Host AASA file on BOTH domains:
   - `https://reczipes.app/.well-known/apple-app-site-association`
   - `https://www.reczipes.app/.well-known/apple-app-site-association`

2. Add both in Xcode Associated Domains:
   ```
   appclips:reczipes.app
   appclips:www.reczipes.app
   ```

---

## Testing Checklist

- [ ] File accessible via HTTPS
- [ ] Returns HTTP 200 status
- [ ] Content-Type is `application/json`
- [ ] No authentication required
- [ ] No redirects
- [ ] Valid JSON syntax
- [ ] Team ID is correct
- [ ] Bundle identifiers match exactly
- [ ] Validates in Apple's tool
- [ ] Cached by Apple's CDN (wait 24 hours after first deploy)

---

## Deployment Steps

1. **Create the file** on your web server:
   ```bash
   mkdir -p .well-known
   nano .well-known/apple-app-site-association
   ```

2. **Paste the JSON** (with your Team ID)

3. **Set permissions**:
   ```bash
   chmod 644 .well-known/apple-app-site-association
   ```

4. **Test locally**:
   ```bash
   curl https://yourdomain.com/.well-known/apple-app-site-association
   ```

5. **Validate with Apple's tool**

6. **Wait for CDN cache** (up to 24 hours)

7. **Test App Clip invocation**

---

## Example URLs for Your App

Based on your Reczipes2 app, here are suggested URL patterns:

### App Clip URLs:
```
https://yourdomain.com/clip/extract
https://yourdomain.com/clip/extract?url=RECIPE_URL
https://yourdomain.com/extract/camera
```

### Universal Links (Main App):
```
https://yourdomain.com/recipe/[RECIPE_ID]
https://yourdomain.com/book/[BOOK_ID]
https://yourdomain.com/shared/recipe
```

### QR Code Example:
Create a QR code pointing to:
```
https://yourdomain.com/clip/extract
```

When scanned with Camera app, this will launch your App Clip!

---

## Monitoring

### Check if Apple has cached your file:

```bash
# Apple's CDN
curl https://app-site-association.cdn-apple.com/a/v1/yourdomain.com
```

If this returns your AASA file, Apple has cached it successfully.

### Update the file:

1. Make changes on your server
2. Clear Apple's cache (can take 24 hours)
3. Or change the URL in App Store Connect to force refresh

---

## Support Resources

- [Apple Associated Domains Guide](https://developer.apple.com/documentation/xcode/supporting-associated-domains)
- [AASA File Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_associated-domains)
- [Validation Tool](https://search.developer.apple.com/appsearch-validation-tool/)

---

**Need a domain?** If you don't have a domain yet, you can:
1. Purchase one from a registrar (Namecheap, GoDaddy, etc.)
2. Use a free subdomain service during development
3. Deploy a simple static site on Netlify, Vercel, or GitHub Pages

**Pro tip**: You can test locally using `localhost` or `ngrok` during development, but production requires a real domain with HTTPS.
