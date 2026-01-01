provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "site_dns" {
  for_each = var.site_configs

  zone_id = local.zone_ids[each.key]
  name    = each.value.domain_name
  type    = "A"
  content = "192.0.2.1"  # Dummy IP - Cloudflare will proxy through Workers
  proxied = true
}

# Extract zone from API domain (e.g., demo-api.sb-demokit.com -> sb-demokit.com)
locals {
  api_zone = var.api_domain != "" ? join(".", slice(split(".", var.api_domain), 1, length(split(".", var.api_domain)))) : ""
}

# API domain DNS record (if configured)
resource "cloudflare_record" "api_dns" {
  count = var.api_domain != "" && local.api_zone != "" ? 1 : 0

  zone_id = try(
    var.create_zones ? cloudflare_zone.zone[local.api_zone].id : data.cloudflare_zone.zone[local.api_zone].id,
    local.zone_ids[keys(var.site_configs)[0]]  # Fallback to first site's zone
  )
  name    = split(".", var.api_domain)[0]  # Extract subdomain (e.g., "demo-api")
  type    = var.api_backend_ip != "" ? "A" : "CNAME"
  content = var.api_backend_ip != "" ? var.api_backend_ip : "@"  # Use root domain if CNAME
  proxied = true  # Proxy through Cloudflare for DDoS protection
}

# Create Cloudflare zones if they don't exist, or use existing ones
# First, try to get unique DNS zones from site_configs
locals {
  # Get unique DNS zones (multiple sites can share the same zone)
  unique_zones = toset([for site in var.site_configs : site.dns_zone])
}

# Create zones if they don't exist (optional - set create_zones = true to enable)
resource "cloudflare_zone" "zone" {
  for_each = var.create_zones ? local.unique_zones : toset([])
  
  account_id = var.cloudflare_account_id
  zone       = each.value
  plan       = var.cloudflare_zone_plan # e.g., "free", "pro", "business", "enterprise"
  
  # Optional: Set jump_start to automatically scan DNS records
  jump_start = var.cloudflare_jump_start
}

# Data source to reference existing zones (only used when create_zones = false)
# Note: This will fail if zones don't exist and create_zones = false
# In that case, either set create_zones = true or add zones to Cloudflare manually first
data "cloudflare_zone" "zone" {
  for_each = var.create_zones ? toset([]) : local.unique_zones
  name     = each.value
}

# Local to get zone IDs - prefer created zones, fallback to data source
# This allows us to use either created zones or existing zones seamlessly
locals {
  zone_ids = {
    for site_key, site_config in var.site_configs :
    site_key => (
      var.create_zones && contains(local.unique_zones, site_config.dns_zone) ?
      cloudflare_zone.zone[site_config.dns_zone].id :
      data.cloudflare_zone.zone[site_config.dns_zone].id
    )
  }
}

resource "cloudflare_workers_script" "spaces_router" {
  count = var.enable_workers ? 1 : 0
  
  account_id = var.cloudflare_account_id
  name       = "spaces-multi-site-router"

  content = <<-EOT
    // Route map injected from Terraform
    const ROUTE_MAP = ${jsonencode({
      for k, v in var.site_configs :
      v.domain_name => {
        spaces_path = "${var.domain_prefix}${replace(k, "_", "-")}"
        base_url = var.spaces_base_url
      }
    })};
    
    const API_DOMAIN = ${var.api_domain != "" ? "\"${var.api_domain}\"" : "null"};

    addEventListener('fetch', event => {
      event.respondWith(handleRequest(event.request));
    });

    async function handleRequest(request) {
      const url = new URL(request.url);
      const host = url.hostname;
      const path = url.pathname;
      
      // Check if this is an API request
      if (API_DOMAIN && path.startsWith('/api')) {
        // Proxy API requests to demo-api.sb-demokit.com
        const apiUrl = new URL(path + url.search, `https://${"$"}{API_DOMAIN}`);
        
        // Forward Cloudflare geolocation headers to backend
        // Cloudflare automatically adds these headers:
        // - CF-IPCountry: ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "SG")
        // - CF-IPCity: City name
        // - CF-IPContinent: Continent code (e.g., "NA", "EU", "AS")
        // - CF-IPLatitude: Latitude
        // - CF-IPLongitude: Longitude
        const apiHeaders = new Headers();
        
        // Copy original headers
        request.headers.forEach((value, key) => {
          apiHeaders.set(key, value);
        });
        
        // Forward Cloudflare geolocation headers (if present)
        const country = request.headers.get('CF-IPCountry');
        const city = request.headers.get('CF-IPCity');
        const continent = request.headers.get('CF-IPContinent');
        const latitude = request.headers.get('CF-IPLatitude');
        const longitude = request.headers.get('CF-IPLongitude');
        
        if (country) apiHeaders.set('CF-IPCountry', country);
        if (city) apiHeaders.set('CF-IPCity', city);
        if (continent) apiHeaders.set('CF-IPContinent', continent);
        if (latitude) apiHeaders.set('CF-IPLatitude', latitude);
        if (longitude) apiHeaders.set('CF-IPLongitude', longitude);
        
        // Also forward the original IP address
        const clientIP = request.headers.get('CF-Connecting-IP') || request.headers.get('X-Forwarded-For');
        if (clientIP) apiHeaders.set('X-Client-IP', clientIP);
        
        // Forward the request to the API domain
        const apiRequest = new Request(apiUrl, {
          method: request.method,
          headers: apiHeaders,
          body: request.body
        });
        
        const apiResponse = await fetch(apiRequest);
        
        // Create new response with cache control headers to prevent caching
        const responseHeaders = new Headers(apiResponse.headers);
        responseHeaders.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0');
        responseHeaders.set('Pragma', 'no-cache');
        responseHeaders.set('Expires', '0');
        
        return new Response(apiResponse.body, {
          status: apiResponse.status,
          statusText: apiResponse.statusText,
          headers: responseHeaders
        });
      }
      
      // Handle static site requests
      const cfg = ROUTE_MAP[host];
      if (!cfg) {
        return new Response("Unknown site: " + host, { status: 404 });
      }

      // Rewrite path: /something → /spaces_path/something
      // e.g., /index.html → /dev-mobile-sb-demokit-com/index.html
      const filePath = path === "/" ? "/index.html" : path;
      const target = `${"$"}{cfg.base_url}/${"$"}{cfg.spaces_path}${"$"}{filePath}`;

      // Fetch from Spaces
      const response = await fetch(target, {
        method: request.method,
        headers: {
          // Remove Cloudflare-specific headers that might cause issues
          'Accept': request.headers.get('Accept') || '*/*',
        }
      });

      // Create a new response with correct content-type
      const contentType = getContentType(filePath);
      const newHeaders = new Headers(response.headers);
      newHeaders.set('Content-Type', contentType);
      
      // Copy other important headers
      if (response.headers.get('Cache-Control')) {
        newHeaders.set('Cache-Control', response.headers.get('Cache-Control'));
      }
      if (response.headers.get('ETag')) {
        newHeaders.set('ETag', response.headers.get('ETag'));
      }

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: newHeaders
      });
    }

    function getContentType(path) {
      const ext = path.split('.').pop().toLowerCase();
      const types = {
        'html': 'text/html; charset=utf-8',
        'css': 'text/css; charset=utf-8',
        'js': 'application/javascript; charset=utf-8',
        'json': 'application/json; charset=utf-8',
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'gif': 'image/gif',
        'svg': 'image/svg+xml',
        'ico': 'image/x-icon',
        'woff': 'font/woff',
        'woff2': 'font/woff2',
        'ttf': 'font/ttf',
        'eot': 'application/vnd.ms-fontobject',
        'otf': 'font/otf',
        'pdf': 'application/pdf',
        'zip': 'application/zip',
        'xml': 'application/xml',
        'txt': 'text/plain; charset=utf-8'
      };
      return types[ext] || 'application/octet-stream';
    }
  EOT
}


locals {
  # Calculate site hashes only if build directories exist
  # This allows terraform to work even if builds haven't been created yet
  site_hashes = {
    for site, cfg in var.site_configs :
    site => fileexists("${path.module}/${cfg.local_build_dir}") ? filesha256("${path.module}/${cfg.local_build_dir}") : "build-not-found-${site}"
  }
}   

# Note: Cloudflare API token permission groups are not a Terraform resource
# Cache purging is handled via the null_resource below using the API directly

resource "null_resource" "purge_cache" {
  # Only create purge resources for sites that have build directories
  for_each = {
    for site, cfg in var.site_configs :
    site => cfg
    if fileexists("${path.module}/${cfg.local_build_dir}")
  }

  triggers = {
    site_hash = local.site_hashes[each.key]
  }

  provisioner "local-exec" {
    command = <<EOF
curl -X POST "https://api.cloudflare.com/client/v4/zones/${local.zone_ids[each.key]}/purge_cache" \
  -H "Authorization: Bearer ${var.cloudflare_api_token}" \
  -H "Content-Type: application/json" \
  --data '{
    "files": [
      {
        "url": "https://${each.value.domain_name}/*"
      }
    ]
  }'
EOF
  }
}

# Combined cache ruleset - Cloudflare only allows ONE ruleset per phase per zone
# Since multiple sites can share the same zone, we create one ruleset per unique zone
# and include rules for all domains in that zone
locals {
  # Group sites by their DNS zone
  sites_by_zone = {
    for zone in local.unique_zones :
    zone => [
      for k, v in var.site_configs :
      v if v.dns_zone == zone
    ]
  }
}

resource "cloudflare_ruleset" "cache_settings" {
  for_each = var.enable_rulesets ? local.unique_zones : toset([])

  zone_id = var.create_zones ? cloudflare_zone.zone[each.key].id : data.cloudflare_zone.zone[each.key].id
  name    = "Cache settings - ${each.key}"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  # Note: API cache bypass rules removed - API requests are now handled by Worker
  # and routed to demo-api.sb-demokit.com, so they don't need cache rules here

  dynamic "rules" {
    for_each = local.sites_by_zone[each.key]
    content {
      description = "Cache HTML for SPA - ${rules.value.domain_name}"
      action      = "set_cache_settings"
      expression  = "(http.host eq \"${rules.value.domain_name}\" and http.request.uri.path contains \".html\")"
      enabled     = true

      action_parameters {
        cache = true
        edge_ttl {
          mode    = "override_origin"
          default = 300   # 5 minutes
        }
        browser_ttl {
          mode    = "override_origin"
          default = 60    # 1 minute
        }
      }
    }
  }

  dynamic "rules" {
    for_each = local.sites_by_zone[each.key]
    content {
      description = "Static FE caching - ${rules.value.domain_name}"
      action      = "set_cache_settings"
      expression  = "(http.host eq \"${rules.value.domain_name}\")"
      enabled     = true

      action_parameters {
        cache = true
        edge_ttl {
          mode    = "override_origin"
          default = 86400         # 1 day
        }
        browser_ttl {
          mode    = "override_origin"
          default = 3600          # 1 hour
        }
        serve_stale {
          disable_stale_while_updating = false
        }
      }
    }
  }
}


resource "cloudflare_workers_route" "routes" {
  for_each = var.enable_workers ? var.site_configs : {}

  zone_id     = local.zone_ids[each.key]
  script_name = cloudflare_workers_script.spaces_router[0].name
  pattern     = "${each.value.domain_name}/*"
}

