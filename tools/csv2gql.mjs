import * as CSVParser from "csv-parse";
import fs from "fs";
import { finished } from "stream/promises";

let argHost = process.argv.pop();

if (process.argv.length < 2 && argHost.slice(0,3) !== "http") {
    argHost = null;
}

// The default target is localhost to match the dev environment
const targetHost = argHost? argHost : "http://localhost:8080/api/";

const forceClean = process.env.CLEANUP;

// const parentdir = "data/sdgs_originals/with_posterior";
const parentdir = "data/sdgs";

const files = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16];

function getFilename(id) {
    return `${parentdir}/${id}.csv`
}

const matcher = (await Promise.all(files.map(async (idx) => {
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

            const rctxt = record[rid + 1].trim();
            const fctxt = record[rid + 2].trim();

            if (rctxt && rctxt.length && rctxt !== "NA") {
                obj[mapping[rid + 1].key] = rctxt.replaceAll("*", " ").trim();
            }

            if (fctxt && fctxt.length && fctxt !== "NA") {
                obj[mapping[rid + 2].key] = fctxt.replaceAll("*", " ").trim();
            }

            if (!obj.keyword.length) {
                return null;
            }

            return expandMatchingRecords(obj, "required_context")
                .flat()
                .map(o => expandMatchingRecords(o, "forbidden_context"));
        });
    });
})))
.flat(4)
.filter((r) => r && r.keyword.length);

const query = "mutation addSdgMatch($matcher: [AddSdgMatchInput!]!) { addSdgMatch(input: $matcher, upsert: true) { sdgMatch { construct } } }";
const variables = { matcher };
const body = JSON.stringify({ query, variables }, null, "  ");

// console.log(body);

// await cleanup_missing(matcher); // TODO

// console.log(">>> pre request");

const RequestController = new AbortController();

const method = "POST"; // all requests are POST requests
const {signal} = RequestController;
const cache = "no-store";

const headers = {
    'Content-Type': 'application/json'
};

await cleanup_all(forceClean); 

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

function expandMatchingRecords(record, type) {

    if (!record) {
        console.log("no record");
        return null;
    }

    const construct = record.construct;
    const language = record.language;
    const sdg = record.sdg;
    const keyword = record.keyword;

    const forbidden_context = record.forbidden_context;
    const required_context = record.required_context;
    
    if (!record[type]) {
        return [record];
    }

    const atransform = record[type].split(",").map(t => t.trim());
    
    if (!(atransform || atransform.length)) {
        return [record];
    }

    return atransform.map((t, i) => {
        if (!(t || t.length)) {
            return null;
        }

        const retval = {
            construct: `${construct}_${i}`,
            language,
            sdg,
            keyword,
            required_context,
            forbidden_context
        };

        retval[type] = t; 
        return retval;
    });
}
