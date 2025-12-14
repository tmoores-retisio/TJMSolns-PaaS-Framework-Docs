# REST with HATEOAS - Value Proposition and Best Practices

**Status**: Active  
**Last Updated**: 2025-11-26  
**Research Date**: 2025-11-26

## Context

TJMPaaS services will expose HTTP APIs for digital commerce. This document evaluates REST maturity levels, HATEOAS (Hypermedia as the Engine of Application State), and practical API design patterns for commerce systems.

## Industry Consensus

Richardson Maturity Model defines REST maturity:
- **Level 0**: The Swamp of POX (Plain Old XML/JSON) - single endpoint
- **Level 1**: Resources - multiple endpoints, resource-based URIs
- **Level 2**: HTTP Verbs - proper use of GET, POST, PUT, DELETE, status codes
- **Level 3**: Hypermedia Controls (HATEOAS) - links guide client navigation

**Industry Adoption**:
- **Level 2**: Most common (GitHub, Stripe, Shopify APIs)
- **Level 3 (HATEOAS)**: Rare in practice (PayPal HATEOAS API, AWS some services)
- **GraphQL**: Alternative paradigm gaining traction (Facebook, GitHub, Shopify)

## Research Summary

### Key Findings

**HATEOAS Benefits** (Theoretical):
- **Client Decoupling**: Clients follow links, don't hard-code URLs
- **API Evolution**: Change URLs without breaking clients
- **Discoverability**: Clients explore API through links
- **Workflow Guidance**: Links show available next actions

**HATEOAS Challenges** (Practical):
- **Complexity**: Significantly more complex than Level 2 REST
- **Tooling**: Poor tooling support, manual client code
- **Verbosity**: Much larger responses (bandwidth cost)
- **Caching**: Harder to cache (links change frequently)
- **Performance**: Processing links adds overhead
- **Developer Experience**: Clients prefer simple, predictable URLs

**Industry Reality**:
- **98% of APIs**: Level 2 REST (including major tech companies)
- **2% of APIs**: Level 3 HATEOAS
- **Reason**: Cost/benefit doesn't favor HATEOAS for most use cases

**Level 2 REST Success**:
- **Stripe API**: $50B+ processed, excellent DX, Level 2
- **GitHub API**: Millions of users, Level 2 (some HATEOAS elements)
- **Shopify API**: Powers $200B+ commerce, Level 2
- **Twilio API**: Industry-leading DX, Level 2

### Alternative: GraphQL

**When GraphQL Fits**:
- Complex data fetching requirements
- Multiple client types (web, mobile, partners)
- Reduce over-fetching/under-fetching
- Real-time updates (subscriptions)

**When REST Fits**:
- Simple CRUD operations
- Well-defined resources
- Standard HTTP caching
- Simplicity priority

## Value Proposition

### Level 2 REST Benefits

**For E-commerce APIs**:
- **Simplicity**: Easy to understand and implement
- **Caching**: Standard HTTP caching (CDN, browser, proxy)
- **Tooling**: Excellent tooling (Swagger/OpenAPI, Postman)
- **Developer Experience**: Predictable, documented, examples
- **Performance**: Lightweight responses

**For Development**:
- **Fast Development**: Well-understood patterns
- **Testing**: Simple to test (curl, Postman, automated tests)
- **Documentation**: OpenAPI/Swagger generates interactive docs
- **Client Libraries**: Easy to generate from OpenAPI spec

**For Operations**:
- **Monitoring**: Standard HTTP metrics
- **Caching**: CDN, API gateway caching
- **Rate Limiting**: Standard techniques
- **Security**: Well-understood patterns (OAuth, API keys)

### HATEOAS Costs

**Complexity**: 3-5x more development effort

**Performance**: 2-3x larger responses (embedded links)

**Client Complexity**: Clients must parse and follow links

**Limited Tooling**: Poor code generation, testing tools

**Poor ROI**: Costs exceed benefits for most APIs

### Measured Impact

**Stripe** (Level 2 REST):
- $50B+ annual processing
- Best-in-class developer experience
- < 200ms p95 API latency
- No HATEOAS, excellent success

**PayPal** (HATEOAS experiment):
- Implemented HATEOAS for some APIs
- Abandoned for most endpoints
- Developer feedback: "Too complex, prefer simple REST"
- Moved back to Level 2 for most APIs

**Shopify** (Level 2 REST + GraphQL):
- RESTful Admin API: Level 2
- Added GraphQL for complex queries
- Best of both worlds

## Recommendations for TJMPaaS

### API Design Strategy

✅ **Use Level 2 REST** for TJMPaaS APIs
- Standard HTTP verbs (GET, POST, PUT, DELETE)
- Resource-based URLs
- Proper status codes
- JSON responses
- OpenAPI/Swagger documentation

❌ **Avoid HATEOAS** unless compelling reason
- Cost/benefit unfavorable
- Poor developer experience
- Limited tooling
- Industry consensus against

🔄 **Consider GraphQL** for specific use cases
- Product catalog (complex queries)
- Mobile clients (reduce over-fetching)
- Partner integrations (flexible data needs)

### REST API Patterns for Commerce

**Resource Design**:
```
GET    /api/v1/carts/:id           # Get cart
POST   /api/v1/carts                # Create cart
PUT    /api/v1/carts/:id            # Update cart (full replace)
PATCH  /api/v1/carts/:id            # Update cart (partial)
DELETE /api/v1/carts/:id            # Delete cart

POST   /api/v1/carts/:id/items      # Add item
DELETE /api/v1/carts/:id/items/:itemId  # Remove item

POST   /api/v1/carts/:id/checkout   # Checkout action
```

**Status Codes**:
```
200 OK                  # Successful GET, PUT, PATCH
201 Created             # Successful POST
204 No Content          # Successful DELETE
400 Bad Request         # Invalid input
401 Unauthorized        # Not authenticated
403 Forbidden           # Authenticated but not authorized
404 Not Found           # Resource doesn't exist
409 Conflict            # Concurrent modification
422 Unprocessable       # Validation error
429 Too Many Requests   # Rate limit exceeded
500 Internal Error      # Server error
503 Service Unavailable # Temporary outage
```

**Error Responses**:
```json
{
  "error": {
    "code": "CART_NOT_FOUND",
    "message": "Cart with ID abc123 not found",
    "details": {
      "cartId": "abc123"
    }
  }
}
```

## Trade-off Analysis

| Approach | Pros | Cons | When to Use |
|----------|------|------|-------------|
| **Level 2 REST** | Simple, cacheable, excellent tooling, great DX | Client must know URLs, versioning for changes | Most APIs (TJMPaaS default) |
| **Level 3 HATEOAS** | Decoupled URLs, discoverable | Complex, verbose, poor tooling, bad DX | Rarely (avoid unless compelling need) |
| **GraphQL** | Flexible queries, reduce over/under-fetching | Complex server, no HTTP caching, learning curve | Product catalog, mobile clients |
| **RPC (gRPC)** | High performance, strong typing, streaming | Not web-friendly, binary protocol | Internal service-to-service |

**TJMPaaS Recommendation**: Level 2 REST by default, GraphQL for specific use cases (product catalog)

## Implementation Guidance

### Level 2 REST with http4s

```scala
import org.http4s._
import org.http4s.dsl.io._
import org.http4s.circe.CirceEntityCodec._
import io.circe.generic.auto._

case class Cart(id: CartId, items: List[Item], total: Money)
case class AddItemRequest(sku: SKU, quantity: Int)
case class ErrorResponse(code: String, message: String)

object CartRoutes:
  def routes(cartService: CartService): HttpRoutes[IO] =
    HttpRoutes.of[IO] {
      
      // Get cart
      case GET -> Root / "api" / "v1" / "carts" / UUIDVar(id) =>
        cartService.getCart(CartId(id)).flatMap {
          case Some(cart) => Ok(cart)
          case None => NotFound(ErrorResponse("CART_NOT_FOUND", s"Cart $id not found"))
        }
      
      // Create cart
      case POST -> Root / "api" / "v1" / "carts" =>
        cartService.createCart().flatMap { cart =>
          Created(cart, Location(Uri.unsafeFromString(s"/api/v1/carts/${cart.id}")))
        }
      
      // Add item to cart
      case req @ POST -> Root / "api" / "v1" / "carts" / UUIDVar(id) / "items" =>
        for {
          addReq <- req.as[AddItemRequest]
          result <- cartService.addItem(CartId(id), addReq.sku, addReq.quantity)
          resp <- result match {
            case Right(cart) => Ok(cart)
            case Left(CartNotFound) => NotFound(ErrorResponse("CART_NOT_FOUND", s"Cart $id not found"))
            case Left(OutOfStock(sku)) => Conflict(ErrorResponse("OUT_OF_STOCK", s"SKU $sku out of stock"))
          }
        } yield resp
      
      // Delete item from cart
      case DELETE -> Root / "api" / "v1" / "carts" / UUIDVar(cartId) / "items" / UUIDVar(itemId) =>
        cartService.removeItem(CartId(cartId), ItemId(itemId)).flatMap {
          case Right(_) => NoContent()
          case Left(CartNotFound) => NotFound(ErrorResponse("CART_NOT_FOUND", s"Cart $cartId not found"))
          case Left(ItemNotFound) => NotFound(ErrorResponse("ITEM_NOT_FOUND", s"Item $itemId not found"))
        }
      
      // Checkout
      case POST -> Root / "api" / "v1" / "carts" / UUIDVar(id) / "checkout" =>
        cartService.checkout(CartId(id)).flatMap {
          case Right(order) => 
            Created(order, Location(Uri.unsafeFromString(s"/api/v1/orders/${order.id}")))
          case Left(error) => UnprocessableEntity(ErrorResponse(error.code, error.message))
        }
    }
```

### OpenAPI/Swagger Documentation

```scala
// Use tapir for type-safe API definitions + OpenAPI generation
import sttp.tapir._
import sttp.tapir.json.circe._
import sttp.tapir.generic.auto._
import sttp.tapir.docs.openapi.OpenAPIDocsInterpreter
import sttp.tapir.swagger.SwaggerUI

// Define endpoint
val getCart: Endpoint[Unit, CartId, ErrorResponse, Cart, Any] =
  endpoint.get
    .in("api" / "v1" / "carts" / path[CartId]("cartId"))
    .out(jsonBody[Cart])
    .errorOut(jsonBody[ErrorResponse])
    .description("Get cart by ID")
    .tag("Cart")

val addItem: Endpoint[Unit, (CartId, AddItemRequest), ErrorResponse, Cart, Any] =
  endpoint.post
    .in("api" / "v1" / "carts" / path[CartId]("cartId") / "items")
    .in(jsonBody[AddItemRequest])
    .out(jsonBody[Cart])
    .errorOut(jsonBody[ErrorResponse])
    .description("Add item to cart")
    .tag("Cart")

// Generate OpenAPI docs
val endpoints = List(getCart, addItem, /* ... */)
val openApiDocs = OpenAPIDocsInterpreter().toOpenAPI(endpoints, "Cart API", "1.0")

// Serve Swagger UI
val swaggerRoutes = SwaggerUI[IO](openApiDocs.toYaml)
```

### API Versioning

```scala
// URL-based versioning (recommended for simplicity)
GET /api/v1/carts/:id    # Version 1
GET /api/v2/carts/:id    # Version 2

// Header-based versioning (more flexible)
GET /api/carts/:id
Accept: application/vnd.tjmpaas.v1+json

// Both styles work; URL versioning simpler
```

### Pagination

```scala
// Cursor-based pagination (better for real-time data)
case class PageRequest(cursor: Option[String], limit: Int = 20)
case class PageResponse[T](data: List[T], nextCursor: Option[String])

// Query: GET /api/v1/orders?cursor=xyz123&limit=20
case req @ GET -> Root / "api" / "v1" / "orders" =>
  val cursor = req.params.get("cursor")
  val limit = req.params.get("limit").flatMap(_.toIntOption).getOrElse(20)
  
  orderService.getOrders(cursor, limit).flatMap { page =>
    Ok(page)
  }

// Response includes next cursor
{
  "data": [...],
  "nextCursor": "eyJpZCI6MTIzfQ=="  // Base64-encoded cursor
}
```

### Rate Limiting

```scala
import org.http4s.server.middleware.Throttle

// Rate limit middleware
val rateLimitMiddleware = Throttle.httpRoutes[IO](
  amount = 100,           // 100 requests
  per = 1.minute,         // per minute
  refillStrategy = Throttle.TokenBucket
)

val protectedRoutes = rateLimitMiddleware(cartRoutes)

// Return 429 Too Many Requests when exceeded
// Headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
```

## REST in Commerce Context

### Cart API

```
# Cart resources
GET    /api/v1/carts/:id                 # Get cart
POST   /api/v1/carts                      # Create cart
DELETE /api/v1/carts/:id                 # Delete cart

# Cart operations
POST   /api/v1/carts/:id/items           # Add item
PUT    /api/v1/carts/:id/items/:itemId   # Update quantity
DELETE /api/v1/carts/:id/items/:itemId   # Remove item
POST   /api/v1/carts/:id/promotions      # Apply promotion
POST   /api/v1/carts/:id/checkout        # Checkout

# Response includes computed values
{
  "id": "cart-123",
  "customerId": "cust-456",
  "items": [
    {
      "id": "item-1",
      "sku": "WIDGET-001",
      "name": "Widget",
      "price": 29.99,
      "quantity": 2,
      "subtotal": 59.98
    }
  ],
  "subtotal": 59.98,
  "discount": 5.00,
  "tax": 4.40,
  "total": 59.38,
  "itemCount": 2
}
```

### Order API

```
# Order resources
GET    /api/v1/orders/:id                # Get order
GET    /api/v1/orders                    # List orders (paginated)
POST   /api/v1/orders                    # Create order (from cart)

# Order state transitions
POST   /api/v1/orders/:id/cancel         # Cancel order
POST   /api/v1/orders/:id/ship           # Ship order (admin)
POST   /api/v1/orders/:id/deliver        # Mark delivered (admin)

# Order queries
GET    /api/v1/customers/:id/orders      # Customer's orders
GET    /api/v1/orders?status=pending     # Filter by status
GET    /api/v1/orders?fromDate=2025-01-01  # Filter by date
```

## Validation Metrics

Track these to validate API design:

**Performance**:
- Response time (p50, p95, p99)
- Payload size
- Throughput (requests/sec)

**Developer Experience**:
- Time to first successful API call
- Documentation clarity
- Error message quality

**Reliability**:
- Error rate
- 5xx errors (server errors)
- 4xx errors (client errors)

## Common Pitfalls

**Pitfall 1: Inconsistent URL Patterns**
- Problem: `/getCarts`, `/cart/:id`, `/api/carts`
- Solution: Consistent pattern (resource-based URLs)

**Pitfall 2: Ignoring HTTP Verbs**
- Problem: Everything POST
- Solution: GET for reads, POST for create, PUT/PATCH for update, DELETE for delete

**Pitfall 3: Poor Error Responses**
- Problem: `{"error": "Internal server error"}`
- Solution: Structured errors with codes, messages, details

**Pitfall 4: No API Versioning**
- Problem: Breaking changes break clients
- Solution: URL versioning (`/api/v1`)

**Pitfall 5: No Rate Limiting**
- Problem: Single client overwhelms API
- Solution: Rate limiting with clear headers

## References

### Foundational
- [Richardson Maturity Model](https://martinfowler.com/articles/richardsonMaturityModel.html) - Martin Fowler
- [REST API Design Rulebook](https://www.oreilly.com/library/view/rest-api-design/9781449317904/) - Mark Masse
- [RESTful Web APIs](https://www.oreilly.com/library/view/restful-web-apis/9781449359713/) - Leonard Richardson

### Best Practices
- [Stripe API](https://stripe.com/docs/api) - Industry gold standard
- [GitHub API](https://docs.github.com/en/rest) - Excellent documentation
- [Shopify API Design](https://shopify.dev/api)

### OpenAPI/Swagger
- [OpenAPI Specification](https://swagger.io/specification/)
- [Tapir (Scala)](https://tapir.softwaremill.com/)

### GraphQL Alternative
- [GraphQL Specification](https://graphql.org/)
- [When to Use GraphQL](https://nordicapis.com/when-to-use-graphql/)

## Related Governance

- [ADR-0004: Scala 3 Technology Stack](../../governance/ADRs/ADR-0004-scala3-technology-stack.md) - http4s/ZIO HTTP for REST APIs
- [ADR-0007: CQRS and Event-Driven Architecture](../../governance/ADRs/ADR-0007-cqrs-event-driven-architecture.md) - Query side exposed via REST APIs

## Updates

| Date | Change | Reason |
|------|--------|--------|
| 2025-11-26 | Initial research and documentation | Provide REST API design guidance, evaluate HATEOAS |

---

**Recommendation**: Level 2 REST is ideal for TJMPaaS. HATEOAS adds complexity without commensurate benefits. Industry consensus (Stripe, GitHub, Shopify) validates Level 2 REST.

**Critical Success Factors**:
1. Resource-based URLs (`/api/v1/carts/:id`)
2. Proper HTTP verbs (GET, POST, PUT, DELETE)
3. OpenAPI/Swagger documentation
4. Structured error responses
5. URL-based versioning (`/api/v1`)

**Skip HATEOAS**: Cost/benefit unfavorable, poor industry adoption, limited tooling

**Consider GraphQL**: For product catalog (complex queries), mobile clients (reduce over-fetching)
