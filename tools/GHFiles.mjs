import {Buffer} from "node:buffer";

import { Octokit, App } from "octokit";

import * as Target from "./GqlHandler.mjs";
import * as Excel from "./Utilities.mjs";

let octokit;

const setup = {};

export function init(config) {
    octokit = new Octokit({
        auth: config.ghtoken
    });

    setup.targetURL = config.apiurl;
    setup.target_path = config.target_path;
}

export async function handleFiles(files) {
    // TODO selective cleanup

    // ignore passed files and runn all files
    await Target.cleanup_all(setup.targetURL);
    files = sequence(16).map(i => `${setup.target_path}/SDG${i}.xlsx`);

    return Promise.all(files.map(handleOneFile));
}

async function handleOneFile(filename) {
    const sdgid = filename.split("/").pop().replace(".xlsx", "");

    console.log(`handle ${filename} for ${sdgid}`);

    let result; 

    try {
        result = await octokit.request('GET /repos/{owner}/{repo}/contents/{path}', {
            owner: 'sustainability-zhaw',
            repo: 'keywords',
            path: filename
        });
    }
    catch (err) {
        console.log(`ERROR for ${sdgid}: ${err.message}`);
        return;
    }

    const fileobject = result.data;

    const contentBuffer = Buffer.from(fileobject.content, "base64");

    if (!(contentBuffer && contentBuffer.length)) {
        console.log(`no content returned for ${sdgid}`);
        return;
    }

    console.log(`process ${sdgid}`);

    const matcher = await Excel.loadOneBuffer(sdgid, contentBuffer);
    
    if (matcher.length) {
        await Target.injectData(setup.targetURL, {matcher});
        console.log(`data incjected for ${sdgid}`);
    }
}

function sequence(len, start) {
    if (!start) {
        start = 1;
    }
    return Array(len).fill().map((_, i) => i + start);
}
