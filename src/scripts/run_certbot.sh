#!/bin/bash

# Source in util.sh so we can have our nice tools
. $(cd $(dirname $0); pwd)/util.sh

# We require an email to register the ssl certificate for
if [ -z "$CERTBOT_EMAIL" ]; then
    error "CERTBOT_EMAIL environment variable undefined; certbot will do nothing"
    exit 1
fi

exit_code=0
set -x

# Retrieve certificate for all found parse_domains

if [ "${IS_SINGLE_CERTIFICATE}" = "1" ]; then
  domains="$(parse_domains)"
  renewals_required=0

  for domain in $domains; do
    if is_renewal_required $domain; then
      renewals_required=$(($renewals_required + 1))
    fi
  done

  if [ $renewals_required -gt 0 ]; then
    # Get a single certificate for all of the specified domains
    if ! get_multi_domain_certificate "$domains" $CERTBOT_EMAIL; then
        error "Cerbot failed for $domains."
        exit_code=1
    fi
  else
    echo "Not run certbot for $domains; no domains need renewal." # TODO: renew only certificates that need to be renewed
  fi

else
  # Loop over every domain we can find
  for domain in $(parse_domains); do
      if is_renewal_required $domain; then
          # Renewal required for this doman.
          # Last one happened over a week ago (or never)
          if ! get_certificate $domain $CERTBOT_EMAIL; then
              error "Cerbot failed for $domain. Check the logs for details."
              exit_code=1
          fi
      else
          echo "Not run certbot for $domain; last renewal happened just recently."
      fi
  done
fi

# After trying to get all our certificates, auto enable any configs that we
# did indeed get certificates for
auto_enable_configs

set +x
exit $exit_code
