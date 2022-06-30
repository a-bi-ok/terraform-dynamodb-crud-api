
INVOKE_URL="https://d8j4och2ui.execute-api.us-east-1.amazonaws.com/serverless_lambda_stage" 

# Create or update an item. The command includes a request body with the item's ID, price, and name.

curl -X "PUT" -H "Content-Type: application/json" -d "{
    \"id\": \"grunt10000\",
    \"price\": 12345,
    \"item\": \"kenkey\"
}" $INVOKE_URL/items

curl -s $INVOKE_URL/items | js-beautify 

# curl -X "GET" https://lsyfl295d2.execute-api.us-east-1.amazonaws.com/serverless_lambda_stage/items
