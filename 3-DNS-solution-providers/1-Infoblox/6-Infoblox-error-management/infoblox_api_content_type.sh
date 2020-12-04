#!/bin/bash

API_ENDPOINT=""
VALID_USER_1_NAME=""
VALID_USER_1_PASSWORD=""
VALID_USER_2_NAME=""
VALID_USER_2_PASSWORD=""

echo "== Send requests"

# ---------------
echo "=== PREPARE: Create a generic proto test view"

# See https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md

## Delete view if already exist
export view_id=$(curl -k -u $VALID_USER_1_NAME:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/view?name=scoulomb-proto-view-cont-type" |  jq .[0]._ref |  tr -d '"')
echo $view_id

curl -k -u $VALID_USER_1_NAME:infoblox \
        -H "Content-Type: application/json" \
        -X DELETE \
        "https://$API_ENDPOINT/wapi/v2.5/$view_id"

## Recreate the view
curl -k -u $VALID_USER_1_NAME:$VALID_USER_1_PASSWORD -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/view" -d '{"name": "scoulomb-proto-view-cont-type"}'
export view_id=$(curl -k -u $VALID_USER_1_NAME:$VALID_USER_1_PASSWORD \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/view?name=scoulomb-proto-view-cont-type" |  jq .[0]._ref |  tr -d '"')
echo $view_id

## Create the zone
curl -k -u $VALID_USER_1_NAME:$VALID_USER_1_PASSWORD -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/zone_auth?_return_fields%2B=fqdn,network_view&_return_as_object=1" -d \
'{"fqdn": "me.scoulomb.net","view": "scoulomb-proto-view-cont-type"}'

# ---------------
echo -e "\n=== TEST1: Create entry nominal: A '201 application/json' IS RETURNED BUT actual type is 'text'"

UUID=$(cat /proc/sys/kernel/random/uuid)
export entry_name="demo-test-$UUID"

payload_infoblox=$(cat <<EOF
{
    "name": "$entry_name.me.scoulomb.net",
    "view": "scoulomb-proto-view-cont-type",
    "ipv4addr": "15.24.53.5"
}
EOF
)


echo $payload_infoblox | jq -M

curl -i -k -u $VALID_USER_1_NAME:$VALID_USER_1_PASSWORD \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:a


echo -e "\n=== TEST1 BIS: Create entry nominal with user 2: A '201 application/json' IS RETURNED BUT actual type is 'text'"

UUID=$(cat /proc/sys/kernel/random/uuid)
export entry_name="demo-test-$UUID"

payload_infoblox=$(cat <<EOF
{
    "name": "$entry_name.me.scoulomb.net",
    "view": "scoulomb-proto-view-cont-type",
    "ipv4addr": "15.24.53.5"
}
EOF
)


echo $payload_infoblox | jq -M

curl -i -k -u $VALID_USER_2_NAME:$VALID_USER_2_PASSWORD \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:a

echo -e "\n=== TEST1 BIS 2: Create entry nominal with user 2 with a more recent API version (2.11): A '201 application/json' IS RETURNED BUT actual type is 'text'"

UUID=$(cat /proc/sys/kernel/random/uuid)
export entry_name="demo-test-$UUID"

payload_infoblox=$(cat <<EOF
{
    "name": "$entry_name.me.scoulomb.net",
    "view": "scoulomb-proto-view-cont-type",
    "ipv4addr": "15.24.53.5"
}
EOF
)


echo $payload_infoblox | jq -M

curl -i -k -u $VALID_USER_2_NAME:$VALID_USER_2_PASSWORD \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.11/record:a


echo -e "\n=== TEST2: Create record in zone which does not exist: A '400 application/json' IS RETURNED and actual type is 'application/json'"

UUID=$(cat /proc/sys/kernel/random/uuid)
export entry_name="demo-test-$UUID"

payload_infoblox=$(cat <<EOF
{
    "name": "$entry_name.me.unknown.net",
    "view": "scoulomb-proto-view-cont-type",
    "ipv4addr": "15.24.53.5"
}
EOF
)

echo $payload_infoblox | jq -M

curl -i -k -u $VALID_USER_1_NAME:$VALID_USER_1_PASSWORD \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:a

echo -e "\n=== TEST3: Create entry username exists / invalid credentials: A '401 text/html' IS RETURNED and actual type is 'text/html'"

UUID=$(cat /proc/sys/kernel/random/uuid)
export entry_name="demo-test-$UUID"

payload_infoblox=$(cat <<EOF
{
    "name": "$entry_name.me.scoulomb.net",
    "view": "scoulomb-proto-view-cont-type",
    "ipv4addr": "15.24.53.5"
}
EOF
)


echo $payload_infoblox | jq -M

curl -i -k -u $VALID_USER_1_NAME:wrongpwd \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:a

echo -e "\n=== TEST4: Create entry username exists / invalid credentials RETRY: A '401 text/html' IS RETURNED and actual type is 'text/html'"

curl -i -k -u $VALID_USER_1_NAME:wrongpwd \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:a

echo -e "\n=== TEST5: Create entry username DOES NOT exist : A '401 text/html' IS RETURNED and actual type is 'text/html'"

curl -i -k -u invalidusername:wrongpwd \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:a


echo -e "\n=== TEST6: Find entry username DOES NOT exist : A '401 text/html' IS RETURNED and actual type is 'text/html'"

curl -i -k -u invalidusername:wrongpwd \
        -H "Content-Type: application/json" \
        "https://$API_ENDPOINT/wapi/v2.5/allrecords?name=$entry_name&zone=me.scoulomb.net&view=scoulomb-proto-view-cont-type"

echo -e "\n=== TEST7: Find entry username DOES NOT exist RETRY : A '403 text/html' IS RETURNED and actual type is 'text/html'"

for i in {1..3}
do
curl -i -k -u invalidusername:wrongpwd \
        -H "Content-Type: application/json" \
        "https://$API_ENDPOINT/wapi/v2.5/allrecords?name=$entry_name&zone=me.scoulomb.net&view=scoulomb-proto-view-cont-type"
done

# I managed to generate the 403 with a find but not with a create
# Note several failing retry can make valid credential failing
# Here is a demo

echo -e "\n=== TEST8: Create entry nominal after username failure: device is blocked temporarily for this user"

UUID=$(cat /proc/sys/kernel/random/uuid)
export entry_name="demo-test-$UUID"

payload_infoblox=$(cat <<EOF
{
    "name": "$entry_name.me.scoulomb.net",
    "view": "scoulomb-proto-view-cont-type",
    "ipv4addr": "15.24.53.5"
}
EOF
)


echo $payload_infoblox | jq -M

curl -i -k -u $VALID_USER_1_NAME:$VALID_USER_1_PASSWORD \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:a


echo -e "\n=== TEST9: Create entry nominal after username failure: device is blocked temporarily for all users"

curl -i -k -u $VALID_USER_2_NAME:$VALID_USER_2_PASSWORD \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:a

# ---------------
echo "=== Clean-up"

# sleep 120 second to be re-allowed to perform queries
sleep 120

# https://stackoverflow.com/questions/43158140/way-to-create-multiline-comments-in-bash
# : <<'END_COMMENT'
echo $view_id
curl -k -u $VALID_USER_1_NAME:$VALID_USER_1_PASSWORD \
        -H "Content-Type: application/json" \
        -X DELETE \
        "https://$API_ENDPOINT/wapi/v2.5/$view_id"
# END_COMMENT;
