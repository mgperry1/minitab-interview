import os
import statistics
from typing import List, Union
from fastapi import FastAPI, HTTPException, status
from fastapi.responses import HTMLResponse, Response


# Read version from environment variable with fallback default
APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")

app = FastAPI(
    title="Demo Minitab Statistics Calculation Service",
    description="Calculates mean and population standard deviation from arrays of numbers.",
    version=APP_VERSION,
)


def format_numeric_result(value: float) -> str:
    """
    Rounds to 3 decimal places and removes unnecessary trailing zeroes.
    Example: 3.0 -> '3', 3.340 -> '3.34', 1.414 -> '1.414'
    """
    rounded = round(value, 3)
    if rounded.is_integer():
        return str(int(rounded))
    formatted = f"{rounded:.3f}".rstrip("0").rstrip(".")
    return formatted if formatted else "0"


@app.get("/", response_class=HTMLResponse)
def info_page():
    """Service landing and documentation info page."""
    html_content = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Minitab Interview Statistics Service Demo</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #24292e; background-color: #f6f8fa; }
    .card { background: white; border: 1px solid #d0d7de; border-radius: 8px; padding: 24px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
    h1 { color: #0969da; margin-top: 0; }
    h2 { border-bottom: 1px solid #eaecef; padding-bottom: 8px; }
    code, pre { background-color: #f0f3f6; border-radius: 6px; font-family: monospace; }
    code { padding: 2px 6px; font-size: 0.9em; }
    pre { padding: 12px; overflow-x: auto; }
    .badge { display: inline-block; padding: 2px 8px; font-size: 0.8em; font-weight: 600; border-radius: 12px; color: white; }
    .post { background-color: #1f883d; }
    .get { background-color: #0969da; }
    ul { list-style: none; padding-left: 0; }
    li { margin-bottom: 12px; }
    a { color: #0969da; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="card">
    <h1>📊 Minitab Interview Statistics Service</h1>
    <p>Demo a containerized microservice for computing arithmetic mean and population standard deviation.</p>
    <p>Interactive API Explorer: <a href="/docs" target="_blank"><strong>/docs (Swagger UI)</strong></a> <br> Health Probe: <a href="/healthz"><code>/healthz</code></a></p>
  </div>

  <div class="card">
    <h2>Available Endpoints</h2>
    <ul>
      <li>
        <span class="badge post">POST</span> <code>/mean</code> &mdash; Calculates the arithmetic mean of a JSON array of numbers.
      </li>
      <li>
        <span class="badge post">POST</span> <code>/stddev</code> &mdash; Calculates the population standard deviation.
      </li>
      <li>
        <span class="badge get">GET</span> <code>/healthz</code> &mdash; Container readiness and liveness health probe.
      </li>
    </ul>

    <h2>Quick Examples</h2>
    <pre><code># Calculate Mean
curl http://localhost:3000/mean \
  -X POST \
  -H "Content-Type: application/json" \
  -d '[1, 2, 3, 4, 5]'
# Response: 3

# Calculate Population Standard Deviation
curl http://localhost:3000/stddev \
  -X POST \
  -H "Content-Type: application/json" \
  -d '[1.5, 3, 1, 7, 4.2]'
# Response: 2.15</code></pre>
  </div>
</body>
</html>
"""
    return HTMLResponse(content=html_content, status_code=status.HTTP_200_OK)


@app.get("/healthz", status_code=status.HTTP_200_OK)
def health_check():
    """Healthcheck endpoint for orchestrators and container probes."""
    return {"status": "healthy"}


@app.post("/mean", status_code=status.HTTP_200_OK)
def calculate_mean(payload: List[Union[int, float]]):
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payload array cannot be empty.",
        )
    result = statistics.fmean(payload)
    return Response(
        content=format_numeric_result(result),
        media_type="application/json",
    )


@app.post("/stddev", status_code=status.HTTP_200_OK)
def calculate_stddev(payload: List[Union[int, float]]):
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payload array cannot be empty.",
        )
    result = statistics.pstdev(payload)
    return Response(
        content=format_numeric_result(result),
        media_type="application/json",
    )


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", "3000"))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port)