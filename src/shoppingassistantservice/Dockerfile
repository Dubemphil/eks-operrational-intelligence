# Define a default value so it's not empty if the builder fails to provide it
ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM python:3.14.7-slim@sha256:ce40764625a4ff50df3548277632e7f96c4e77fe75fa848aae9885476e7df5a4 AS base

FROM base AS builder

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends g++ \
    && rm -rf /var/lib/apt/lists/*

# get packages
COPY requirements.txt .
RUN pip install -r requirements.txt

FROM base
# Enable unbuffered logging
ENV PYTHONUNBUFFERED=1

# get packages
WORKDIR /shoppingassistantservice

# Grab packages from builder
COPY --from=builder /usr/local/lib/python3.14/ /usr/local/lib/python3.14/

# Add the application
COPY . .

# set listen port
ENV PORT="8080"
EXPOSE 8080

ENTRYPOINT ["python", "shoppingassistantservice.py"]
