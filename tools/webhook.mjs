import Koa from "koa";
import Router from "@koa/router";
import KoaCompose from "koa-compose";
import koaBody from "koa-body";
import * as GHFiles from "./GHFiles.mjs";

import * as Config from "./ConfigReader.mjs";

const cfg = await Config.readConfig(["./config.json", "./tools/config.json", "/etc/app/config.json"]);

GHFiles.init(cfg);

const hook = setup();

// inject any existing data
GHFiles.handleAllFiles();

hook.run();

function setup() {
    const app = new Koa();
    const router = new Router();

    // app.use(koaBody.koaBody());

    router.post("/payload", koaBody.koaBody(), KoaCompose([
        startRequest,
        handlePing,
        checkPush,
        checkFiles,
        handlePayload,
        handleOther,
        cleanup
        // renderOK
    ])); 

    router.get("/", KoaCompose([
        startRequest,
        handleHelo,
        // renderOK
    ])); 

    app.use(router.routes());

    return {run: () => app.listen(8090)};
}

async function startRequest(ctx, next) {
    console.log(`${(new Date(Date.now())).toISOString()} -------- new request ${ctx.request.body ? "with payload": ""}`);
    await next();
}

async function handlePing(ctx, next) {
    if ("zen" in ctx.request.body) {
        console.log("   GH ping");
        ctx.body = JSON.stringify({message: "Not being distracted at all."});
    }
    await next();
}

async function handleOther(ctx, next) {
    if (!ctx.body && !("ref" in ctx.request.body)) {
        console.log(JSON.stringify(ctx.request.body, null, "  "));
        ctx.body = JSON.stringify({message: "thank you"});
    }
    await next();
}

async function checkPush(ctx, next) {
    if (!ctx.body && "ref" in ctx.request.body) {
        console.log(`${(new Date(Date.now())).toISOString()} -- ${ctx.request.body.head_commit.id}`);
        
        const branch = ctx.request.body.ref.replace("refs/heads/", "");

        if (branch !== cfg.branch) {
            console.log("push on other branch, ignored");
            ctx.body = JSON.stringify({message: "thank you"});
        }
    }
    await next();
}

async function checkFiles(ctx, next) {
    if (!ctx.body && "ref" in ctx.request.body) {
        const files = ctx.request.body.commits
                    // merge all available files that have changed.
                    .map((c) => c.modified.concat(c.added)).flat()
                    // focus on target path
                    .filter(fn => fn.startsWith(cfg.target_path))
                    // filter target files
                    .filter((fn) => fn.slice(-5) === ".xlsx")
                    // remove duplicates
                    .reduce((agg, fn) => {
                        if (!agg.includes(fn)) {
                            agg.push(fn);
                        }
                        return agg;
                    }, []);
  
        if (!files.length) {
            console.log("no relevant files have changed");
            ctx.body = JSON.stringify({message: "done"});
        }

        ctx.gh_files = files;
    } 

    await next();
}

async function handlePayload(ctx, next) {
    if (!ctx.body && ctx.gh_files) {
        console.log(`some files have changed: ${ctx.gh_files.join("; ")}`);

        ctx.body = JSON.stringify({message: "accepted"});

        GHFiles.handleFiles(ctx.gh_files, ctx.request.body.head_commit.id);
    }
    
    await next();
}

async function cleanup(ctx, next) {
    if (!ctx.body) {
        ctx.body = JSON.stringify({message: "nothing to do"});
    }

    console.log(`${(new Date(Date.now())).toISOString()} -------- request done`);

    await next();
}

async function handleHelo(ctx, next) {
    console.log("HELO");

    ctx.body = JSON.stringify({message: "Hello"});

    await next();
}
