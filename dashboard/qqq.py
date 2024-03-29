from gql import gql, Client
from gql.transport.aiohttp import AIOHTTPTransport

# Select your transport with a defined url endpoint
transport = AIOHTTPTransport(url="https://api.mainnet.aptoslabs.com/v1/graphql")

# Create a GraphQL client using the defined transport
client = Client(transport=transport, fetch_schema_from_transport=True)

# Provide a GraphQL query
query = gql(
    """
    query MyQuery {
        user_transactions(
            where: {entry_function_id_str: {_eq: "0x9d518b9b84f327eafc5f6632200ea224a818a935ffd6be5d78ada250bbc44a6::sidekick::create_to"}}
            limit: 10
            offset: 0
            order_by: {block_height: asc}
        ) {
            version
        }
    }
    """
)

# Execute the query on the transport
result = client.execute(query)
print(result)