"""Execute a GraphQL query asynchronously using the gql client and AIOHTTP transport.

Creates a transport to the GraphQL API endpoint, initializes a client with 
that transport, executes the provided query, and prints the result.
"""

import asyncio

from gql import Client, gql
from gql.transport.aiohttp import AIOHTTPTransport


async def get_txn_versions(grade: str):
    """Execute a GraphQL query asynchronously.

    Creates an AIOHTTP transport to the GraphQL API endpoint, initializes a
    Client with that transport, executes the provided query, and prints the
    result.

    The async with block starts a connection on the transport and provides
    a session to execute queries on that connection.
    """
    transport = AIOHTTPTransport(url="https://api.mainnet.aptoslabs.com/v1/graphql")

    # Using `async with` on the client will start a connection on the transport
    # and provide a `session` variable to execute queries on this connection
    async with Client(
        transport=transport,
        fetch_schema_from_transport=True,
    ) as session:
        package_address = "0x9d518b9b84f327eafc5f6632200ea224a818a935ffd6be5d78ada250bbc44a6"
        # Execute single query
        query = gql(
            """
                query CommonGradeCount($token_properties: jsonb_comparison_exp = {_contains: {grade: Rare}}, $collection_id: String!) {
                current_token_ownerships_v2_aggregate(
                    where: {_and: {_and: {current_token_data: {collection_id: {_eq: $collection_id}, token_properties: $token_properties}, amount: {_gt: "0"}}}}
                ) {
                    aggregate {
                    count(columns: amount)
                    }
                }
                }
            """
        )
        params = {
            "collection_id": "0x9d9ae026d65ad917bffcc6984370468e751ec3e9cd7a69f114c8a58c34d408b7",
        }
        result = await session.execute(query, variable_values=params)
        print(result)

        


asyncio.run(get_txn_versions("Rare"))
