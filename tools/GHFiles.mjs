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
}

export function handleFiles(files) {
    // TODO selective cleanup
    return Promise.all(files.map(handleOneFile));
}

async function handleOneFile(filename) {
    const sdgid = filename.split("/").pop().replace(".xlsx", "");

    const result = await octokit.request('GET /repos/{owner}/{repo}/contents/{path}', {
        owner: 'sustainability-zhaw',
        repo: 'keywords',
        path: filename
    });

    const fileobject = result.data;

    const contentBuffer = Buffer.from(fileobject.content, "base64");

    if (!(contentBuffer && contentBuffer.length)) {
        console.log("no content returned");
        return;
    }    

    const matcher = await Excel.loadOneBuffer(sdgid, contentBuffer);
    
    if (matcher.length) {
        await Target.injectData(setup.targetURL, {matcher});
    }
}