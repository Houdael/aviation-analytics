"""
dlt pipeline for pulling flight arrivals and departures from the OpenSky Network API.
Covers 10 major European airports.
"""

import os
import time
from datetime import date, datetime, timedelta, timezone
from typing import Any, Generator

import dlt
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# ICAO codes for 10 major European airports
EUROPEAN_AIRPORTS = [
    "EGLL",  # London Heathrow
    "LFPG",  # Paris Charles de Gaulle
    "EHAM",  # Amsterdam Schiphol
    "EDDF",  # Frankfurt
    "LEMD",  # Madrid Barajas
    "LIRF",  # Rome Fiumicino
    "LEBL",  # Barcelona El Prat
    "EBBR",  # Brussels
    "LSZH",  # Zurich
    "LPPT",  # Lisbon
]

# Fields returned by the OpenSky /flights/arrival and /flights/departure endpoints
FLIGHT_COLUMNS = [
    "icao24",                              # 24-bit ICAO transponder address (hex)
    "firstSeen",                           # Estimated departure time (Unix timestamp)
    "estDepartureAirport",                 # ICAO code of estimated departure airport
    "lastSeen",                            # Last time aircraft was seen (Unix timestamp)
    "estArrivalAirport",                   # ICAO code of estimated arrival airport
    "callsign",                            # Flight callsign (up to 8 chars)
    "estDepartureAirportHorizDistance",    # Horizontal distance to departure airport (metres)
    "estDepartureAirportVertDistance",     # Vertical distance to departure airport (metres)
    "estArrivalAirportHorizDistance",      # Horizontal distance to arrival airport (metres)
    "estArrivalAirportVertDistance",       # Vertical distance to arrival airport (metres)
    "departureAirportCandidatesCount",     # Number of alternative departure airport candidates
    "arrivalAirportCandidatesCount",       # Number of alternative arrival airport candidates
]

TOKEN_URL = (
    "https://auth.opensky-network.org/auth/realms/opensky-network"
    "/protocol/openid-connect/token"
)


class TokenManager:
    """Fetches and transparently refreshes an OAuth2 client-credentials token."""

    def __init__(self) -> None:
        self._client_id = os.environ["OPENSKY_CLIENT_ID"]
        self._client_secret = os.environ["OPENSKY_CLIENT_SECRET"]
        self._access_token: str | None = None
        self._expires_at: float = 0.0

    def _fetch_token(self) -> None:
        response = requests.post(
            TOKEN_URL,
            data={
                "grant_type": "client_credentials",
                "client_id": self._client_id,
                "client_secret": self._client_secret,
            },
            timeout=10,
        )
        response.raise_for_status()
        payload = response.json()
        self._access_token = payload["access_token"]
        # Refresh 30 s before actual expiry to avoid clock-edge failures
        self._expires_at = time.monotonic() + payload["expires_in"] - 30

    @property
    def token(self) -> str:
        if self._access_token is None or time.monotonic() >= self._expires_at:
            self._fetch_token()
        return self._access_token  # type: ignore[return-value]

    @property
    def auth_headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.token}"}


OPENSKY_API_BASE = "https://opensky-network.org/api"


def _build_session() -> requests.Session:
    """Return a requests Session with retry logic and exponential backoff."""
    session = requests.Session()
    retry = Retry(
        total=3,
        backoff_factor=2,          # waits 2 s, 4 s, 8 s between retries
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET", "POST"],
        raise_on_status=False,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    return session


_SESSION = _build_session()


def fetch_flights(
    airport: str,
    day: date,
    token_manager: TokenManager,
) -> list[dict[str, Any]]:
    """Return arrivals and departures for *airport* on *day*.

    Each record contains the fields from FLIGHT_COLUMNS plus a ``flight_type``
    field set to ``"arrival"`` or ``"departure"``.
    """
    begin = int(datetime(day.year, day.month, day.day, tzinfo=timezone.utc).timestamp())
    end = begin + 86400

    endpoints = [
        ("arrival", f"{OPENSKY_API_BASE}/flights/arrival"),
        ("departure", f"{OPENSKY_API_BASE}/flights/departure"),
    ]

    records: list[dict[str, Any]] = []
    for flight_type, url in endpoints:
        response = _SESSION.get(
            url,
            params={"airport": airport, "begin": begin, "end": end},
            headers=token_manager.auth_headers,
            timeout=60,
        )
        response.raise_for_status()
        for record in response.json() or []:
            records.append({**record, "flight_type": flight_type})

    return records


@dlt.resource(name="flights", write_disposition="append")
def flights_resource(
    day: date,
    token_manager: TokenManager,
) -> Generator[dict[str, Any], None, None]:
    for airport in EUROPEAN_AIRPORTS:
        yield from fetch_flights(airport, day, token_manager)


@dlt.source
def opensky_source(
    day: date,
    token_manager: TokenManager,
) -> dlt.sources.DltSource:
    return flights_resource(day, token_manager)


def run_pipeline() -> None:
    yesterday = datetime.now(timezone.utc).date() - timedelta(days=1)
    token_manager = TokenManager()

    pipeline = dlt.pipeline(
        pipeline_name="opensky",
        destination="snowflake",
        dataset_name="raw",
    )
    load_info = pipeline.run(opensky_source(yesterday, token_manager))
    print(load_info)


if __name__ == "__main__":
    run_pipeline()
