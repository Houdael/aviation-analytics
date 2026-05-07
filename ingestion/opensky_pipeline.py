"""
dlt pipeline for pulling flight arrivals and departures from the OpenSky Network API.
Covers 10 major European airports.
"""

# ICAO codes for 10 major European airports
EUROPEAN_AIRPORTS = [
    "EGLL",  # London Heathrow
    "LFPG",  # Paris Charles de Gaulle
    "EHAM",  # Amsterdam Schiphol
    "EDDF",  # Frankfurt
    "LEMD",  # Madrid Barajas
    "LIRF",  # Rome Fiumicino
    "LEBL",  # Barcelona El Prat
    "EDDM",  # Munich
    "EGKK",  # London Gatwick
    "EKCH",  # Copenhagen Kastrup
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
