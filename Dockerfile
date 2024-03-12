# This is a quick and dirty conversion of sameersbn's squid docker image to:
#
#   a) Run on port 80 rather than port 3128
#    b) Require a password (which you MUST set as the PASSWORD environment
#       variable when you start the container) for use of squid


FROM sameersbn/squid:3.5.27-2

# we need to install apache2-utils to use htpasswd.
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
   && apt-get install -y apache2-utils \
   && rm -rf /var/lib/apt/lists/*

RUN <<EOF
perl <<'EOSCRIPT'

use Tie::File;

# tie the files to the arrays (one line per array) so you modify the files just by
# altering the array and have perl magically update the underling files for us
tie @squidconf, 'Tie::File', '/etc/squid/squid.conf';
tie @entrypoint, 'Tie::File', '/sbin/entrypoint.sh';

# replace all occurrences of a regex in an array with another string
sub replace {
    my $array = shift;
    my $re = shift;
    my $replacement = shift;

    foreach my $line (@$array) {
        if ($line =~ $re) {
            $line = $replacement;
            return;
        }
    }
    die "Can't find line to replace";
}

# change squid's confiig to listen on port 80
replace(\@squidconf, qr/^http_port\s+3128/, "http_port 80");

# change squid's confiig to require a password which it gets from the
# /etc/squid/passwd file
replace(\@squidconf, qr/^http_access deny all/, <<'REPLACEMENT');
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 2 hours
acl auth_users proxy_auth REQUIRED
http_access allow auth_users
http_access deny all
REPLACEMENT

# change the entry script so that it creates the /etc/squid/passwd file for
# squid based on the contents of the PASSWORD env var on startup
replace(\@entrypoint, qr/set -e/, <<'REPLACEMENT');
set -e

if [ -n "$PASSWORD" ]; then
    htpasswd -bc /etc/squid/passwd squid $PASSWORD
else
    echo "PASSWORD env variable not set, bailing out!"
    exit 1
fi
REPLACEMENT

EOSCRIPT
EOF

