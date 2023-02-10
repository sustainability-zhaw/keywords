import Koa from "koa";
import Router from "@koa/router";
import KoaCompose from "koa-compose";
import koaBody from "koa-body";
import * as GHFiles from "./GHFiles.mjs";

import * as Config from "./ConfigReader.mjs";

const cfg = await Config.readConfig("./config.json");

GHFiles.init(cfg);

const hook = setup();

hook.run();

function setup() {
    const app = new Koa();
    const router = new Router();

    // app.use(koaBody.koaBody());

    router.post("/payload", koaBody.koaBody(), KoaCompose([
        startRequest,
        handlePayload,
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
    const now = (new Date(Date.now())).toISOString();
    console.log(`${now} -------- new payload`);
    ctx.now = now;
    await next();
}

async function handlePayload(ctx, next) {
    const payload = JSON.stringify(ctx.request.body, null, "  ");
    const message = ctx.request.body;

    if ("zen" in message) {
        console.log("   GH ping");
        ctx.body = JSON.stringify({message: "Not being distracted at all."});
        await next();
        return;
    }

    if (!("ref" in message)) {
        console.log(payload);
        ctx.body = JSON.stringify({message: "thank you"});
        await next();
        return;
    }

    console.log(`${ctx.now} -- ${ctx.request.body.head_commit.id}`);
    const branch = message.ref.replace("refs/heads/", "");

    if (branch !== cfg.branch) {
        console.log("push on other branch, ignored");
        ctx.body = JSON.stringify({message: "thank you"});
        await next();
        return;
    }

    const files  = message.commits
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
        await next();
        return;
    }
   
    console.log(`some files have changed: ${files.join("; ")}`);
    
    ctx.body = JSON.stringify({message: "accepted"});

    GHFiles.handleFiles(files, ctx.request.body.head_commit);

    console.log(`${(new Date(Date.now())).toISOString()} -------- payload done`);

    await next();
}

async function handleHelo(ctx, next) {
    console.log("HELO");

    ctx.body = JSON.stringify({message: "Hello"});

    await next();
}
