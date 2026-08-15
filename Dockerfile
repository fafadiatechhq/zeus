# Zeus — Custom ERPNext Image
# Extends the official frappe/erpnext:v15 image with HRMS + Zeus pre-installed.
# Build: docker compose build
# Run:   docker compose up

FROM frappe/erpnext:v15

USER root
RUN apt-get update \
    && apt-get install --no-install-recommends -y git \
    && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench

# HRMS (v15) — Employee, Attendance, Expense Claim, and related HR doctypes
ARG HRMS_BRANCH=version-15
RUN git clone --depth 1 --branch ${HRMS_BRANCH} https://github.com/frappe/hrms.git apps/hrms \
    && ./env/bin/pip install --no-cache-dir -e apps/hrms

# ── Copy Zeus ERPNext app (Python module only; Flutter app is excluded via .dockerignore)
# README.md must be alongside pyproject.toml because flit_core reads it for the package description
COPY --chown=frappe:frappe pyproject.toml README.md apps/zeus/
COPY --chown=frappe:frappe zeus/                    apps/zeus/zeus/

# ── Install Zeus into the bench virtualenv so Frappe can import it
RUN ./env/bin/pip install --no-cache-dir -e apps/zeus

# ── Copy the one-time init/seed script
COPY --chown=frappe:frappe docker/init.sh /usr/local/bin/zeus-init.sh
RUN chmod +x /usr/local/bin/zeus-init.sh
