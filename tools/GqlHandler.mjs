
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

    if (!("errors" in result)) {
        console.log(JSON.stringify(result.errors, null, "  "));
    }

    return result;
}

export async function cleanup_all(target, force) {
    if (!force) {
        return;
    }

    await Promise.all(["de", "en", "fr", "it"].map(async (lang) => {
        const query = `mutation {
            deleteSdgMatch(filter: {language: {eq: "${lang}"}}) {
              msg
              sdgMatch {
                construct
              }
            }
          }`;
          
        const result = await runRequest(target, { query });
        
        if (!("errors" in result)) {
            console.log(JSON.stringify(result.errors, null, "  "));
        }
    }));
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

    let result;

    while (!result || ("errors" in  result && result.errors[0].message.endsWith("Please retry"))) {
        const response = await fetch(targetHost, {
            signal,
            method,
            headers,
            cache,
            body
        });
            
        result = await response.json();
    }

    return result;
}
