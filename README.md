# Backend Engineering Take-Home Assignment: Dynamic Pricing Proxy By Julando omar

## Development Environment Setup

The project scaffold is a minimal Ruby on Rails application with a `/api/v1/pricing` endpoint. While you're free to configure your environment as you wish, this repository is pre-configured for a Docker-based workflow that supports live reloading for your convenience.

The provided `Dockerfile` builds a container with all necessary dependencies. Your local code is mounted directly into the container, so any changes you make on your machine will be reflected immediately. Your application will need to communicate with the external pricing model, which also runs in its own Docker container.

### Quick Start Guide

Here is a list of common commands for building, running, and interacting with the Dockerized environment.

```bash

# --- 1. Build & Run The Main Application ---
# Build and run the Docker compose
docker compose up -d --build

# --- 2. Test The Endpoint ---
# Send a sample request to your running service
curl 'http://localhost:3000/api/v1/pricing?period=Summer&hotel=FloatingPointResort&room=SingletonRoom'

# --- 3. Run Tests ---
# Run the full test suite
docker compose exec interview-dev ./bin/rails test

# Run a specific test file
docker compose exec interview-dev ./bin/rails test test/controllers/pricing_controller_test.rb

# Run a specific test by name
docker compose exec interview-dev ./bin/rails test test/controllers/pricing_controller_test.rb -n test_should_get_pricing_with_all_parameters
```



## Solution description

In this solution, i used the caching strategy to reduce the number of API sent to the `rate-api`. The cache is implemented using a Redis. The caching is done using on a background job, which is implemented using the sidekiq job. the background job will run at boot, then will run periodically every 5 minutes. The sidekiq job will fetch the rates for all the hotels and rooms and store them in the cache. The cache will be used to serve the requests to the `api/v1/pricing` endpoint. The solutions also feature an admin endpoint to reset the cache and the sidekiq jobs, so if something or an update to the rate-api happens, then the admin could cleared the cache.

## Why using caching

Cache is used because we need to reduce the amount of API calls to the `rate-api` from 10000 request per day to under 1000 request per day. if we use the cache, the request will be around ~288 request per day to the api. 288 request is recieved by multiplying the 60 minutes / 5 minutes = 12 and then we multiply it by 24 hours = 288. 

Caching is also used because of the constraints of the 36 request combinations of the `rate-api`. the 36 request combinations are pretty small to be stored in the redis, so it could be stored and then be updated easily. 

Why we don't cache per request - caching the result after the request is sent to the api. in this case, the constraints are only 36 combinations, so it would be cheaper and efficient to store the whole combination in cache, then caching the request response everytime the user hit the endpoint. the cache per request would be a better solution if the constrains if the combinations are more (>=10k combinations)

The system also return errors instead of stale cache for the pricing system if the rate-api is down or return errors, because i believe the hotel pricing system and pricing is sensitive to customers, so by showing the error instead of previous price, it reduce the confusion between the company and customer.

## Comparison between other solutions
Some solutions are considered:
- Caching per request: this solution is not recommended because it would be expensive and inefficient to store the whole combination in cache, then caching the request response everytime the user hit the endpoint. the cache per request would be a better solution if the constrains if the combinations are more (>=10k combinations)

- Caching with stale cache: this solution is not recommended because the stale pricing system could be a problem for the company and customer, so by showing the error instead of previous price, it reduce the confusion between the company and customer.

- In system memory: this solution is not recommended because the data will be reset on server restart, and it would be more difficult to implement and maintain.

- RDBMS: this solution is not recommended because we don't need the relational database, and RDBMS is more suitable to store more complex data and unchangeable data, in this case the data is will be replaced after 5 minutes, so it's better to use redis in this case.

## Flow Diagrams
Caching Warming Strategy
![Caching Warming Strategy](./img/Caching%20Strategy.png)

User Request Flow
![User Request Flow](./img/User%20Request%20Flow.png)

Admin Reset Flow
![Admin Reset Flow](./img/Admin%20Reset%20Flow.png)

## Routes

The application has two routes:
- `GET /api/v1/pricing`: Get the rate for the hotel, use URL Params with these attributes:
  - `period`: Summer, Autumn, Winter, Spring
  - `hotel`: FloatingPointResort, GitawayHotel, RecursionRetreat
  - `room`: SingletonRoom, BooleanTwin, RestfulKing
- `POST /admin/rate_cache/refresh`: Refresh the rate cache. Use the admin Token `e2c7c1df165336a21e04cd917875f0f` To Authenticate.

## Repository Architecture
- `Controllers`
  - `Api::V1::PricingController`: Handles the main API function from customers (`GET /api/v1/pricing`). Interfacing between the user and the `RateCacheService` service
  - `Admin::RateCacheController`: Handle the admin endpint (`POST /admin/rate_cache/refresh`). Interfacing between the admin and the `RateCacheService` service

- `Services`
  - `Api::V1::PricingService`: Handles the pricing service. Calling the `get_rate` method from the `RateCacheService` service.
  - `RateCacheService`: Handles the rate cache service. Interfacing between the `RateCacheWorker` worker and the `RateApiClient` client. Consist of the `set_rate` and `get_rate` methods.
    - `set_rate`: set the rate in the cache
    - `get_rate`: get the rate from the cache

- `Workers`
  - `RateCacheWorker`: Handles the rate cache worker. Main job to call the `RateCacheService` method and save to the redis.

- `Clients`
  - `RateApiClient`: Handles the rate api client.

## Resilience & Error Handling

To ensure high availability and stability, the system incorporates comprehensive error handling mechanisms:
- **Graceful Degradation**: If the `rate-api` is down or returns errors during the periodic background sync, the system logs the error and gracefully halts that specific job run. Sidekiq's retry functionality would attempt to recover. Meanwhile, the `PricingController` will continue serving the stale/last-known prices from Redis until they expire or are successfully refreshed.
- **API Fault Tolerance**: If the `PricingController` encounters an internal failure (e.g. Redis becomes unreachable), the overarching controller rescue blocks intercept the `StandardError` and gracefully respond with a `400 Bad Request` or `500 Internal Server Error` containing an `INTERNAL_ERROR` payload. This prevents raw stack traces from bleeding to the end-users.

## Testing Strategy

The solution relies on a test-driven approach to ensure correct functionality:
- **Service Tests (`RateCacheServiceTest`)**: Verify that caching writes all expected elements to Redis and correctly identifies internal failures or missing combinations without breaking.
- **Controller Tests (`PricingControllerTest`)**: Test bounds, parameter validation, edge-cases, and confirm the exact error structures are returned upon missing entries (`RATE_NOT_FOUND`) or deep system issues (`INTERNAL_ERROR`).
- **Worker/Client Tests (`RateCacheWorkerTest`, `RateApiClientTest`)**: Ensure that the Sidekiq tasks schedule accurately and API clients form proper HTTP requests and handle downtime effectively.

## Test Coverage
Testing is framework is using the built in Test in Rails. `SimpleCov` is used to measure the test coverage.

Test Coverage is ~90%, with the remaining coverage are the files that are not used in the solution (bootstraped files).

Test coverage could be seen by running the 
```
./bin/rails test
```

then open the `coverage/index.html` file in the browser.

![Test Coverage](./img/Test%20Coverage.png)

## Future Improvements

For future improvements, there would be some improvement to be make:
- If the rate-api become increasingly large, we could call the `rate-api` with batch of requests. This way we could reduce the amount of request to the api and also reduce the amount of results returned from the `rate-api`. We could also change it to per-request caching if the `rate-api` becoming increasingly large.

- We could also add tracing using some third party service, like datadog, to know which part of the system is taking the most time to process.

- we also could intergrate with the user service, so we could replace the hardcoded user token used by `rate-api` and replace the hardcoded admin token that used in the system with a more robust system.

- We could also add rate-limit to limit the user request, so the user didn't spam both the server and the redis.

## LLM usage
The LLM is used to generate some of the tests, and also to help refactor and improve the code to be more readable. LLM is also used for dry run, to check if there's a bug exists or not. The LLM also used to fix the wording on some part of the Readme.MD file

Tools used are gemini and AntiGravity.


