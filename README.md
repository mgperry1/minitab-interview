```markdown
# Minitab Stats Service Demo

A simple, containerized Python microservice built with FastAPI that calculates the arithmetic mean and population standard deviation for a list of numbers[cite: 1, 3]. It includes dynamic runtime port configuration, version labeling, and automated build/test scripts for local validation[cite: 1, 4, 5].  Service and setup based on requirments doc.

---

## Repository Layout

```text
.
├── app/
│   ├── __init__.py
│   └── main.py             # FastAPI routes, math logic, and HTML landing page
├── tests/
│   ├── __init__.py
│   └── test_main.py        # Pytest unit tests
├── docs/
│   ├── Requiements.pdf
├── Dockerfile              # Container build definition (non-root user, multi-stage friendly)
├── docker-compose.yml      # Compose specification for local dev & testing
├── runit.sh                # Bash : builds image, runs tests & container, tests curls
├── runit.ps1               # PowerShell : builds image, runs tests &container, tests curls
├── requirements.txt        # Python package dependencies
└── README.md

```

---

## Quickstart

### Automated Scripts (Build, Test, and Run)

The helper scripts build the Docker image, run unit tests inside the container, spin up the container, and run live HTTP tests against the exposed endpoints:

* **Bash (Linux / macOS / Git Bash):**
```bash
chmod +x runit.sh
./runit.sh

```



* **PowerShell (Windows):**
```powershell
.\runit.ps1

```

*(If your execution policy blocks scripts, run: `powershell -ExecutionPolicy Bypass -File .\testit.ps1`)*


### Docker Compose

You can also run everything through Docker Compose:

```bash
# Build image and start the container
docker compose up -d --build

# Run pytest inside the running environment
docker compose run --rm stats-service python -m pytest

# Tear it down
docker compose down

```

---

## Configuration Options

Common settings can be customized using environment variables or script arguments:

* `PORT`: Port the service listens on inside the container (defaults to `3000`).
* `HOST_PORT`: Port mapped to your local machine (defaults to `3000`).
* `APP_VERSION`: Version string displayed on `/`, `/healthz`, and Swagger docs (defaults to `1.0.0`).
* `IMAGE_NAME`: Tag name for the Docker image (defaults to `stats-service`).
* `CONTAINER_NAME`: Name for the running container instance (defaults to `stats-service-app`).


**Examples:**

* Bash: `PORT=8080 HOST_PORT=8080 APP_VERSION=1.1.0 ./runit.sh`
* PowerShell: `.\runit.ps1 -Port 8080 -HostPort 8080 -AppVersion "1.1.0"`


---

## Endpoints

* `GET /`: Landing page showing service status, endpoints, and version.
* `GET /healthz`: Health check probe (`{"status": "healthy", "version": "..."}`).
* `GET /docs`: Interactive Swagger UI documentation.
* `POST /mean`: Accepts a JSON array of numbers and returns the mean.
* `POST /stddev`: Accepts a JSON array of numbers and returns the population standard deviation.

### Curl Examples

```bash
# Mean (returns 3)
curl http://localhost:3000/mean -X POST -H "Content-Type: application/json" -d '[1,2,3,4,5]'
# Mean with decimals (returns 3.34)
curl http://localhost:3000/mean -X POST -H "Content-Type: application/json" -d '[1.5,3,1,7,4.2]'
# Population standard deviation (returns 1.414)
curl http://localhost:3000/stddev -X POST -H "Content-Type: application/json" -d '[1,2,3,4,5]'
# Population standard deviation (returns 2.15)
curl http://localhost:3000/stddev -X POST -H "Content-Type: application/json" -d '[1.5,3,1,7,4.2]'

```
(Numeric outputs are rounded to three decimal places with trailing zeroes omitted.)
---
## Where to Add Code & Tests
### Adding New Code
* **New routes or math logic:** Open `app/main.py` and define your new `@app.get` or `@app.post` handlers.

* **Splitting larger modules:** If the app grows, add new Python modules inside `app/` (such as `app/calculations.py` or `app/routers/`) and import them into `app/main.py`.
* **Adding dependencies:** Add new third-party libraries to `requirements.txt`. Core math in this service relies on Python's built-in `statistics` library (`fmean`, `pstdev`) to keep image sizes small without bulky dependencies.

### Adding Tests

* **Unit tests (`pytest`):** Add new test functions to `tests/test_main.py`. You can also create separate test files (e.g., `tests/test_endpoints.py`), as long as the file starts with `test_` so pytest discovers it automatically.

* **Live end-to-end checks:** To test a new endpoint during container startup, append your assertion call to `runit.sh` (`test_curl "/your-endpoint" 'payload' 'expected'`) and `runit.ps1` (`Assert-Endpoint -Endpoint "/your-endpoint" ...`).

```

```