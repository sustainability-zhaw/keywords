
export async function injectData(target, variables) {
    const query = `
    mutation addSdgMatch($matcher: [AddSdgMatchInput!]!) { 
        addSdgMatch(input: $matcher, upsert: true) { 
            sdgMatch {
                construct
            }
        } 
    }`;

    const result = await runRequest(target, { query, variables });

    // console.log(JSON.stringify(result, null, "  "));
    return result;
}

export async function cleanup_all(target, force) {
    if (!force) {
        return;
    }

    const query = `mutation {
        deleteSdgMatch(filter: {has: construct}) {
          msg
          sdgMatch {
            construct
          }
        }
      }`;
      
    const result = await runRequest(target, { query });
    
    console.log(JSON.stringify(result, null, "  "));

    return result;
}

async function runRequest(targetHost, bodyObject) {
    const method = "POST"; // all requests are POST requests
    const RequestController = new AbortController();
    const {signal} = RequestController;
    const cache = "no-store";

    const headers = {
        'Content-Type': 'application/json'
    };

    const body = JSON.stringify(bodyObject, null, "  ");

    // console.log(body);

    // return;

    const response = await fetch(targetHost, {
        signal,
        method,
        headers,
        cache,
        body
    });
        
    const result = await response.json();

    return result;
}
