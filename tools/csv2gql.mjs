import * as CSVParser from "csv-parse";
import fs from "fs";
import { finished } from "stream/promises";

let argHost = process.argv.pop();

if (process.argv.length < 2 && argHost.slice(0,3) !== "http") {
    argHost = null;
}

// The default target is localhost to match the dev environment
const targetHost = argHost? argHost : "http://localhost:8080/api/";

const RequestController = new AbortController();

// const parentdir = "data/sdgs_originals/with_posterior";
const parentdir = "data/sdgs";

const files = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16];

function getFilename(id) {
    return `${parentdir}/${id}.csv`
}

const matcher = (await Promise.all(files.map(async (idx) => {
    await cleanup_all(true); 

    const parser = CSVParser.parse({
        delimiter: ";"
    });

    const data = [];

    parser.on("readable", () => {
        let r;
        while ((r = parser.read()) !== null) {
            data.push(r);
        }
    });

    const fileid = `SDG${idx}`;

    fs.createReadStream(getFilename(fileid))
      .pipe(parser);

    await finished(parser);

    // console.log(JSON.stringify(data));

    const fields = data.shift();
    const mapping = fields.map(f => {
        if (f !== "id") {
            return { 
                language: f.slice(-2),
                key: f.slice(0,-3)
            };
        }

        return {key: f};
    });

    return data.map(record => {
        const id = `${fileid.toLowerCase()}_${record[0].trim()}`;

        return [1,4,7,10].map(rid => {
            const obj = {
                construct: `${id}_${mapping[rid].language}`,
                language: mapping[rid].language,
                sdg: {
                    id: `sdg_${idx}`
                }
            };  

            obj[mapping[rid].key] = record[rid].replaceAll("*", " ").trim();

            if (record[rid + 1].trim() !== "NA") {              
                obj[mapping[rid + 1].key] = record[rid + 1].replaceAll("*", " ").trim();
            }

            if (record[rid + 2].trim() !== "NA") {              
                obj[mapping[rid + 2].key] = record[rid + 2].replaceAll("*", " ").trim();
            }

            return obj;
        });
    }).flat();
}))).flat()
.filter((r) => r.keyword.length);


const method = "POST"; // all requests are POST requests
const {signal} = RequestController;
const cache = "no-store";

const headers = {
    'Content-Type': 'application/json'
};

const query = "mutation addSdgMatch($matcher: [AddSdgMatchInput!]!) { addSdgMatch(input: $matcher, upsert: true) { sdgMatch { construct } } }";
const variables = { matcher };
const body = JSON.stringify({ query, variables }, null, "  ");

// console.log(body);

// console.log(">>> pre request");

const response = await fetch(targetHost, {
    signal,
    method,
    headers,
    cache,
    body
});

// console.log(">>> post request");

const result = await response.json();

// console.log(">>> request results");

console.log(JSON.stringify(result, null, "  "));

async function cleanup_all(force) {
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
      
    const method = "POST"; // all requests are POST requests
    const {signal} = RequestController;
    const cache = "no-store";

    const headers = {
        'Content-Type': 'application/json'
    };

    const body = JSON.stringify({ query }, null, "  ");

    const response = await fetch(targetHost, {
        signal,
        method,
        headers,
        cache,
        body
    });
    
    // console.log(">>> post request");
    
    const result = await response.json();
    
    // console.log(">>> request results");
    
    console.log(JSON.stringify(result, null, "  "));
}
