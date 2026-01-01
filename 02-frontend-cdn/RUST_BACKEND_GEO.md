# Getting Country Information in Rust Backend

When requests come through Cloudflare Workers, Cloudflare automatically adds geolocation headers that are forwarded to your Rust backend.

## Headers Available

The Worker forwards these Cloudflare headers to your backend:

- **`CF-IPCountry`**: ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "SG", "AU")
- **`CF-IPCity`**: City name (e.g., "Singapore", "New York")
- **`CF-IPContinent`**: Continent code (e.g., "NA", "EU", "AS", "OC")
- **`CF-IPLatitude`**: Latitude coordinate
- **`CF-IPLongitude`**: Longitude coordinate
- **`X-Client-IP`**: Original client IP address

## Rust Example

Here's how to read the country in your Rust backend:

### Using Actix Web

```rust
use actix_web::{web, HttpRequest, HttpResponse};

async fn api_handler(req: HttpRequest) -> HttpResponse {
    // Get country code
    let country = req.headers()
        .get("CF-IPCountry")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("UNKNOWN");
    
    // Get city (optional)
    let city = req.headers()
        .get("CF-IPCity")
        .and_then(|h| h.to_str().ok());
    
    // Get continent (optional)
    let continent = req.headers()
        .get("CF-IPContinent")
        .and_then(|h| h.to_str().ok());
    
    // Get client IP
    let client_ip = req.headers()
        .get("X-Client-IP")
        .and_then(|h| h.to_str().ok());
    
    println!("Request from country: {}, city: {:?}, IP: {:?}", 
             country, city, client_ip);
    
    // Your API logic here
    HttpResponse::Ok().json(json!({
        "country": country,
        "city": city,
        "continent": continent,
        "client_ip": client_ip
    }))
}
```

### Using Axum

```rust
use axum::{extract::Request, http::HeaderMap};

async fn api_handler(headers: HeaderMap) -> impl IntoResponse {
    let country = headers
        .get("CF-IPCountry")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("UNKNOWN");
    
    let city = headers
        .get("CF-IPCity")
        .and_then(|h| h.to_str().ok());
    
    // Your API logic here
    Json(json!({
        "country": country,
        "city": city
    }))
}
```

### Using Warp

```rust
use warp::Filter;

let country = warp::header::optional::<String>("CF-IPCountry");

let api = warp::path("api")
    .and(country)
    .map(|country: Option<String>| {
        let country_code = country.unwrap_or_else(|| "UNKNOWN".to_string());
        format!("Country: {}", country_code)
    });
```

## Country Codes

The `CF-IPCountry` header uses ISO 3166-1 alpha-2 codes:
- `US` - United States
- `GB` - United Kingdom
- `SG` - Singapore
- `AU` - Australia
- `IN` - India
- `CN` - China
- etc.

Special values:
- `XX` - Unknown country
- `T1` - Tor network

## Testing

You can test the country detection by:
1. Using a VPN to change your location
2. Checking the `CF-IPCountry` header in your backend logs
3. Using Cloudflare's geolocation test tools

## Notes

- These headers are automatically added by Cloudflare
- The country is determined by the client's IP address
- The accuracy depends on Cloudflare's geolocation database
- If the country cannot be determined, `CF-IPCountry` will be `XX`
